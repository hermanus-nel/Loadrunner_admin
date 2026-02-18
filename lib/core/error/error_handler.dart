// lib/core/error/error_handler.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_exception.dart';

/// Global error handler service
class ErrorHandler {
  static ErrorHandler? _instance;
  static ErrorHandler get instance => _instance ??= ErrorHandler._();

  ErrorHandler._();

  /// Stream controller for error events
  final _errorStreamController = StreamController<ErrorEvent>.broadcast();
  
  /// Stream of error events for listening throughout the app
  Stream<ErrorEvent> get errorStream => _errorStreamController.stream;

  /// List of recent errors for debugging
  final List<ErrorEvent> _recentErrors = [];
  
  /// Maximum number of recent errors to keep
  static const int _maxRecentErrors = 50;

  /// Error listeners for custom handling
  final List<ErrorListener> _listeners = [];

  /// Initialize the error handler with Flutter error handling
  void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Catch errors that escape to the platform
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true; // Prevent app crash
    };

    debugPrint('🛡️ ErrorHandler initialized');
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    final event = ErrorEvent(
      error: details.exception,
      stackTrace: details.stack,
      context: details.context?.toDescription(),
      source: ErrorSource.flutter,
      timestamp: DateTime.now(),
    );

    _processError(event);

    // In debug mode, also log to console
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  }

  /// Handle platform-level errors
  void _handlePlatformError(Object error, StackTrace stack) {
    final event = ErrorEvent(
      error: error,
      stackTrace: stack,
      source: ErrorSource.platform,
      timestamp: DateTime.now(),
    );

    _processError(event);
  }

  /// Handle errors from app code (call this manually)
  AppException handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    bool silent = false,
  }) {
    final appException = _convertToAppException(error, stackTrace);

    final event = ErrorEvent(
      error: error,
      stackTrace: stackTrace ?? StackTrace.current,
      context: context,
      source: ErrorSource.app,
      timestamp: DateTime.now(),
      appException: appException,
    );

    _processError(event, silent: silent);

    return appException;
  }

  /// Process an error event
  void _processError(ErrorEvent event, {bool silent = false}) {
    // Add to recent errors
    _recentErrors.add(event);
    if (_recentErrors.length > _maxRecentErrors) {
      _recentErrors.removeAt(0);
    }

    // Log the error
    _logError(event);

    // Notify listeners
    for (final listener in _listeners) {
      try {
        listener(event);
      } catch (e) {
        debugPrint('❌ Error in error listener: $e');
      }
    }

    // Emit to stream (for UI updates)
    if (!silent) {
      _errorStreamController.add(event);
    }
  }

  /// Log error to console and potentially to remote service
  void _logError(ErrorEvent event) {
    final buffer = StringBuffer();
    buffer.writeln('══════════════════════════════════════════════════');
    buffer.writeln('🔴 ERROR [${event.source.name.toUpperCase()}]');
    buffer.writeln('Time: ${event.timestamp.toIso8601String()}');
    
    if (event.context != null) {
      buffer.writeln('Context: ${event.context}');
    }
    
    if (event.appException != null) {
      buffer.writeln('Type: ${event.appException.runtimeType}');
      buffer.writeln('Code: ${event.appException!.code}');
      buffer.writeln('Category: ${event.appException!.category}');
      buffer.writeln('Retryable: ${event.appException!.isRetryable}');
      buffer.writeln('User Message: ${event.appException!.userMessage}');
    }
    
    buffer.writeln('Error: ${event.error}');
    
    if (event.stackTrace != null) {
      buffer.writeln('Stack Trace:');
      buffer.writeln(event.stackTrace.toString().split('\n').take(10).join('\n'));
    }
    
    buffer.writeln('══════════════════════════════════════════════════');

    debugPrint(buffer.toString());

    // TODO: Send to remote logging service in production
    // if (!kDebugMode) {
    //   _sendToRemoteLogging(event);
    // }
  }

  /// Convert any error to an AppException
  AppException _convertToAppException(dynamic error, StackTrace? stackTrace) {
    // Already an AppException
    if (error is AppException) {
      return error;
    }

    // Network errors
    if (error is SocketException ||
        error is HttpException ||
        _isNetworkError(error)) {
      return NetworkException.fromError(error, stackTrace);
    }

    // Auth errors (from JWT handler or Supabase)
    if (_isAuthError(error)) {
      return AuthException(
        message: error.toString(),
        type: _getAuthErrorType(error),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Database errors (Supabase/PostgreSQL)
    if (_isDatabaseError(error)) {
      return DatabaseException.fromSupabaseError(error, stackTrace);
    }

    // Timeout errors
    if (error is TimeoutException) {
      return NetworkException(
        message: error.message ?? 'Request timed out',
        code: 'timeout',
        originalError: error,
        stackTrace: stackTrace,
        isTimeout: true,
      );
    }

    // Default to unexpected exception
    return UnexpectedException.fromError(error, stackTrace);
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection reset') ||
        errorString.contains('connection closed') ||
        errorString.contains('no internet') ||
        errorString.contains('timeout') ||
        errorString.contains('timed out');
  }

  bool _isAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('jwt') ||
        errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('unauthorized') ||
        errorString.contains('unauthenticated') ||
        errorString.contains('session') ||
        errorString.contains('token') ||
        errorString.contains('pgrst301');
  }

  AuthErrorType _getAuthErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('expired')) {
      return AuthErrorType.sessionExpired;
    }
    if (errorString.contains('invalid') && errorString.contains('otp')) {
      return AuthErrorType.invalidOtp;
    }
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return AuthErrorType.unauthorized;
    }
    if (errorString.contains('locked')) {
      return AuthErrorType.accountLocked;
    }
    if (errorString.contains('suspended')) {
      return AuthErrorType.accountSuspended;
    }

    return AuthErrorType.unknown;
  }

  bool _isDatabaseError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('postgres') ||
        errorString.contains('pgrst') ||
        errorString.contains('supabase') ||
        errorString.contains('23505') || // duplicate
        errorString.contains('23503') || // foreign key
        errorString.contains('42501') || // permission
        errorString.contains('rls');
  }

  /// Add an error listener
  void addListener(ErrorListener listener) {
    _listeners.add(listener);
  }

  /// Remove an error listener
  void removeListener(ErrorListener listener) {
    _listeners.remove(listener);
  }

  /// Get recent errors for debugging
  List<ErrorEvent> getRecentErrors() => List.unmodifiable(_recentErrors);

  /// Clear recent errors
  void clearRecentErrors() => _recentErrors.clear();

  /// Get error count by category
  Map<String, int> getErrorCountsByCategory() {
    final counts = <String, int>{};
    for (final event in _recentErrors) {
      final category = event.appException?.category ?? 'unknown';
      counts[category] = (counts[category] ?? 0) + 1;
    }
    return counts;
  }

  /// Dispose resources
  void dispose() {
    _errorStreamController.close();
    _listeners.clear();
    _recentErrors.clear();
  }
}

