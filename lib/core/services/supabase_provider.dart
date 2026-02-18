// lib/core/services/supabase_provider.dart
// Adapted from main LoadRunner app's SupabaseProvider
// Uses SessionService as the primary authentication source

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'session_service.dart';

/// A provider class that manages the Supabase client instance
/// Uses SessionService as the primary authentication source
class SupabaseProvider {
  // Singleton instance
  static final SupabaseProvider _instance = SupabaseProvider._internal();

  // Factory constructor to return the singleton instance
  factory SupabaseProvider() => _instance;

  // Private constructor for singleton
  SupabaseProvider._internal();

  // Cached client reference
  SupabaseClient? _client;
  bool _isInitialized = false;

  // Session service reference - primary auth source
  SessionService? _sessionService;

  // Debug mode flag
  static bool debugMode = true;

  // Debug logging helper
  void _debugLog(String message) {
    if (debugMode) {
      debugPrint('🔧 SupabaseProvider Debug: $message');
    }
  }

  /// Set the session service (should be called early in app initialization)
  void setSessionService(SessionService sessionService) {
    _sessionService = sessionService;
    _debugLog('Session service set successfully');

    // Listen to auth state changes from SessionService
    _sessionService!.authStateChanges.listen((isAuthenticated) {
      _debugLog('Auth state changed - authenticated: $isAuthenticated');
      if (isAuthenticated) {
        _updateSupabaseHeaders();
      } else {
        _clearSupabaseHeaders();
      }
    });
  }

  /// Check if the provider is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the Supabase client - called once during app startup
  void initialize() {
    if (_isInitialized) {
      _debugLog('Already initialized');
      return;
    }

    try {
      _client = Supabase.instance.client;
      _isInitialized = true;
      _debugLog('Initialized successfully');

      // Update headers if we already have a session service
      if (_sessionService?.isAuthenticated == true) {
        _updateSupabaseHeaders();
      }
    } catch (e) {
      _debugLog('Error initializing: $e');
      rethrow;
    }
  }

  /// Get the Supabase client instance
  SupabaseClient get client {
    if (!_isInitialized || _client == null) {
      try {
        initialize();
      } catch (e) {
        throw Exception('SupabaseProvider not initialized. Call initialize() first: $e');
      }
    }

    if (_client == null) {
      throw Exception('SupabaseProvider client is null after initialization');
    }

    return _client!;
  }

  /// Get the current authenticated user ID
  /// Uses multi-fallback approach: SessionService → Supabase auth → JWT
  String getCurrentUserId() {
    // Primary: SessionService (most reliable)
    if (_sessionService != null && _sessionService!.userId != null) {
      return _sessionService!.userId!;
    }

    // Fallback 1: Supabase auth currentUser
    try {
      final user = client.auth.currentUser;
      if (user != null) {
        return user.id;
      }
    } catch (e) {
      _debugLog('Error getting Supabase auth user: $e');
    }

    // Fallback 2: Extract from JWT in headers
    try {
      final authHeader = client.headers['Authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7);
        final userId = _extractUserIdFromJwt(token);
        if (userId != null) {
          return userId;
        }
      }
    } catch (e) {
      _debugLog('Error extracting user ID from JWT: $e');
    }

    throw Exception('No authenticated user found');
  }

  /// Helper for checking authentication state using SessionService
  bool get isAuthenticated {
    if (_sessionService == null) {
      // Fallback to Supabase auth if no session service
      try {
        return client.auth.currentUser != null;
      } catch (e) {
        return false;
      }
    }

    return _sessionService!.isAuthenticated;
  }

  /// Get current user (for Supabase auth compatibility)
  User? get currentUser => client.auth.currentUser;

  /// Access to database tables
  SupabaseQueryBuilder from(String table) => client.from(table);

  /// Access to storage buckets
  SupabaseStorageClient get storage => client.storage;

  /// Access to auth methods
  GoTrueClient get auth => client.auth;

  /// Access to functions
  FunctionsClient get functions => client.functions;

  /// Access to realtime
  RealtimeClient get realtime => client.realtime;

  /// Update Supabase headers when authentication state changes
  Future<void> _updateSupabaseHeaders() async {
    if (_sessionService == null || !_isInitialized || _client == null) {
      return;
    }

    try {
      final accessToken = await _sessionService!.getAccessToken();
      if (accessToken != null) {
        _client!.headers['Authorization'] = 'Bearer $accessToken';
        _debugLog('Updated Authorization header');
      }
    } catch (e) {
      _debugLog('Error updating headers: $e');
    }
  }

  /// Clear Supabase headers when user signs out
  void _clearSupabaseHeaders() {
    if (_client != null) {
      _client!.headers.remove('Authorization');
      _debugLog('Cleared Authorization header');
    }
  }

  /// Ensure authentication headers are up to date
  Future<bool> ensureAuthenticationHeaders() async {
    if (_sessionService == null) {
      _debugLog('No session service available');
      return false;
    }

    try {
      if (!_sessionService!.isAuthenticated) {
        return false;
      }

      final accessToken = await _sessionService!.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return false;
      }

      if (_client != null) {
        _client!.headers['Authorization'] = 'Bearer $accessToken';
        return true;
      }

      return false;
    } catch (e) {
      _debugLog('Error ensuring auth headers: $e');
      return false;
    }
  }

  /// Extract user ID from JWT token
  String? _extractUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final jwtPayload = jsonDecode(decoded) as Map<String, dynamic>;

      return jwtPayload['sub'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Validate current authentication state
  Future<bool> validateAuthentication() async {
    try {
      if (_sessionService == null || !_sessionService!.isAuthenticated) {
        return false;
      }

      final accessToken = await _sessionService!.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return false;
      }

      await ensureAuthenticationHeaders();

      // Try a simple authenticated request to validate
      try {
        await client.from('users').select('id').limit(1);
        return true;
      } catch (e) {
        _debugLog('Auth validation query failed: $e');
        return false;
      }
    } catch (e) {
      _debugLog('Error validating authentication: $e');
      return false;
    }
  }

  /// Quick health check
  Future<Map<String, dynamic>> quickHealthCheck() async {
    final health = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'isInitialized': _isInitialized,
      'hasClient': _client != null,
      'hasSessionService': _sessionService != null,
      'isAuthenticated': isAuthenticated,
    };

    int passedChecks = 0;
    if (_isInitialized) passedChecks++;
    if (_client != null) passedChecks++;
    if (_sessionService != null) passedChecks++;
    if (isAuthenticated) passedChecks++;

    health['passedChecks'] = passedChecks;
    health['overallHealthy'] = passedChecks >= 3;

    return health;
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'isInitialized': _isInitialized,
      'hasClient': _client != null,
      'hasSessionService': _sessionService != null,
      'sessionServiceAuthenticated': _sessionService?.isAuthenticated ?? false,
      'sessionServiceUserId': _sessionService?.userId,
      'hasAuthHeader': _client?.headers.containsKey('Authorization') ?? false,
    };
  }

  /// Reset the provider
  Future<void> reset() async {
    _clearSupabaseHeaders();
    if (_sessionService != null) {
      await _updateSupabaseHeaders();
    }
  }
}
