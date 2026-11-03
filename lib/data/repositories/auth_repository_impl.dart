import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/supabase_error_handler.dart';
import '../../core/services/supabase_service.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/supabase_auth_datasource.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(dataSource, supabase);
});

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final SupabaseClient _supabase;

  AuthRepositoryImpl(this._dataSource, this._supabase);

  @override
  Stream<String?> get authStateChanges =>
      _dataSource.onAuthStateChange.map((state) => state.session?.user.id);

  @override
  String? get currentUserId => _dataSource.currentUser?.id;

  @override
  Future<ProfileEntity> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final response = await _dataSource.signUpWithEmail(
      email: email,
      password: password,
      username: username,
      displayName: displayName,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException(
        message: 'Registration was successful, but account activation is required. Please check your email.',
        code: 'CONFIRMATION_REQUIRED',
      );
    }

    // Try fetching the bootstrapped profile created by handle_new_user() trigger
    return await _fetchOrCreateProfile(
      userId: user.id,
      username: username,
      displayName: displayName,
    );
  }

  @override
  Future<ProfileEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _dataSource.signInWithEmail(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException(
        message: 'Sign in failed. Could not retrieve user session.',
      );
    }

    return await _fetchOrCreateProfile(
      userId: user.id,
      username: user.userMetadata?['username'] as String? ?? 'user_${user.id.substring(0, 6)}',
      displayName: user.userMetadata?['display_name'] as String? ?? 'User',
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _dataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<void> updateUserPassword(String newPassword) async {
    await _dataSource.updateUserPassword(newPassword);
  }

  @override
  Future<void> signOut() async {
    await _dataSource.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    await _dataSource.deleteAccount();
  }

  Future<ProfileEntity> _fetchOrCreateProfile({
    required String userId,
    required String username,
    required String displayName,
  }) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        return ProfileEntity(
          id: data['id'] as String,
          username: data['username'] as String,
          displayName: data['display_name'] as String,
          avatarUrl: data['avatar_url'] as String?,
          bio: data['bio'] as String?,
          isOnline: data['is_online'] as bool? ?? false,
          lastSeen: DateTime.tryParse(data['last_seen'] as String? ?? ''),
          createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
        );
      }

      // If trigger had a momentary delay, insert profile row explicitly conforming to Phase 5 RLS
      final inserted = await _supabase.from('profiles').upsert({
        'id': userId,
        'username': username.toLowerCase().trim(),
        'display_name': displayName.trim(),
        'is_online': false,
        'last_seen': DateTime.now().toIso8601String(),
      }).select().single();

      return ProfileEntity(
        id: inserted['id'] as String,
        username: inserted['username'] as String,
        displayName: inserted['display_name'] as String,
        avatarUrl: inserted['avatar_url'] as String?,
        bio: inserted['bio'] as String?,
        isOnline: inserted['is_online'] as bool? ?? false,
        lastSeen: DateTime.tryParse(inserted['last_seen'] as String? ?? ''),
        createdAt: DateTime.tryParse(inserted['created_at'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }
}
