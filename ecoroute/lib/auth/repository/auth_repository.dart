import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/user_model.dart';
import '../../core/network/supabase_client.dart';

class AuthRepository {
  final SupabaseClientInstance _supabase = SupabaseClientInstance();

  Future<UserModel?> login(String email, String password) async {
    final response = await _supabase.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      return UserModel(
        id: response.user!.id,
        email: response.user!.email ?? email,
        role: response.user!.userMetadata?['role'] ?? 'developer',
      );
    }
    return null;
  }

  Future<UserModel?> signUp(String email, String password, String role) async {
    final response = await _supabase.client.auth.signUp(
      email: email,
      password: password,
      data: {'role': role},
    );

    if (response.user != null) {
      return UserModel(
        id: response.user!.id,
        email: response.user!.email ?? email,
        role: role,
      );
    }
    return null;
  }

  Future<void> logout() async {
    await _supabase.client.auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _supabase.client.auth.currentUser;
    if (user != null) {
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        role: user.userMetadata?['role'] ?? 'developer',
      );
    }
    return null;
  }

  Stream<AuthStateChange> get authStateChanges =>
      _supabase.client.auth.onAuthStateChange;
}
