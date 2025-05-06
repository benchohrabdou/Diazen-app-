import 'package:diazen/authentication/loginpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Importez la classe Loginpage

void main() {
  testWidgets('Login page test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: Loginpage()));

    // Verify that the login page is displayed.
    expect(find.text('Welcome back'), findsOneWidget);

    // Enter a valid email and password.
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'password123');

    // Tap the 'Sign in' button and trigger a frame.
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    // Verify that the home page is displayed.
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Login page test with invalid credentials',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: Loginpage()));

    // Verify that the login page is displayed.
    expect(find.text('Welcome back'), findsOneWidget);

    // Enter an invalid email and password.
    await tester.enterText(find.byType(TextField).first, 'invalid@example.com');
    await tester.enterText(find.byType(TextField).last, 'wrongpassword');

    // Tap the 'Sign in' button and trigger a frame.
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    // Verify that an error message is displayed.
    expect(find.text('Invalid email or password'), findsOneWidget);
  });
}
