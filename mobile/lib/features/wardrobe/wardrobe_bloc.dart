import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/sync/sync_engine.dart';

abstract class WardrobeEvent extends Equatable {
  const WardrobeEvent();
  @override
  List<Object?> get props => [];
}

class LoadWardrobeRequested extends WardrobeEvent {}

class CategoryFilterChanged extends WardrobeEvent {
  final String category;
  const CategoryFilterChanged(this.category);
  @override
  List<Object?> get props => [category];
}

class SearchQueryChanged extends WardrobeEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class AddWardrobeItemSubmitted extends WardrobeEvent {
  final WardrobeItemModel item;
  const AddWardrobeItemSubmitted(this.item);
  @override
  List<Object?> get props => [item];
}

class DeleteItemRequested extends WardrobeEvent {
  final String itemId;
  const DeleteItemRequested(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class MarkItemAsWornRequested extends WardrobeEvent {
  final String itemId;
  final String context;
  const MarkItemAsWornRequested(this.itemId, this.context);
  @override
  List<Object?> get props => [itemId, context];
}

abstract class WardrobeState extends Equatable {
  const WardrobeState();
  @override
  List<Object?> get props => [];
}

class WardrobeInitial extends WardrobeState {}
class WardrobeLoading extends WardrobeState {}

class WardrobeLoaded extends WardrobeState {
  final List<WardrobeItemModel> allItems;
  final List<WardrobeItemModel> filteredItems;
  final String selectedCategory;
  final String searchQuery;

  const WardrobeLoaded({
    required this.allItems,
    required this.filteredItems,
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [allItems, filteredItems, selectedCategory, searchQuery];
}

class WardrobeError extends WardrobeState {
  final String message;
  const WardrobeError(this.message);
  @override
  List<Object?> get props => [message];
}

class WardrobeBloc extends Bloc<WardrobeEvent, WardrobeState> {
  final ApiClient apiClient;
  final SyncEngine syncEngine;
  List<WardrobeItemModel> _localItems = [];

  WardrobeBloc({required this.apiClient, required this.syncEngine}) : super(WardrobeInitial()) {
    on<LoadWardrobeRequested>((event, emit) async {
      emit(WardrobeLoading());
      try {
        // 1. Try loading from persistent local cache
        final cached = await SecureStorage.getWardrobeCache();
        if (cached != null && cached.isNotEmpty) {
          try {
            final List decoded = jsonDecode(cached);
            _localItems = decoded.map((j) => WardrobeItemModel.fromJson(j)).toList();
          } catch (_) {
            _localItems = [];
          }
        }

        // 2. Fallback to default foundation items if cache was empty
        if (_localItems.isEmpty) {
          _localItems = [
            const WardrobeItemModel(id: "item_1", category: "Tops", subcategory: "Shirts", name: "White Oxford Shirt", colors: ["White"], formality: "Smart Casual", wearCount: 7, purchasePrice: 85.0),
            const WardrobeItemModel(id: "item_2", category: "Bottoms", subcategory: "Trousers", name: "Navy Slim Trousers", colors: ["Navy"], formality: "Smart Casual", wearCount: 4, purchasePrice: 110.0),
            const WardrobeItemModel(id: "item_3", category: "Footwear", subcategory: "Sneakers", name: "White Leather Sneakers", colors: ["White"], formality: "Casual", wearCount: 12, purchasePrice: 130.0),
            const WardrobeItemModel(id: "item_4", category: "Tops", subcategory: "T-Shirts", name: "Charcoal Grey Crewneck", colors: ["Grey"], formality: "Casual", wearCount: 15, purchasePrice: 35.0),
            const WardrobeItemModel(id: "item_5", category: "Bottoms", subcategory: "Jeans", name: "Raw Indigo Denim", colors: ["Blue"], formality: "Casual", wearCount: 9, purchasePrice: 95.0),
            const WardrobeItemModel(id: "item_6", category: "Outerwear", subcategory: "Jackets", name: "Minimal Wool Overshirt", colors: ["Black"], formality: "Smart Casual", wearCount: 3, purchasePrice: 160.0),
          ];
          await _saveToCache();
        }

        // 3. Try fetching from backend if online
        try {
          final res = await apiClient.dio.get('/wardrobe');
          if (res.data is List && (res.data as List).isNotEmpty) {
            final remoteItems = (res.data as List)
                .map((j) => WardrobeItemModel.fromJson(j))
                .toList();
            _localItems = remoteItems;
            await _saveToCache();
          }
        } catch (_) {
          // Keep local cached items if offline or backend is starting
        }

        _applyFilter(emit, 'All', '');
      } catch (e) {
        emit(WardrobeError(ApiClient.getErrorMessage(e)));
      }
    });

    on<CategoryFilterChanged>((event, emit) {
      if (state is WardrobeLoaded) {
        final current = state as WardrobeLoaded;
        _applyFilter(emit, event.category, current.searchQuery);
      }
    });

    on<SearchQueryChanged>((event, emit) {
      if (state is WardrobeLoaded) {
        final current = state as WardrobeLoaded;
        _applyFilter(emit, current.selectedCategory, event.query);
      }
    });

    on<AddWardrobeItemSubmitted>((event, emit) async {
      _localItems.insert(0, event.item);
      await _saveToCache();

      syncEngine.queueMutation(SyncMutation(
        id: "mut_${DateTime.now().millisecondsSinceEpoch}",
        entityType: "wardrobe_item",
        entityId: event.item.id,
        mutationType: "INSERT",
        payload: event.item.toJson(),
        timestamp: DateTime.now(),
      ));

      // Attempt immediate background sync
      syncEngine.flushQueue().ignore();

      if (state is WardrobeLoaded) {
        final current = state as WardrobeLoaded;
        _applyFilter(emit, current.selectedCategory, current.searchQuery);
      } else {
        _applyFilter(emit, 'All', '');
      }
    });

    on<DeleteItemRequested>((event, emit) async {
      _localItems.removeWhere((i) => i.id == event.itemId);
      await _saveToCache();

      syncEngine.queueMutation(SyncMutation(
        id: "mut_del_${DateTime.now().millisecondsSinceEpoch}",
        entityType: "wardrobe_item",
        entityId: event.itemId,
        mutationType: "DELETE",
        payload: {"id": event.itemId},
        timestamp: DateTime.now(),
      ));

      syncEngine.flushQueue().ignore();

      // Delete from backend API if online
      try {
        await apiClient.dio.delete('/wardrobe/${event.itemId}');
      } catch (_) {}

      if (state is WardrobeLoaded) {
        final current = state as WardrobeLoaded;
        _applyFilter(emit, current.selectedCategory, current.searchQuery);
      }
    });

    on<MarkItemAsWornRequested>((event, emit) async {
      final index = _localItems.indexWhere((i) => i.id == event.itemId);
      if (index != -1) {
        final item = _localItems[index];
        _localItems[index] = item.copyWith(
          wearCount: item.wearCount + 1,
          lastWornDate: DateTime.now(),
        );
        await _saveToCache();

        syncEngine.queueMutation(SyncMutation(
          id: "mut_wear_${DateTime.now().millisecondsSinceEpoch}",
          entityType: "wear_event",
          entityId: event.itemId,
          mutationType: "INSERT",
          payload: {"wardrobe_item_id": event.itemId, "event_context": event.context},
          timestamp: DateTime.now(),
        ));

        syncEngine.flushQueue().ignore();

        if (state is WardrobeLoaded) {
          final current = state as WardrobeLoaded;
          _applyFilter(emit, current.selectedCategory, current.searchQuery);
        }
      }
    });
  }

  Future<void> _saveToCache() async {
    try {
      final jsonList = _localItems.map((i) => i.toJson()).toList();
      await SecureStorage.saveWardrobeCache(jsonEncode(jsonList));
    } catch (_) {}
  }

  void _applyFilter(Emitter<WardrobeState> emit, String category, String query) {
    var filtered = List<WardrobeItemModel>.from(_localItems);
    if (category != 'All') {
      filtered = filtered.where((i) => i.category.toLowerCase() == category.toLowerCase()).toList();
    }
    if (query.isNotEmpty) {
      filtered = filtered.where((i) =>
        i.name.toLowerCase().contains(query.toLowerCase()) ||
        i.subcategory.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    emit(WardrobeLoaded(
      allItems: _localItems,
      filteredItems: filtered,
      selectedCategory: category,
      searchQuery: query,
    ));
  }
}
