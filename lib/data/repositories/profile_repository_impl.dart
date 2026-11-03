import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/remote/supabase_profile_datasource.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dataSource = ref.watch(profileRemoteDataSourceProvider);
  return ProfileRepositoryImpl(dataSource);
});

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _dataSource;

  ProfileRepositoryImpl(this._dataSource);

  @override
  Future<ProfileEntity?> getMyProfile() {
    return _dataSource.getMyProfile();
  }

  @override
  Future<ProfileEntity?> getProfile(String userId) {
    return _dataSource.getProfile(userId);
  }

  @override
  Future<ProfileEntity> updateProfile({
    required String userId,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) {
    return _dataSource.updateProfile(
      userId: userId,
      displayName: displayName,
      username: username,
      bio: bio,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<List<ProfileEntity>> searchUsers({
    required String query,
    int limit = 20,
    int offset = 0,
  }) {
    return _dataSource.searchUsers(
      query: query,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileExtension,
  }) {
    return _dataSource.uploadAvatar(
      userId: userId,
      imageBytes: imageBytes,
      fileExtension: fileExtension,
    );
  }

  @override
  Future<void> deleteAvatar({required String userId}) {
    return _dataSource.deleteAvatar(userId: userId);
  }

  @override
  Future<bool> checkUsernameAvailability(String username) {
    return _dataSource.checkUsernameAvailability(username);
  }

  @override
  Future<void> updateOnlineStatus({required String userId, required bool isOnline}) {
    return _dataSource.updateOnlineStatus(userId: userId, isOnline: isOnline);
  }
}
