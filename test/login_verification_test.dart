import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aplibhaji_admin/main.dart';
import 'package:aplibhaji_admin/features/auth/login_screen.dart';

void main() {
  testWidgets('Login Screen input and focus validation test', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ProviderScope(child: ApliBhajiAdminApp()));
    await tester.pumpAndSettle();

    // 1. Verify text fields exist
    final emailFieldFinder = find.widgetWithText(TextFormField, 'Email Address');
    final passwordFieldFinder = find.widgetWithText(TextFormField, 'Password');
    final loginButtonFinder = find.text('LOGIN');

    expect(emailFieldFinder, findsOneWidget);
    expect(passwordFieldFinder, findsOneWidget);
    expect(loginButtonFinder, findsOneWidget);

    // 2. Tap Email field and enter text
    await tester.tap(emailFieldFinder);
    await tester.pump();
    await tester.enterText(emailFieldFinder, 'test@example.com');
    await tester.pump();
    expect(find.text('test@example.com'), findsOneWidget);

    // 3. Tap Password field and enter text
    await tester.tap(passwordFieldFinder);
    await tester.pump();
    await tester.enterText(passwordFieldFinder, 'password123');
    await tester.pump();
    expect(find.text('password123'), findsOneWidget);

    // 4. Verify password obscure text holds
    final passwordTextField = tester.widget<TextField>(
      find.descendant(of: passwordFieldFinder, matching: find.byType(TextField))
    );
    expect(passwordTextField.obscureText, isTrue);

    // 5. Tap the toggle suffix icon to show password
    final suffixIconFinder = find.descendant(
      of: passwordFieldFinder,
      matching: find.byType(IconButton),
    );
    expect(suffixIconFinder, findsOneWidget);
    await tester.tap(suffixIconFinder);
    await tester.pump();

    // Verify it toggled to false
    final passwordTextFieldUpdated = tester.widget<TextField>(
      find.descendant(of: passwordFieldFinder, matching: find.byType(TextField))
    );
    expect(passwordTextFieldUpdated.obscureText, isFalse);
  });
}
