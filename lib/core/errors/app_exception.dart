/// Sealed hierarchy of domain and infrastructure exceptions in Telora.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

/// Thrown when there is no active internet connection or socket failure occurs
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No active internet connection. Please verify network access.',
    super.code = 'NETWORK_UNAVAILABLE',
    super.originalError,
  });
}

/// Thrown for authentication lifecycle errors (invalid credentials, expired token, etc.)
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.originalError,
  });
}

/// Thrown during WebRTC peer connection, SDP negotiation or media track acquisition failures
class CallException extends AppException {
  const CallException({
    required super.message,
    super.code = 'CALL_ERROR',
    super.originalError,
  });
}

/// Thrown for PostgreSQL/Supabase database and RLS policy violations
class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code = 'DATABASE_ERROR',
    super.originalError,
  });
}

/// Thrown when camera, microphone, or notification hardware permission is denied
class PermissionException extends AppException {
  final String permissionName;

  const PermissionException({
    required this.permissionName,
    super.message = 'Required device permission was denied.',
    super.code = 'PERMISSION_DENIED',
    super.originalError,
  });
}

/// Thrown when a requested resource is not found
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code = 'NOT_FOUND',
    super.originalError,
  });
}
