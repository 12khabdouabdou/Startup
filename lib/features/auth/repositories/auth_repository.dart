import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  final GoTrueClient _auth;

  AuthRepository(this._auth);

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithOtp({
    required String phoneNumber,
  }) async {
    await _auth.signInWithOtp(phone: phoneNumber);
  }

  Future<AuthResponse> verifyOtp({
    required String phoneNumber,
    required String token,
  }) async {
    return await _auth.verifyOTP(
      phone: phoneNumber,
      token: token,
      type: OtpType.sms,
    );
  }
  
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client.auth);
});
