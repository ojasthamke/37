import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aplibhaji_admin/main.dart';

void main() {
  testWidgets('Login screen loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: ApliBhajiAdminApp()));

    // Verify that login elements are found.
    expect(find.text('Orderkart admin'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
