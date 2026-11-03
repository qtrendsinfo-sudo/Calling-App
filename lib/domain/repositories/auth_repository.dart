import '../entities/profile_entity.dart';

abstract class AuthRepository {
  Stream<String?> get authStateChanges;
  String? get currentUserId;
  Future<ProfileEntity> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  });
  Future<ProfileEntity> signInWithEmail({
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updateUserPassword(String newPassword);
  Future<void> signOut();
  Future<void> deleteAccount();
}
