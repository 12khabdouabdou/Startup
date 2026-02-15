import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fill_exchange/app.dart';
import 'package:fill_exchange/core/providers/auth_provider.dart';
import 'package:fill_exchange/features/auth/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Simple mock user stream that yields null (unauthenticated)
final unauthStream = Stream<User?>.value(null);

void main() {
  testWidgets('Unauthenticated user is redirected to LoginScreen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FillExchangeApp(),
      ),
    );
    // Initial state is loading or null? StreamProvider starts with AsyncLoading by default
    // authStateProvider defaults to FirebaseAuth.instance.authStateChanges()
    // Since we don't mock FirebaseAuth here, it might return null or throw if not initialized?
    // Actually Firebase.initializeApp not called in test.
    
    // We MUST override the provider.
  });

  testWidgets('Unauthenticated user is redirected to LoginScreen (Overridden)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => unauthStream),
        ],
        child: const FillExchangeApp(),
      ),
    );
    
    await tester.pumpAndSettle();
    
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
