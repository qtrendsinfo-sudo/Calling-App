enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  verificationRequired,
  sessionExpired,
  loading,
  error,
}

class AppAuthState {
  final AuthStatus status;
  final String? userId;
  final String? email;
  final String? errorMessage;
  final String? successMessage;

  const AppAuthState({
    required this.status,
    this.userId,
    this.email,
    this.errorMessage,
    this.successMessage,
  });

  factory AppAuthState.initial() => const AppAuthState(status: AuthStatus.initial);

  factory AppAuthState.loading() => const AppAuthState(status: AuthStatus.loading);

  factory AppAuthState.authenticated({
    required String userId,
    required String email,
  }) =>
      AppAuthState(
        status: AuthStatus.authenticated,
        userId: userId,
        email: email,
      );

  factory AppAuthState.unauthenticated() => const AppAuthState(status: AuthStatus.unauthenticated);

  factory AppAuthState.verificationRequired({required String email}) => AppAuthState(
        status: AuthStatus.verificationRequired,
        email: email,
      );

  factory AppAuthState.sessionExpired() => const AppAuthState(status: AuthStatus.sessionExpired);

  factory AppAuthState.error(String message) => AppAuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isVerificationRequired => status == AuthStatus.verificationRequired;
}
