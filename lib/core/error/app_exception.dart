// lib/core/error/app_exception.dart

import 'dart:io';

/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';

  /// Get user-friendly error message
  String get userMessage => message;

  /// Check if error is retryable
  bool get isRetryable => false;

  /// Get error category for analytics/logging
  String get category => 'unknown';
}

/// Network-related exceptions
class NetworkException extends AppException {
  final int? statusCode;
  final bool isTimeout;
  final bool isOffline;

  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    this.statusCode,
    this.isTimeout = false,
    this.isOffline = false,
  });

  @override
  String get userMessage {
    if (isOffline) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (isTimeout) {
      return 'Request timed out. Please try again.';
    }
    if (statusCode != null) {
      if (statusCode! >= 500) {
        return 'Server error. Please try again later.';
      }
      if (statusCode == 404) {
        return 'The requested resource was not found.';
      }
      if (statusCode == 403) {
        return 'You don\'t have permission to perform this action.';
      }
      if (statusCode == 401) {
        return 'Your session has expired. Please log in again.';
      }
    }
    return 'A network error occurred. Please try again.';
  }

  @override
  bool get isRetryable => isTimeout || isOffline || (statusCode != null && statusCode! >= 500);

  @override
  String get category => 'network';

  /// Create from various error types
  factory NetworkException.fromError(dynamic error, [StackTrace? stackTrace]) {
    if (error is SocketException) {
      return NetworkException(
        message: error.message,
        code: 'socket_error',
        originalError: error,
        stackTrace: stackTrace,
        isOffline: true,
      );
    }

    if (error is HttpException) {
      return NetworkException(
        message: error.message,
        code: 'http_error',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return NetworkException(
        message: error.toString(),
        code: 'timeout',
        originalError: error,
        stackTrace: stackTrace,
        isTimeout: true,
      );
    }

    if (errorString.contains('socketexception') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('connection refused') ||
        errorString.contains('no internet')) {
      return NetworkException(
        message: error.toString(),
        code: 'offline',
        originalError: error,
        stackTrace: stackTrace,
        isOffline: true,
      );
    }

    return NetworkException(
      message: error.toString(),
      code: 'unknown_network_error',
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}

/// Authentication-related exceptions
class AuthException extends AppException {
  final AuthErrorType type;

  const AuthException({
    required super.message,
    required this.type,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage {
    switch (type) {
      case AuthErrorType.invalidCredentials:
        return 'Invalid credentials. Please check and try again.';
      case AuthErrorType.sessionExpired:
        return 'Your session has expired. Please log in again.';
      case AuthErrorType.unauthorized:
        return 'You are not authorized to perform this action.';
      case AuthErrorType.invalidOtp:
        return 'Invalid verification code. Please try again.';
      case AuthErrorType.otpExpired:
        return 'Verification code has expired. Please request a new one.';
      case AuthErrorType.accountLocked:
        return 'Your account has been locked. Please contact support.';
      case AuthErrorType.accountSuspended:
        return 'Your account has been suspended.';
      case AuthErrorType.unknown:
        return 'Authentication error. Please try again.';
    }
  }

  @override
  bool get isRetryable =>
      type == AuthErrorType.invalidCredentials || type == AuthErrorType.invalidOtp;

  @override
  String get category => 'auth';

  factory AuthException.sessionExpired([dynamic originalError]) {
    return AuthException(
      message: 'Session expired',
      type: AuthErrorType.sessionExpired,
      code: 'session_expired',
      originalError: originalError,
    );
  }

  factory AuthException.invalidOtp([dynamic originalError]) {
    return AuthException(
      message: 'Invalid OTP',
      type: AuthErrorType.invalidOtp,
      code: 'invalid_otp',
      originalError: originalError,
    );
  }

  factory AuthException.unauthorized([dynamic originalError]) {
    return AuthException(
      message: 'Unauthorized',
      type: AuthErrorType.unauthorized,
      code: 'unauthorized',
      originalError: originalError,
    );
  }
}

enum AuthErrorType {
  invalidCredentials,
  sessionExpired,
  unauthorized,
  invalidOtp,
  otpExpired,
  accountLocked,
  accountSuspended,
  unknown,
}

/// Database/API exceptions
class DatabaseException extends AppException {
  final DatabaseErrorType type;

  const DatabaseException({
    required super.message,
    required this.type,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage {
    switch (type) {
      case DatabaseErrorType.notFound:
        return 'The requested item was not found.';
      case DatabaseErrorType.duplicate:
        return 'This item already exists.';
      case DatabaseErrorType.foreignKey:
        return 'This item cannot be modified due to related data.';
      case DatabaseErrorType.validation:
        return 'The provided data is invalid.';
      case DatabaseErrorType.permission:
        return 'You don\'t have permission to access this data.';
      case DatabaseErrorType.connection:
        return 'Unable to connect to the database. Please try again.';
      case DatabaseErrorType.unknown:
        return 'A database error occurred. Please try again.';
    }
  }

  @override
  bool get isRetryable => type == DatabaseErrorType.connection;

  @override
  String get category => 'database';

  factory DatabaseException.fromSupabaseError(dynamic error, [StackTrace? stackTrace]) {
    final errorString = error.toString().toLowerCase();
    final code = _extractSupabaseCode(error);

    if (errorString.contains('23503') || errorString.contains('foreign key')) {
      return DatabaseException(
        message: error.toString(),
        type: DatabaseErrorType.foreignKey,
        code: code ?? 'foreign_key',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (errorString.contains('23505') || errorString.contains('duplicate')) {
      return DatabaseException(
        message: error.toString(),
        type: DatabaseErrorType.duplicate,
        code: code ?? 'duplicate',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (errorString.contains('pgrst116') || errorString.contains('not found') || errorString.contains('no rows')) {
      return DatabaseException(
        message: error.toString(),
        type: DatabaseErrorType.notFound,
        code: code ?? 'not_found',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (errorString.contains('42501') || errorString.contains('permission denied') || errorString.contains('rls')) {
      return DatabaseException(
        message: error.toString(),
        type: DatabaseErrorType.permission,
        code: code ?? 'permission',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return DatabaseException(
      message: error.toString(),
      type: DatabaseErrorType.unknown,
      code: code ?? 'unknown',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static String? _extractSupabaseCode(dynamic error) {
    try {
      if (error is Map && error['code'] != null) {
        return error['code'].toString();
      }
      final match = RegExp(r'code["\s:]+(\w+)').firstMatch(error.toString());
      return match?.group(1);
    } catch (_) {
      return null;
    }
  }
}

enum DatabaseErrorType {
  notFound,
  duplicate,
  foreignKey,
  validation,
  permission,
  connection,
  unknown,
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, List<String>> fieldErrors;

  const ValidationException({
    required super.message,
    this.fieldErrors = const {},
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage {
    if (fieldErrors.isNotEmpty) {
      final firstError = fieldErrors.values.first.first;
      return firstError;
    }
    return message;
  }

  @override
  String get category => 'validation';

  /// Check if a specific field has errors
  bool hasFieldError(String field) => fieldErrors.containsKey(field);

  /// Get errors for a specific field
  List<String> getFieldErrors(String field) => fieldErrors[field] ?? [];
}

/// Generic application exception for unexpected errors
class UnexpectedException extends AppException {
  const UnexpectedException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'An unexpected error occurred. Please try again.';

  @override
  bool get isRetryable => true;

  @override
  String get category => 'unexpected';

  factory UnexpectedException.fromError(dynamic error, [StackTrace? stackTrace]) {
    return UnexpectedException(
      message: error.toString(),
      code: 'unexpected',
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}

/// Rate limiting exception
class RateLimitException extends AppException {
  final Duration? retryAfter;

  const RateLimitException({
    required super.message,
    this.retryAfter,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage {
    if (retryAfter != null) {
      return 'Too many requests. Please wait ${retryAfter!.inSeconds} seconds.';
    }
    return 'Too many requests. Please wait a moment and try again.';
  }

  @override
  bool get isRetryable => true;

  @override
  String get category => 'rate_limit';
}
