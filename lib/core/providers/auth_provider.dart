import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the stream of user authentication state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((event) => event.session?.user);
});

/// Provides boolean authentication status.
///
/// Returns [true] if user is logged in, [false] otherwise.
/// Defaults to [false] if loading or error.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).value != null;
});

/// Provides the current authenticated user or null.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});
