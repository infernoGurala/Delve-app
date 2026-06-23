import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:delve_app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('Delve app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DelveApp());
    expect(find.byType(DelveApp), findsOneWidget);
  });
}
