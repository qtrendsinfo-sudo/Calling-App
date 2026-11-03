import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../errors/supabase_error_handler.dart';
import 'supabase_service.dart';

final supabaseStorageServiceProvider = Provider<SupabaseStorageService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseStorageService(supabase);
});

/// Centralized Supabase Storage Service for avatar and media assets.
class SupabaseStorageService {
  final SupabaseClient _supabase;

  // Maximum allowed upload sizes in bytes
  static const int maxAvatarSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const int maxMediaSizeBytes = 25 * 1024 * 1024; // 25 MB

  SupabaseStorageService(this._supabase);

  /// Uploads or updates an avatar image for a user in the 'avatars' bucket.
  /// Path: `<userId>/avatar.jpg`
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List fileBytes,
    String contentType = 'image/jpeg',
  }) async {
    if (fileBytes.length > maxAvatarSizeBytes) {
      throw const DatabaseException(
        message: 'Avatar image must be smaller than 5 MB.',
        code: 'FILE_TOO_LARGE',
      );
    }

    final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await _supabase.storage.from(AppConstants.avatarsBucket).uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      // Return public or signed URL according to bucket configuration
      final publicUrl = _supabase.storage.from(AppConstants.avatarsBucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  /// Uploads chat media (image, audio snippet) into the 'chat-media' bucket.
  Future<String> uploadChatMedia({
    required String conversationId,
    required String fileName,
    required Uint8List fileBytes,
    required String contentType,
  }) async {
    if (fileBytes.length > maxMediaSizeBytes) {
      throw const DatabaseException(
        message: 'Media file must be smaller than 25 MB.',
        code: 'FILE_TOO_LARGE',
      );
    }

    final path = '$conversationId/$fileName';
    try {
      await _supabase.storage.from(AppConstants.chatMediaBucket).uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );

      // Media in private buckets is accessed via short-lived signed URLs (1 hour)
      final signedUrl = await _supabase.storage
          .from(AppConstants.chatMediaBucket)
          .createSignedUrl(path, 60 * 60);
      return signedUrl;
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  /// Removes an avatar or media item from storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }
}
