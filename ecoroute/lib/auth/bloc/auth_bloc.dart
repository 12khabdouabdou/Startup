import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthCheckRequested>(_onCheck);
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    try {
      emit(const AuthLoading());
      // TODO: Implement actual Supabase login
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock successful login
      final user = UserModel(
        id: '1',
        email: event.email,
        role: 'developer',
      );
      
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUp(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    try {
      emit(const AuthLoading());
      // TODO: Implement actual Supabase signup
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock successful signup
      final user = UserModel(
        id: '1',
        email: event.email,
        role: event.role,
      );
      
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    try {
      // TODO: Implement actual Supabase logout
      await Future.delayed(const Duration(milliseconds: 500));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    try {
      emit(const AuthLoading());
      // TODO: Check if user is already logged in
      await Future.delayed(const Duration(milliseconds: 500));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
