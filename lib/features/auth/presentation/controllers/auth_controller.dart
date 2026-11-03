import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../data/datasources/remote/supabase_auth_datasource.dart';
import 'auth_state.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AppAuthState>((ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthController(dataSource);
});

final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.userId;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.isAuthenticated;
});

class AuthController extends StateNotifier<AppAuthState> {
  final AuthRemoteDataSource _dataSource;
  StreamSubscription<AuthState>? _authSubscription;

  AuthController(this._dataSource) : super(AppAuthState.initial()) {
    _initAuthListener();
  }

  void _initAuthListener() {
    // Check initial user from Supabase session on startup
    final initialUser = _dataSource.currentUser;
    final initialSession = _dataSource.currentSession;
    if (initialUser != null && initialSession != null) {
      state = AppAuthState.authenticated(
        userId: initialUser.id,
        email: initialUser.email ?? '',
      );
    } else {
      state = AppAuthState.unauthenticated();
    }

    // Subscribe to centralized Supabase auth lifecycle events
    _authSubscription = _dataSource.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          if (session?.user != null) {
            state = AppAuthState.authenticated(
              userId: session!.user.id,
              email: session.user.email ?? '',
            );
          }
          break;
        case AuthChangeEvent.signedOut:
        case AuthChangeEvent.userDeleted:
          state = AppAuthState.unauthenticated();
          break;
        case AuthChangeEvent.passwordRecovery:
          // User opened deep link for password reset
          if (session?.user != null) {
            state = AppAuthState.authenticated(
              userId: session!.user.id,
              email: session.user.email ?? '',
            );
          }
          break;
        default:
          break;
      }
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = AppAuthState.loading();
    try {
      final response = await _dataSource.signInWithEmail(
        email: email,
        password: password,
      );
      if (response.user != null) {
        state = AppAuthState.authenticated(
          userId: response.user!.id,
          email: response.user!.email ?? '',
        );
      } else {
        state = AppAuthState.unauthenticated();
      }
    } catch (e) {
      state = AppAuthState.error(ErrorHandler.getUserMessage(e));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    state = AppAuthState.loading();
    try {
      final response = await _dataSource.signUpWithEmail(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      );

      // If email confirmation is enabled on Supabase, session is null until verified
      if (response.session == null && response.user != null) {
        state = AppAuthState.verificationRequired(email: email.trim());
      } else if (response.user != null) {
        state = AppAuthState.authenticated(
          userId: response.user!.id,
          email: response.user!.email ?? '',
        );
      } else {
        state = AppAuthState.unauthenticated();
      }
    } catch (e) {
      state = AppAuthState.error(ErrorHandler.getUserMessage(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    state = AppAuthState.loading();
    try {
      await _dataSource.sendPasswordResetEmail(email);
      state = const AppAuthState(
        status: AuthStatus.unauthenticated,
        successMessage: 'Instructions to reset your password have been sent to your email.',
      );
    } catch (e) {
      state = AppAuthState.error(ErrorHandler.getUserMessage(e));
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    state = AppAuthState.loading();
    try {
      await _dataSource.updateUserPassword(newPassword);
      final currentUser = _dataSource.currentUser;
      state = AppAuthState.authenticated(
        userId: currentUser?.id ?? '',
        email: currentUser?.email ?? '',
      );
    } catch (e) {
      state = AppAuthState.error(ErrorHandler.getUserMessage(e));
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = AppAuthState.loading();
    try {
      await _dataSource.signOut();
      state = AppAuthState.unauthenticated();
    } catch (e) {
      state = AppAuthState.error(ErrorHandler.getUserMessage(e));
    }
  }

  Future<void> deleteAccount() async {
    state = AppAuthState.loading();
    try {
      await _dataSource.deleteAccount();
      state = AppAuthState.unauthenticated();
    } catch (e) {
      state = AppAuthState.error(ErrorHandler.getUserMessage(e));
    }
  }

  void clearMessages() {
    if (state.errorMessage != null || state.successMessage != null) {
      state = AppAuthState(
        status: state.status,
        userId: state.userId,
        email: state.email,
        errorMessage: null,
        successMessage: null,
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