/// Error event containing all error information
class ErrorEvent {
  final dynamic error;
  final StackTrace? stackTrace;
  final String? context;
  final ErrorSource source;
  final DateTime timestamp;
  final AppException? appException;

  const ErrorEvent({
    required this.error,
    this.stackTrace,
    this.context,
    required this.source,
    required this.timestamp,
    this.appException,
  });

  /// Get user-friendly message
  String get userMessage {
    if (appException != null) {
      return appException!.userMessage;
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Check if error is retryable
  bool get isRetryable => appException?.isRetryable ?? false;
}

/// Source of the error
enum ErrorSource {
  flutter, // Flutter framework errors
  platform, // Platform-level errors
  app, // Application code errors
}

/// Type definition for error listeners
typedef ErrorListener = void Function(ErrorEvent event);

// ============================================================================
// Riverpod Providers
// ============================================================================

/// Provider for the ErrorHandler instance
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler.instance;
});

/// Stream provider for error events
final errorStreamProvider = StreamProvider<ErrorEvent>((ref) {
  return ErrorHandler.instance.errorStream;
});

/// Provider for recent errors
final recentErrorsProvider = Provider<List<ErrorEvent>>((ref) {
  // Watch the error stream to trigger rebuilds
  ref.watch(errorStreamProvider);
  return ErrorHandler.instance.getRecentErrors();
});

// ============================================================================
// Extension Methods
// ============================================================================

/// Extension to easily handle errors with context
extension ErrorHandlerExtension on Object {
  AppException handleAsError({String? context, bool silent = false}) {
    return ErrorHandler.instance.handleError(
      this,
      stackTrace: StackTrace.current,
      context: context,
      silent: silent,
    );
  }
}

/// Extension for Future error handling
extension FutureErrorHandler<T> on Future<T> {
  /// Execute future with error handling
  Future<T> handleErrors({String? context, bool silent = false}) {
    return catchError((Object error, StackTrace stackTrace) {
      ErrorHandler.instance.handleError(
        error,
        stackTrace: stackTrace,
        context: context,
        silent: silent,
      );
      throw error;
    });
  }

  /// Execute future and return Result type
  Future<Result<T>> toResult({String? context}) async {
    try {
      final value = await this;
      return Result.success(value);
    } catch (error, stackTrace) {
      final exception = ErrorHandler.instance.handleError(
        error,
        stackTrace: stackTrace,
        context: context,
        silent: true,
      );
      return Result.failure(exception);
    }
  }
}

/// Result type for error handling
sealed class Result<T> {
  const Result._();

  factory Result.success(T value) = Success<T>;
  factory Result.failure(AppException error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => isSuccess ? (this as Success<T>).value : null;
  AppException? get errorOrNull => isFailure ? (this as Failure<T>).error : null;

  R when<R>({
    required R Function(T value) success,
    required R Function(AppException error) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).value);
    } else {
      return failure((this as Failure<T>).error);
    }
  }
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value) : super._();
}

class Failure<T> extends Result<T> {
  final AppException error;
  const Failure(this.error) : super._();
}
