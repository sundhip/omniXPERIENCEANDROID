import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:omnipresence/main.dart';
import 'package:omnipresence/core/network/api_client.dart';
import 'package:omnipresence/core/sync/sync_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('OmniPresence app smoke test - renders LoginView on unauthenticated startup', (WidgetTester tester) async {
    final apiClient = ApiClient();
    final syncEngine = SyncEngine(apiClient: apiClient);

    await tester.pumpWidget(OmniPresenceApp(
      apiClient: apiClient,
      syncEngine: syncEngine,
    ));

    // Pump frames to complete async initialization
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify OMNIPRESENCE title and login elements exist
    expect(find.text('OMNIPRESENCE'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
