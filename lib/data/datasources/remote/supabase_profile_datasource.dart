import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/supabase_error_handler.dart';
import '../../../core/services/supabase_service.dart';
import '../../../domain/entities/profile_entity.dart';
import '../mock/mock_datasources.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  if (kIsWeb || !SupabaseService.instance.isInitialized) {
    return MockProfileDataSourceImpl();
  }
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseProfileDataSourceImpl(supabase);
});

abstract class ProfileRemoteDataSource {
  Future<ProfileEntity?> getProfile(String userId);
  Future<ProfileEntity?> getMyProfile();
  Future<ProfileEntity> updateProfile({
    required String userId,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  });
  Future<List<ProfileEntity>> searchUsers({
    required String query,
    int limit = 20,
    int offset = 0,
  });
  Future<String> uploadAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileExtension,
  });
  Future<void> deleteAvatar({required String userId});
  Future<bool> checkUsernameAvailability(String username);
  Future<void> updateOnlineStatus({required String userId, required bool isOnline});
}

class SupabaseProfileDataSourceImpl implements ProfileRemoteDataSource {
  final SupabaseClient _supabase;

  SupabaseProfileDataSourceImpl(this._supabase);

  @override
  Future<ProfileEntity?> getMyProfile() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;
    return getProfile(currentUserId);
  }

  @override
  Future<ProfileEntity?> getProfile(String userId) async {
    try {
      // Query secure view enforcing column-level presence privacy based on user_settings
      final data = await _supabase
          .from('user_profiles_secure')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        // Fallback to profiles table in case view was not queried
        final fallback = await _supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        if (fallback == null) return null;
        return ProfileEntity.fromMap(fallback);
      }

      return ProfileEntity.fromMap(data);
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<ProfileEntity> updateProfile({
    required String userId,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) {
      throw const AuthException(message: 'Unauthorized: cannot edit another user profile');
    }

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (displayName != null) updates['display_name'] = displayName.trim();
      if (username != null) updates['username'] = username.trim().toLowerCase();
      if (bio != null) updates['bio'] = bio.trim();
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      final updated = await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return ProfileEntity.fromMap(updated);
    } on PostgrestException catch (e) {
      if (e.code == '23505' || e.message.contains('unique') || e.message.contains('username')) {
        throw const AppException(
          message: 'That username is already taken. Please choose another.',
          code: 'USERNAME_TAKEN',
        );
      }
      throw SupabaseErrorHandler.handleError(e);
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<List<ProfileEntity>> searchUsers({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      // 1. Attempt RPC call for high-performance server-side ranking and block filtering
      try {
        final rpcResult = await _supabase.rpc('search_users', params: {
          'p_query': trimmed,
          'p_limit': limit,
          'p_offset': offset,
        });

        if (rpcResult is List) {
          return rpcResult
              .map((row) => ProfileEntity.fromMap(row as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        // Fallback to direct filtered query on user_profiles_secure
      }

      final data = await _supabase
          .from('user_profiles_secure')
          .select()
          .or('username.ilike.%$trimmed%,display_name.ilike.%$trimmed%')
          .range(offset, offset + limit - 1);

      return (data as List)
          .map((row) => ProfileEntity.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileExtension,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) {
      throw const AuthException(message: 'Unauthorized avatar upload');
    }

    if (imageBytes.length > 5 * 1024 * 1024) {
      throw const AppException(
        message: 'Avatar file size must be smaller than 5 MB.',
        code: 'FILE_TOO_LARGE',
      );
    }

    try {
      final ext = fileExtension.replaceAll('.', '').toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storagePath = '$userId/$fileName';

      // Clean up previous avatars in user directory to prevent orphaned files
      await deleteAvatar(userId: userId);

      await _supabase.storage.from('avatars').uploadBinary(
            storagePath,
            Uint8List.fromList(imageBytes),
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> deleteAvatar({required String userId}) async {
    try {
      final files = await _supabase.storage.from('avatars').list(path: userId);
      if (files.isNotEmpty) {
        final paths = files.map((f) => '$userId/${f.name}').toList();
        await _supabase.storage.from('avatars').remove(paths);
      }
    } catch (_) {
      // Ignore if directory does not exist yet
    }
  }

  @override
  Future<bool> checkUsernameAvailability(String username) async {
    final clean = username.trim().toLowerCase();
    if (clean.length < 3) return false;

    try {
      final res = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', clean)
          .maybeSingle();

      return res == null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> updateOnlineStatus({required String userId, required bool isOnline}) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) return;

    try {
      await _supabase.from('profiles').update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (_) {
      // Background presence update fail-safe
    }
  }
}
