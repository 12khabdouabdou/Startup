import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, codeSent, verified, error }

class AuthState {
  final AuthStatus status;
  final String? verificationId;
  final int? resendToken;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.verificationId,
    this.resendToken,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? verificationId,
    int? resendToken,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken, // For Resend
      errorMessage: errorMessage, // Reset error if not provided? Or keep?
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(const AuthState());

  Future<void> sendCode(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repo.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          // Android Auto-Verification
          await _repo.signInWithCredential(credential);
          state = state.copyWith(status: AuthStatus.verified);
        },
        verificationFailed: (e) {
          state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
        },
        codeSent: (verificationId, resendToken) {
          state = state.copyWith(
            status: AuthStatus.codeSent,
            verificationId: verificationId,
            resendToken: resendToken,
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (state.verificationId == null) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: "Verification ID missing");
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: otp,
      );
      await _repo.signInWithCredential(credential);
      state = state.copyWith(status: AuthStatus.verified);
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
