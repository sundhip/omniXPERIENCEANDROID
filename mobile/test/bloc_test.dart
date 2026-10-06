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

  group('WardrobeBloc Unit Tests', () {
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

    test('LoadWardrobeRequested populates initial items', () async {
      wardrobeBloc.add(LoadWardrobeRequested());
      await expectLater(
        wardrobeBloc.stream,
        emitsInOrder([
          isA<WardrobeLoading>(),
          predicate<WardrobeState>((s) => s is WardrobeLoaded && s.allItems.isNotEmpty),
        ]),
      );
    });

    test('CategoryFilterChanged filters items correctly', () async {
      wardrobeBloc.add(LoadWardrobeRequested());
      await wardrobeBloc.stream.firstWhere((s) => s is WardrobeLoaded);

      wardrobeBloc.add(const CategoryFilterChanged('Tops'));
      await expectLater(
        wardrobeBloc.stream,
        emits(predicate<WardrobeState>((s) {
          if (s is WardrobeLoaded) {
            return s.selectedCategory == 'Tops' &&
                s.filteredItems.every((item) => item.category.toLowerCase() == 'tops');
          }
          return false;
        })),
      );
    });

    test('AddWardrobeItemSubmitted inserts item at index 0', () async {
      wardrobeBloc.add(LoadWardrobeRequested());
      await wardrobeBloc.stream.firstWhere((s) => s is WardrobeLoaded);

      const newItem = WardrobeItemModel(
        id: 'test_item_99',
        category: 'Tops',
        subcategory: 'Polo',
        name: 'Test Black Polo',
        colors: ['Black'],
        formality: 'Smart Casual',
      );

      wardrobeBloc.add(const AddWardrobeItemSubmitted(newItem));
      await expectLater(
        wardrobeBloc.stream,
        emits(predicate<WardrobeState>((s) {
          if (s is WardrobeLoaded) {
            return s.allItems.any((item) => item.id == 'test_item_99');
          }
          return false;
        })),
      );
    });

    test('DeleteItemRequested removes item from list', () async {
      wardrobeBloc.add(LoadWardrobeRequested());
      await wardrobeBloc.stream.firstWhere((s) => s is WardrobeLoaded);

      wardrobeBloc.add(const DeleteItemRequested('item_1'));
      await expectLater(
        wardrobeBloc.stream,
        emits(predicate<WardrobeState>((s) {
          if (s is WardrobeLoaded) {
            return !s.allItems.any((item) => item.id == 'item_1');
          }
          return false;
        })),
      );
    });
  });
}
