import '../entities/profile_entity.dart';

abstract class ProfileRepository {
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
