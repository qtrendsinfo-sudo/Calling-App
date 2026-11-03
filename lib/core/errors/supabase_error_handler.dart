import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_exception.dart';

/// Centralized translator for Supabase platform errors into typed domain exceptions.
class SupabaseErrorHandler {
  SupabaseErrorHandler._();

  static AppException handleError(dynamic error) {
    if (error is AuthException) {
      return _mapAuthException(error);
    }

    if (error is PostgrestException) {
      return _mapPostgrestException(error);
    }

    if (error is StorageException) {
      return DatabaseException(
        message: _friendlyStorageMessage(error.message),
        code: error.statusCode,
        originalError: error,
      );
    }

    if (error is SocketException) {
      return const NetworkException(
        message: 'Unable to reach Telora servers. Please check your internet connection.',
      );
    }

    if (error is AppException) {
      return error;
    }

    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('socket') || errorStr.contains('network') || errorStr.contains('failed host lookup')) {
      return const NetworkException(
        message: 'Network unreachable. Please check your connection and try again.',
      );
    }

    return DatabaseException(
      message: 'A server error occurred. Please try again.',
      originalError: error,
    );
  }

  static AuthException _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid_grant')) {
      return const AuthException(
        message: 'Invalid email or password. Please verify your credentials.',
        code: 'INVALID_CREDENTIALS',
      );
    }
    if (msg.contains('user already registered') || msg.contains('user_already_exists')) {
      return const AuthException(
        message: 'An account with this email already exists. Try signing in instead.',
        code: 'EMAIL_EXISTS',
      );
    }
    if (msg.contains('email not confirmed')) {
      return const AuthException(
        message: 'Please verify your email address before signing in.',
        code: 'EMAIL_NOT_CONFIRMED',
      );
    }
    if (msg.contains('password should be at least')) {
      return const AuthException(
        message: 'Password must be at least 8 characters long.',
        code: 'WEAK_PASSWORD',
      );
    }
    if (msg.contains('token has expired') || msg.contains('jwt expired')) {
      return const AuthException(
        message: 'Your session has expired. Please sign in again.',
        code: 'SESSION_EXPIRED',
      );
    }

    return AuthException(
      message: e.message,
      code: e.statusCode,
      originalError: e,
    );
  }

  static DatabaseException _mapPostgrestException(PostgrestException e) {
    if (e.code == '23505') {
      // Unique violation
      if (e.message.contains('username')) {
        return const DatabaseException(
          message: 'This username is already taken. Please choose another one.',
          code: 'USERNAME_TAKEN',
        );
      }
      return const DatabaseException(
        message: 'This record already exists.',
        code: 'DUPLICATE_ENTRY',
      );
    }

    if (e.code == '42501') {
      // RLS policy violation
      return const DatabaseException(
        message: 'Access denied: You do not have permission to perform this action.',
        code: 'RLS_PERMISSION_DENIED',
      );
    }

    return DatabaseException(
      message: e.message.isNotEmpty ? e.message : 'Database operation failed.',
      code: e.code,
      originalError: e,
    );
  }

  static String _friendlyStorageMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('entity too large') || lower.contains('payload too large')) {
      return 'The selected file is too large. Please select a smaller file.';
    }
    if (lower.contains('unauthorized') || lower.contains('access denied')) {
      return 'You do not have permission to upload to this location.';
    }
    return raw.isNotEmpty ? raw : 'Storage operation failed.';
  }
}
