import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/repositories/auth_repository.dart';


enum AuthStatus { initial, loading, codeSent, verified, error, emailVerificationRequired, passwordResetSent }

class AuthState {
  final AuthStatus status;
  final String? phoneNumber; // Changed verifyingId to phoneNumber for Supabase flow
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.phoneNumber,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(const AuthState());

  Future<void> sendCode(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null, phoneNumber: phoneNumber);
    try {
      await _repo.signInWithOtp(phoneNumber: phoneNumber);
      state = state.copyWith(status: AuthStatus.codeSent);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (state.phoneNumber == null) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: "Phone number missing for verification context.");
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repo.verifyOtp(phoneNumber: state.phoneNumber!, token: otp);
      state = state.copyWith(status: AuthStatus.verified);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repo.signInWithPassword(email: email, password: password);
      state = state.copyWith(status: AuthStatus.verified);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repo.signUpWithPassword(email: email, password: password);
      // If session is null, email confirmation is required (default Supabase behavior)
      if (response.session != null) {
        state = state.copyWith(status: AuthStatus.verified);
      } else {
        state = state.copyWith(status: AuthStatus.emailVerificationRequired);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      try {
        await _repo.resetPasswordForEmail(email: email);
        state = state.copyWith(status: AuthStatus.passwordResetSent);
      } catch (e) {
        state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
      }
    }

  void reset() {
    state = const AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
