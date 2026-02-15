import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fill_exchange/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders correctly', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Sign in with Phone'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Send Verification Code'), findsOneWidget);
  });
}
