import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/supabase_error_handler.dart';
import '../../../core/services/supabase_service.dart';
import '../mock/mock_datasources.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  if (kIsWeb || !SupabaseService.instance.isInitialized) {
    return MockAuthDataSourceImpl();
  }
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseAuthDataSourceImpl(supabase);
});

abstract class AuthRemoteDataSource {
  Stream<AuthState> get onAuthStateChange;
  User? get currentUser;
  Session? get currentSession;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  });

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<UserResponse> updateUserPassword(String newPassword);

  Future<void> signOut();

  Future<void> deleteAccount();
}

class SupabaseAuthDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;

  SupabaseAuthDataSourceImpl(this._supabase);

  @override
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Session? get currentSession => _supabase.auth.currentSession;

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'username': username.trim().toLowerCase(),
          'display_name': displayName.trim(),
        },
      );
      return response;
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'com.rlstudio.telora://login-callback',
      );
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<UserResponse> updateUserPassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      // Calls trusted server-side Edge Function to remove user auth & associated assets safely
      await _supabase.functions.invoke('delete-account');
      await _supabase.auth.signOut();
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }
}
