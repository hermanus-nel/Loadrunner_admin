// lib/core/services/jwt_recovery_handler.dart
// Adapted from main LoadRunner app's JwtRecoveryHandler
// Automatic retry mechanism for JWT-related errors

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'session_service.dart';
import 'supabase_provider.dart';

/// Automatic retry mechanism for JWT-related errors
/// 
/// Features:
/// - Error detection: Identifies JWT/auth errors (401, 403, "jwt", "expired")
/// - Automatic retry: Refreshes token and retries failed operations (max 3 attempts)
/// - Stream support: Handles realtime subscription failures
/// - Singleton pattern: Single instance shared across app
/// - Exponential backoff: Delay between retries
class JwtRecoveryHandler {
  // Singleton instance
  static final JwtRecoveryHandler _instance = JwtRecoveryHandler._internal();

  factory JwtRecoveryHandler() => _instance;

  JwtRecoveryHandler._internal();

  // Service references
  SessionService? _sessionService;
  SupabaseProvider? _supabaseProvider;

  // Recovery state
  bool _isRecovering = false;
  int _consecutiveRecoveryAttempts = 0;

  // Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(milliseconds: 500);
  static const Duration backoffMultiplier = Duration(milliseconds: 500);

  // Debug mode flag
  static bool debugMode = true;

  // Debug logging helper
  void _debugLog(String message) {
    if (debugMode) {
      debugPrint('🔄 JwtRecoveryHandler: $message');
    }
  }

  /// Initialize with required services (matches main app pattern)
  void initialize({
    required SessionService sessionService,
    required SupabaseProvider supabaseProvider,
  }) {
    _sessionService = sessionService;
    _supabaseProvider = supabaseProvider;
    _debugLog('Initialized with SessionService and SupabaseProvider');
  }

  /// Check if handler is initialized
  bool get isInitialized => _sessionService != null && _supabaseProvider != null;

  /// Check if an error is a JWT-related error
  bool isJwtError(dynamic error) {
    if (error == null) return false;

    final errorString = error.toString().toLowerCase();

    // Common JWT error patterns
    final jwtErrorPatterns = [
      'jwt',
      'token',
      'expired',
      'invalid_token',
      'invalid token',
      'unauthorized',
      'auth',
      '401',
      '403',
      'forbidden',
      'not authenticated',
      'session',
      'pgrst301',
      'pgrst302',
    ];

    for (final pattern in jwtErrorPatterns) {
      if (errorString.contains(pattern)) {
        _debugLog('Detected JWT error pattern: $pattern');
        return true;
      }
    }

    return false;
  }

  /// Execute an operation with automatic JWT recovery.
  ///
  /// Accepts a positional [operation] closure and an optional [operationName]
  /// for debug logging.
  Future<T> executeWithRecovery<T>(
    Future<T> Function() operation, [
    String operationName = 'operation',
  ]) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        _debugLog('Executing: $operationName (attempt ${retryCount + 1})');
        final result = await operation();
        _debugLog('Success: $operationName');
        _resetRecoveryState();
        return result;
      } catch (e) {
        if (isJwtError(e)) {
          _debugLog('JWT error detected in: $operationName');

          if (retryCount < maxRetries - 1) {
            _debugLog('Attempting token refresh and retry...');

            final recovered = await _recoverFromJwtError();
            if (recovered) {
              await Future.delayed(retryDelay);
              retryCount++;
              _debugLog('Retrying: $operationName');
              continue;
            } else {
              _debugLog('Recovery failed for: $operationName');
              rethrow;
            }
          } else {
            _debugLog('Max retries exceeded for: $operationName');
            rethrow;
          }
        } else {
          _debugLog('Non-JWT error in: $operationName - $e');
          rethrow;
        }
      }
    }

    throw Exception('Max retries exceeded for: $operationName');
  }

  /// Attempt to recover from a JWT error by refreshing the token
  Future<bool> _recoverFromJwtError() async {
    if (_isRecovering) {
      _debugLog('Already recovering, waiting...');
      await Future.delayed(const Duration(milliseconds: 500));
      return _sessionService?.isAuthenticated ?? false;
    }

    if (_sessionService == null) {
      _debugLog('Session service not initialized');
      return false;
    }

    if (_consecutiveRecoveryAttempts >= maxRetries) {
      _debugLog('Max recovery attempts reached');
      _resetRecoveryState();
      return false;
    }

    _isRecovering = true;
    _consecutiveRecoveryAttempts++;

    try {
      _debugLog('🔑 Refreshing session token (attempt $_consecutiveRecoveryAttempts/$maxRetries)...');
      
      // Calculate backoff delay
      final delay = Duration(
        milliseconds: retryDelay.inMilliseconds +
            (backoffMultiplier.inMilliseconds * (_consecutiveRecoveryAttempts - 1)),
      );
      await Future.delayed(delay);

      final refreshSuccess = await _sessionService!.refreshSessionIfNeeded(forceRefresh: true);

      if (refreshSuccess && _sessionService!.isAuthenticated) {
        _debugLog('✅ Token refreshed successfully');
        
        // Ensure headers are updated
        if (_supabaseProvider != null) {
          await _supabaseProvider!.ensureAuthenticationHeaders();
        }
        
        _resetRecoveryState();
        _isRecovering = false;
        return true;
      } else {
        _debugLog('❌ Token refresh failed');
        _isRecovering = false;
        return false;
      }
    } catch (e) {
      _debugLog('❌ Error during recovery: $e');
      _isRecovering = false;
      return false;
    }
  }

  /// Execute a stream operation with automatic JWT recovery
  Stream<T> streamWithRecovery<T>({
    required Stream<T> Function() streamOperation,
    required String operationName,
  }) async* {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        _debugLog('🎬 Starting stream: $operationName (attempt ${retryCount + 1})');

        await for (final event in streamOperation()) {
          _resetRecoveryState(); // Reset on successful event
          yield event;
        }

        // Stream completed normally
        return;
      } catch (e) {
        if (isJwtError(e)) {
          _debugLog('🔴 JWT error in stream: $operationName');

          if (retryCount < maxRetries - 1) {
            _debugLog('🔑 Attempting stream recovery...');

            final recovered = await _recoverFromJwtError();
            if (recovered) {
              await Future.delayed(retryDelay);
              retryCount++;
              _debugLog('🔄 Retrying stream: $operationName');
              continue;
            } else {
              _debugLog('❌ Stream recovery failed');
              rethrow;
            }
          } else {
            _debugLog('❌ Max stream retries exceeded');
            rethrow;
          }
        } else {
          _debugLog('❌ Non-JWT error in stream: $e');
          rethrow;
        }
      }
    }
  }

  /// Legacy method for backward compatibility
  Future<T> withRecovery<T>(Future<T> Function() operation) async {
    return executeWithRecovery(operation, 'operation');
  }

  /// Reset the recovery state
  void _resetRecoveryState() {
    _consecutiveRecoveryAttempts = 0;
  }

  /// Manually reset the handler
  void reset() {
    _resetRecoveryState();
    _isRecovering = false;
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'isRecovering': _isRecovering,
      'consecutiveAttempts': _consecutiveRecoveryAttempts,
      'maxRetries': maxRetries,
      'isInitialized': isInitialized,
      'hasSessionService': _sessionService != null,
      'hasSupabaseProvider': _supabaseProvider != null,
      'sessionServiceReady': _sessionService?.isAuthenticated ?? false,
      'supabaseProviderReady': _supabaseProvider?.isAuthenticated ?? false,
    };
  }
}

/// Global instance for convenience
final jwtRecoveryHandler = JwtRecoveryHandler();
