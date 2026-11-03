import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'profile_state.dart';

final profileControllerProvider = StateNotifierProvider<ProfileController, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return ProfileController(repository, userId);
});

class ProfileController extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final String? _currentUserId;
  Timer? _debounceTimer;

  ProfileController(this._repository, this._currentUserId) : super(ProfileState.initial()) {
    if (_currentUserId != null) {
      loadMyProfile();
    }
  }

  Future<void> loadMyProfile() async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final profile = await _repository.getMyProfile();
      state = state.copyWith(
        status: ProfileStatus.loaded,
        profile: profile,
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    if (_currentUserId == null) return false;

    state = state.copyWith(status: ProfileStatus.updating, errorMessage: null, successMessage: null);
    try {
      final updated = await _repository.updateProfile(
        userId: _currentUserId!,
        displayName: displayName,
        username: username,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      state = state.copyWith(
        status: ProfileStatus.loaded,
        profile: updated,
        successMessage: 'Profile updated successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
      return false;
    }
  }

  Future<String?> uploadAvatar({
    required List<int> imageBytes,
    required String fileExtension,
  }) async {
    if (_currentUserId == null) return null;

    state = state.copyWith(status: ProfileStatus.updating, errorMessage: null);
    try {
      final avatarUrl = await _repository.uploadAvatar(
        userId: _currentUserId!,
        imageBytes: imageBytes,
        fileExtension: fileExtension,
      );

      final updated = await _repository.updateProfile(
        userId: _currentUserId!,
        avatarUrl: avatarUrl,
      );

      state = state.copyWith(
        status: ProfileStatus.loaded,
        profile: updated,
        successMessage: 'Avatar uploaded successfully.',
      );
      return avatarUrl;
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
      return null;
    }
  }

  void checkUsernameAvailability(String username) {
    _debounceTimer?.cancel();
    final clean = username.trim().toLowerCase();

    // If matches current username, treat as available immediately
    if (clean == state.profile?.username.toLowerCase()) {
      state = state.copyWith(isUsernameAvailable: true, isCheckingUsername: false);
      return;
    }

    if (clean.length < 3) {
      state = state.copyWith(isUsernameAvailable: false, isCheckingUsername: false);
      return;
    }

    state = state.copyWith(isCheckingUsername: true);
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final isAvailable = await _repository.checkUsernameAvailability(clean);
        state = state.copyWith(
          isUsernameAvailable: isAvailable,
          isCheckingUsername: false,
        );
      } catch (_) {
        state = state.copyWith(isCheckingUsername: false);
      }
    });
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
