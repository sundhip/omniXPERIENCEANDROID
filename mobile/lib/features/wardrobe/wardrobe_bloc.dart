import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/sync/sync_engine.dart';
import 'wardrobe_repository.dart';

// EVENTS
abstract class WardrobeEvent extends Equatable {
  const WardrobeEvent();
  @override
  List<Object?> get props => [];
}

class LoadWardrobeRequested extends WardrobeEvent {
  final bool forceRefresh;
  const LoadWardrobeRequested({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

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

class FavoriteFilterToggled extends WardrobeEvent {}

class ToggleItemFavoriteRequested extends WardrobeEvent {
  final String itemId;
  const ToggleItemFavoriteRequested(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class AddWardrobeItemSubmitted extends WardrobeEvent {
  final WardrobeItemModel item;
  const AddWardrobeItemSubmitted(this.item);
  @override
  List<Object?> get props => [item];
}

class UpdateWardrobeItemSubmitted extends WardrobeEvent {
  final WardrobeItemModel item;
  const UpdateWardrobeItemSubmitted(this.item);
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

// STATES
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
  final bool showFavoritesOnly;
  final bool isSyncing;

  const WardrobeLoaded({
    required this.allItems,
    required this.filteredItems,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.showFavoritesOnly = false,
    this.isSyncing = false,
  });

  WardrobeLoaded copyWith({
    List<WardrobeItemModel>? allItems,
    List<WardrobeItemModel>? filteredItems,
    String? selectedCategory,
    String? searchQuery,
    bool? showFavoritesOnly,
    bool? isSyncing,
  }) {
    return WardrobeLoaded(
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [
    allItems, filteredItems, selectedCategory, searchQuery, showFavoritesOnly, isSyncing
  ];
}

class WardrobeError extends WardrobeState {
  final String message;
  const WardrobeError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLOC
class WardrobeBloc extends Bloc<WardrobeEvent, WardrobeState> {
  final ApiClient apiClient;
  final SyncEngine syncEngine;
  late final WardrobeRepository repository;
  List<WardrobeItemModel> _localItems = [];

  WardrobeBloc({
    required this.apiClient,
    required this.syncEngine,
  }) : super(WardrobeInitial()) {
    repository = WardrobeRepository(apiClient: apiClient);

    on<LoadWardrobeRequested>(_onLoadWardrobe);
    on<CategoryFilterChanged>(_onCategoryFilterChanged);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<FavoriteFilterToggled>(_onFavoriteFilterToggled);
    on<ToggleItemFavoriteRequested>(_onToggleItemFavorite);
    on<AddWardrobeItemSubmitted>(_onAddItem);
    on<UpdateWardrobeItemSubmitted>(_onUpdateItem);
    on<DeleteItemRequested>(_onDeleteItem);
    on<MarkItemAsWornRequested>(_onMarkItemWorn);
  }

  Future<void> _onLoadWardrobe(
    LoadWardrobeRequested event,
    Emitter<WardrobeState> emit,
  ) async {
    if (state is! WardrobeLoaded || event.forceRefresh) {
      emit(WardrobeLoading());
    }

    try {
      // 1. Load from persistent local secure cache
      final cached = await SecureStorage.getWardrobeCache();
      if (cached != null && cached.isNotEmpty) {
        try {
          final List decoded = jsonDecode(cached);
          _localItems = decoded.map((j) => WardrobeItemModel.fromJson(j)).toList();
        } catch (_) {
          _localItems = [];
        }
      }

      // If we had cache, emit immediately for fast offline-first render
      if (_localItems.isNotEmpty && state is! WardrobeLoaded) {
        _applyFilters(emit, category: 'All', query: '', favOnly: false);
      }

      // 2. Fetch fresh items from backend
      try {
        final remoteItems = await repository.getWardrobeItems();
        _localItems = remoteItems;
        await _saveToCache();
      } catch (e) {
        // If remote fails, fallback to local cache
        if (_localItems.isEmpty) {
          // If both fail and empty, it is an empty wardrobe, not an error
          _localItems = [];
        }
      }

      final curCat = (state is WardrobeLoaded) ? (state as WardrobeLoaded).selectedCategory : 'All';
      final curQ = (state is WardrobeLoaded) ? (state as WardrobeLoaded).searchQuery : '';
      final curFav = (state is WardrobeLoaded) ? (state as WardrobeLoaded).showFavoritesOnly : false;
      _applyFilters(emit, category: curCat, query: curQ, favOnly: curFav);
    } catch (e) {
      emit(WardrobeError(e.toString()));
    }
  }

  void _onCategoryFilterChanged(
    CategoryFilterChanged event,
    Emitter<WardrobeState> emit,
  ) {
    if (state is WardrobeLoaded) {
      final s = state as WardrobeLoaded;
      _applyFilters(emit, category: event.category, query: s.searchQuery, favOnly: s.showFavoritesOnly);
    }
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<WardrobeState> emit,
  ) {
    if (state is WardrobeLoaded) {
      final s = state as WardrobeLoaded;
      _applyFilters(emit, category: s.selectedCategory, query: event.query, favOnly: s.showFavoritesOnly);
    }
  }

  void _onFavoriteFilterToggled(
    FavoriteFilterToggled event,
    Emitter<WardrobeState> emit,
  ) {
    if (state is WardrobeLoaded) {
      final s = state as WardrobeLoaded;
      _applyFilters(emit, category: s.selectedCategory, query: s.searchQuery, favOnly: !s.showFavoritesOnly);
    }
  }

  Future<void> _onToggleItemFavorite(
    ToggleItemFavoriteRequested event,
    Emitter<WardrobeState> emit,
  ) async {
    final idx = _localItems.indexWhere((i) => i.id == event.itemId);
    if (idx != -1) {
      final old = _localItems[idx];
      final updated = old.copyWith(favorite: !old.favorite);
      _localItems[idx] = updated;
      await _saveToCache();

      if (state is WardrobeLoaded) {
        final s = state as WardrobeLoaded;
        _applyFilters(emit, category: s.selectedCategory, query: s.searchQuery, favOnly: s.showFavoritesOnly);
      }

      // Sync with backend
      try {
        await repository.toggleFavorite(event.itemId);
      } catch (_) {}
    }
  }

  Future<void> _onAddItem(
    AddWardrobeItemSubmitted event,
    Emitter<WardrobeState> emit,
  ) async {
    _localItems.insert(0, event.item);
    await _saveToCache();

    if (state is WardrobeLoaded) {
      final s = state as WardrobeLoaded;
      _applyFilters(emit, category: s.selectedCategory, query: s.searchQuery, favOnly: s.showFavoritesOnly);
    } else {
      _applyFilters(emit, category: 'All', query: '', favOnly: false);
    }

    // Persist to backend and queue mutation for offline resilience
    syncEngine.queueMutation(SyncMutation(
      id: "mut_${DateTime.now().millisecondsSinceEpoch}",
      entityType: "wardrobe_item",
      entityId: event.item.id,
      mutationType: "INSERT",
      payload: event.item.toJson(),
      timestamp: DateTime.now(),
    ));

    try {
      final created = await repository.createWardrobeItem(event.item);
      final index = _localItems.indexWhere((i) => i.id == event.item.id);
      if (index != -1) {
        _localItems[index] = created;
        await _saveToCache();
        if (state is WardrobeLoaded) {
          final s = state as WardrobeLoaded;
          _applyFilters(emit, category: s.selectedCategory, query: s.searchQuery, favOnly: s.showFavoritesOnly);
        }
      }
    } catch (_) {
      syncEngine.flushQueue().ignore();
    }
  }

  Future<void> _onUpdateItem(
    UpdateWardrobeItemSubmitted event,
    Emitter<WardrobeState> emit,
  ) async {
    final idx = _localItems.indexWhere((i) => i.id == event.item.id);
    if (idx != -1) {
      _localItems[idx] = event.item;
      await _saveToCache();

      if (state is WardrobeLoaded) {
        final s = state as WardrobeLoaded;
        _applyFilters(emit, category: s.selectedCategory, query: s.searchQuery, favOnly: s.showFavoritesOnly);
      }

      try {
        await repository.updateWardrobeItem(event.item);
      } catch (_) {}
    }
  }

  Future<void> _onDeleteItem(
    DeleteItemRequested event,
    Emitter<WardrobeState> emit,
  ) async {
    _localItems.removeWhere((i) => i.id == event.itemId);
    await _saveToCache();

    if (state is WardrobeLoaded) {
      final s = state as WardrobeLoaded;
      _applyFilters(emit, category: s.selectedCategory, query: s.searchQuery, favOnly: s.showFavoritesOnly);
    }

    syncEngine.queueMutation(SyncMutation(
      id: "mut_del_${DateTime.now().millisecondsSinceEpoch}",
      entityType: "wardrobe_item",
      entityId: event.itemId,
      mutationType: "DELETE",
      payload: {"id": event.itemId},
      timestamp: DateTime.now(),
    ));

    try {
      await repository.deleteWardrobeItem(event.itemId);
    } catch (_) {}
  }

  Future<void> _onMarkItemWorn(
    MarkItemAsWornRequested event,
    Emitter<WardrobeState> emit,
  ) async {
    final idx = _localItems.indexWhere((i) => i.id == event.itemId);
    if (idx != -1) {
      final old = _localItems[idx];
      final updated = old.copyWith(
        wearCount: old.wearCount + 1,
        lastWornDate: DateTime.now(),
      );
      _localItems[idx] = updated;
      await _saveToCache();

      if (state is WardrobeLoaded) {
        final s = state as WardrobeLoaded;
        _applyFilters(emit, category: s.selectedCategory, query: s.searchQuery, favOnly: s.showFavoritesOnly);
      }

      try {
        await repository.updateWardrobeItem(updated);
      } catch (_) {}
    }
  }

  void _applyFilters(
    Emitter<WardrobeState> emit, {
    required String category,
    required String query,
    required bool favOnly,
  }) {
    var filtered = List<WardrobeItemModel>.from(_localItems);

    if (category != 'All') {
      filtered = filtered.where((i) => i.category.toLowerCase() == category.toLowerCase()).toList();
    }

    if (favOnly) {
      filtered = filtered.where((i) => i.favorite).toList();
    }

    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = filtered.where((i) {
        final inName = i.name.toLowerCase().contains(q);
        final inCategory = i.category.toLowerCase().contains(q);
        final inSubcat = i.subcategory.toLowerCase().contains(q);
        final inBrand = (i.brand ?? '').toLowerCase().contains(q);
        final inColor = (i.primaryColor ?? '').toLowerCase().contains(q) ||
            i.colors.any((c) => c.toLowerCase().contains(q));
        final inPattern = i.pattern.toLowerCase().contains(q);
        return inName || inCategory || inSubcat || inBrand || inColor || inPattern;
      }).toList();
    }

    emit(WardrobeLoaded(
      allItems: List.unmodifiable(_localItems),
      filteredItems: List.unmodifiable(filtered),
      selectedCategory: category,
      searchQuery: query,
      showFavoritesOnly: favOnly,
    ));
  }

  Future<void> _saveToCache() async {
    try {
      final jsonStr = jsonEncode(_localItems.map((i) => i.toJson()).toList());
      await SecureStorage.setWardrobeCache(jsonStr);
    } catch (_) {}
  }
}
