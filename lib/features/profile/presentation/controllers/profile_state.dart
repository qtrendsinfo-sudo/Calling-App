import '../../../../domain/entities/profile_entity.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  updating,
  error,
}

class ProfileState {
  final ProfileStatus status;
  final ProfileEntity? profile;
  final String? errorMessage;
  final String? successMessage;
  final bool isUsernameAvailable;
  final bool isCheckingUsername;

  const ProfileState({
    required this.status,
    this.profile,
    this.errorMessage,
    this.successMessage,
    this.isUsernameAvailable = true,
    this.isCheckingUsername = false,
  });

  factory ProfileState.initial() => const ProfileState(status: ProfileStatus.initial);

  factory ProfileState.loading() => const ProfileState(status: ProfileStatus.loading);

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileEntity? profile,
    String? errorMessage,
    String? successMessage,
    bool? isUsernameAvailable,
    bool? isCheckingUsername,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isUsernameAvailable: isUsernameAvailable ?? this.isUsernameAvailable,
      isCheckingUsername: isCheckingUsername ?? this.isCheckingUsername,
    );
  }

  bool get isLoading => status == ProfileStatus.loading || status == ProfileStatus.updating;
}
