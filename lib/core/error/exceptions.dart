/// Base class for all application exceptions
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
  String toString() => 'AppException: $message (code: $code)';
}

/// Exception for network-related errors
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'A network error occurred',
    super.code,
    super.originalError,
  });
}

/// Exception for authentication errors
class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication failed',
    super.code,
    super.originalError,
  });
}

/// Exception for validation errors
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    super.message = 'Validation failed',
    super.code,
    super.originalError,
    this.fieldErrors,
  });
}

/// Exception for server errors
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    super.message = 'Server error occurred',
    super.code,
    super.originalError,
    this.statusCode,
  });
}

/// Exception for not found errors
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.code,
    super.originalError,
  });
}

/// Exception for permission errors
class PermissionException extends AppException {
  const PermissionException({
    super.message = 'Permission denied',
    super.code,
    super.originalError,
  });
}

/// Exception for timeout errors
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.code,
    super.originalError,
  });
}

/// Exception for cache-related errors
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error occurred',
    super.code,
    super.originalError,
  });
}
