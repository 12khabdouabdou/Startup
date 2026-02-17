import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fill_exchange/features/auth/screens/login_screen.dart';
import 'package:fill_exchange/features/auth/repositories/auth_repository.dart';

class MockGoTrueClient extends Fake implements GoTrueClient {
  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();
}

class MockAuthRepository implements AuthRepository {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<void> signInWithOtp({required String phoneNumber}) async {}

  @override
  Future<AuthResponse> verifyOtp({required String phoneNumber, required String token}) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponse> signInWithPassword({required String email, required String password}) async {
    return AuthResponse(session: null, user: null);
  }

  @override
  Future<AuthResponse> signUpWithPassword({required String email, required String password}) async {
    return AuthResponse(session: null, user: null);
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('LoginScreen renders and switches to Email Auth', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    // Initial state: Phone Auth
    expect(find.text('Sign in with Phone'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget); // ChoiceChip label
    expect(find.text('Email'), findsOneWidget); // ChoiceChip label
    
    // Switch to Email
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    // Verify Email UI
    expect(find.text('Sign In'), findsOneWidget); // Title or Button
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    
    // Toggle to Sign Up
    await tester.tap(find.text('Don\'t have an account? Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget); // Title
    expect(find.text('Sign Up'), findsOneWidget); // Button label
  });
}
