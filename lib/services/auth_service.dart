import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:waste_logistics/models/user.dart';

class AuthService {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  supabase.User? get currentUser => _supabase.auth.currentUser;

  Stream<supabase.AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<supabase.AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<supabase.AuthResponse> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserType userType,
    String? companyName,
    String? address,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'phone': phone,
        'user_type': userType.name,
        if (companyName != null) 'company_name': companyName,
        if (address != null) 'address': address,
      },
    );

    if (response.user != null) {
      final user = User(
        id: response.user!.id,
        email: email,
        name: name,
        phone: phone,
        userType: userType,
        companyName: companyName,
        address: address,
        createdAt: DateTime.now(),
      );

      await _supabase.from('users').insert(user.toJson());
    }

    return response;
  }

  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      supabase.OAuthProvider.google,
      redirectTo: 'io.supabase.waste_logistics://auth-callback',
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<User?> getUserData(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    if (response != null) {
      return User.fromJson(response);
    }
    return null;
  }

  Future<void> updateUserData(User user) async {
    await _supabase.from('users').update(user.toJson()).eq('id', user.id);
  }

  Stream<User?> getUserStream(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => data.isNotEmpty ? User.fromJson(data.first) : null);
  }
}
