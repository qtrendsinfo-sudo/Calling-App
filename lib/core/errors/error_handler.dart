import 'app_exception.dart';

/// Converts raw platform/network exceptions into human-friendly, localized copy.
class ErrorHandler {
  ErrorHandler._();

  static String getUserMessage(dynamic error) {
    if (error is NetworkException) {
      return error.message;
    }
    if (error is AuthException) {
      return error.message;
    }
    if (error is CallException) {
      return error.message;
    }
    if (error is DatabaseException) {
      return error.message;
    }
    if (error is PermissionException) {
      return 'Please grant ${error.permissionName} permission in device settings to proceed.';
    }
    if (error is AppException) {
      return error.message;
    }

    final errorString = error.toString().toLowerCase();
    if (errorString.contains('socket') || errorString.contains('network') || errorString.contains('connection')) {
      return 'Unable to reach Telora network. Please check your internet connection.';
    }
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
