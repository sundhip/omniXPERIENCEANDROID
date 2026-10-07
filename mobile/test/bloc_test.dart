import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:omnipresence/features/auth/auth_bloc.dart';
import 'package:omnipresence/features/wardrobe/wardrobe_bloc.dart';
import 'package:omnipresence/core/network/api_client.dart';
import 'package:omnipresence/core/sync/sync_engine.dart';
import 'package:omnipresence/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AuthBloc Unit Tests', () {
    late ApiClient apiClient;
    late AuthBloc authBloc;

    setUp(() {
      apiClient = ApiClient();
      authBloc = AuthBloc(apiClient: apiClient);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    test('LogoutRequested emits Unauthenticated', () async {
      authBloc.add(LogoutRequested());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<Unauthenticated>(),
        ]),
      );
    });

    test('LoginSubmitted with empty fields emits AuthError without network call', () async {
      authBloc.add(const LoginSubmitted('', ''));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s is AuthError && s.message.contains('email and password')),
        ]),
      );
    });
  });

  group('WardrobeBloc Phase 4 Unit Tests', () {
    late ApiClient apiClient;
    late SyncEngine syncEngine;
    late WardrobeBloc wardrobeBloc;

    setUp(() {
      apiClient = ApiClient();
      syncEngine = SyncEngine(apiClient: apiClient);
      wardrobeBloc = WardrobeBloc(apiClient: apiClient, syncEngine: syncEngine);
    });

    tearDown(() {
      wardrobeBloc.close();
    });

    test('initial state is WardrobeInitial', () {
      expect(wardrobeBloc.state, equals(WardrobeInitial()));
    });

    test('LoadWardrobeRequested populates state cleanly without fake mocks', () async {
      wardrobeBloc.add(const LoadWardrobeRequested());
      await expectLater(
        wardrobeBloc.stream,
        emitsInOrder([
          isA<WardrobeLoading>(),
          isA<WardrobeLoaded>(),
        ]),
      );
    });

    test('AddWardrobeItemSubmitted inserts item and updates state', () async {
      wardrobeBloc.add(const LoadWardrobeRequested());
      await wardrobeBloc.stream.firstWhere((s) => s is WardrobeLoaded);

      const newItem = WardrobeItemModel(
        id: 'test_item_99',
        category: 'Tops',
        subcategory: 'Polo',
        name: 'Test Black Polo',
        primaryColor: 'Black',
        colors: ['Black'],
        formality: 'Smart Casual',
        pattern: 'Solid',
        aiAnalyzed: true,
        aiConfidence: 0.94,
      );

      wardrobeBloc.add(const AddWardrobeItemSubmitted(newItem));
      await expectLater(
        wardrobeBloc.stream,
        emits(predicate<WardrobeState>((s) {
          if (s is WardrobeLoaded) {
            return s.allItems.any((item) => item.id == 'test_item_99') &&
                   s.allItems.first.aiAnalyzed == true &&
                   s.allItems.first.pattern == 'Solid';
          }
          return false;
        })),
      );
    });

    test('CategoryFilterChanged filters items correctly', () async {
      wardrobeBloc.add(const LoadWardrobeRequested());
      await wardrobeBloc.stream.firstWhere((s) => s is WardrobeLoaded);

      const itemTop = WardrobeItemModel(
        id: 'item_top',
        category: 'Tops',
        subcategory: 'T-Shirt',
        name: 'Blue Tee',
        colors: ['Blue'],
      );
      const itemBottom = WardrobeItemModel(
        id: 'item_bottom',
        category: 'Bottoms',
        subcategory: 'Jeans',
        name: 'Indigo Jeans',
        colors: ['Blue'],
      );

      wardrobeBloc.add(const AddWardrobeItemSubmitted(itemTop));
      await wardrobeBloc.stream.firstWhere((s) => s is WardrobeLoaded && s.allItems.length == 1);

      wardrobeBloc.add(const AddWardrobeItemSubmitted(itemBottom));
      await wardrobeBloc.stream.firstWhere((s) => s is WardrobeLoaded && s.allItems.length == 2);

      wardrobeBloc.add(const CategoryFilterChanged('Tops'));
      final filteredState = await wardrobeBloc.stream.firstWhere(
        (s) => s is WardrobeLoaded && s.selectedCategory == 'Tops',
      ) as WardrobeLoaded;

      expect(filteredState.selectedCategory, 'Tops');
      expect(filteredState.filteredItems.length, 1);
      expect(filteredState.filteredItems.first.category, 'Tops');
    });

    test('ToggleItemFavoriteRequested toggles favorite on item', () async {
      wardrobeBloc.add(const LoadWardrobeRequested());
      await wardrobeBloc.stream.firstWhere((s) => s is WardrobeLoaded);

      const item = WardrobeItemModel(
        id: 'fav_item_1',
        category: 'Tops',
        subcategory: 'Shirt',
        name: 'Oxford Shirt',
        favorite: false,
      );
      wardrobeBloc.add(const AddWardrobeItemSubmitted(item));
      await wardrobeBloc.stream.firstWhere((s) => s is WardrobeLoaded && s.allItems.any((i) => i.id == 'fav_item_1'));

      wardrobeBloc.add(const ToggleItemFavoriteRequested('fav_item_1'));
      final favState = await wardrobeBloc.stream.firstWhere(
        (s) => s is WardrobeLoaded && s.allItems.any((i) => i.id == 'fav_item_1' && i.favorite),
      ) as WardrobeLoaded;

      final found = favState.allItems.firstWhere((i) => i.id == 'fav_item_1');
      expect(found.favorite, isTrue);
    });

    test('DeleteItemRequested removes item from list', () async {
      wardrobeBloc.add(const LoadWardrobeRequested());
      await wardrobeBloc.stream.firstWhere((s) => s is WardrobeLoaded);

      const item = WardrobeItemModel(
        id: 'del_item_1',
        category: 'Outerwear',
        subcategory: 'Jacket',
        name: 'Leather Jacket',
      );
      wardrobeBloc.add(const AddWardrobeItemSubmitted(item));
      await wardrobeBloc.stream.firstWhere((s) => s is WardrobeLoaded && s.allItems.any((i) => i.id == 'del_item_1'));

      wardrobeBloc.add(const DeleteItemRequested('del_item_1'));
      final delState = await wardrobeBloc.stream.firstWhere(
        (s) => s is WardrobeLoaded && !s.allItems.any((i) => i.id == 'del_item_1'),
      ) as WardrobeLoaded;

      expect(delState.allItems.any((i) => i.id == 'del_item_1'), isFalse);
    });
  });
}
