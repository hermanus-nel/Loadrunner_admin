// lib/core/services/session_service.dart
// Adapted from main LoadRunner app's SessionService
// Uses phone/OTP authentication via Edge Function (same as main app)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  final SupabaseClient supabaseClient;
  final String edgeFunctionUrl;
  final String apiKey;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  final SharedPreferences? _prefs;

  // Keys for secure storage (FlutterSecureStorage)
  static const String _accessTokenKey = 'admin_access_token';
  static const String _refreshTokenKey = 'admin_refresh_token';
  static const String _userIdKey = 'admin_user_id';
  static const String _userPhoneKey = 'admin_user_phone';

  // Keys for SharedPreferences (backup metadata)
  static const String _prefUserId = 'admin_session_user_id';
  static const String _prefUserPhone = 'admin_session_user_phone';
  static const String _prefTokenExpiry = 'admin_session_token_expiry';
  static const String _prefLastAuth = 'admin_session_last_auth';
  static const String _prefSessionCreated = 'admin_session_created';

  // Authorization header name
  static const String _authHeader = 'Authorization';

  // Session state
  String? _userId;
  String? _userPhone;
  String? _accessToken;
  String? _refreshToken;

  // Operation locks
  bool _isRefreshing = false;

  // JWT refresh retry tracking
  int _consecutiveRefreshFailures = 0;
  static const int _maxRefreshAttempts = 3;

  // Background token refresh
  Timer? _tokenRefreshTimer;

  // Stream controller for session changes
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();

  // Debug mode flag
  static bool debugMode = true;

  // Constructor
  SessionService({
    required this.supabaseClient,
    required this.edgeFunctionUrl,
    required this.apiKey,
    SharedPreferences? prefs,
  }) : _prefs = prefs;

  // Debug logging helper
  void _debugLog(String message) {
    if (debugMode) {
      debugPrint('🔐 SessionService Debug: $message');
    }
  }

  // Expose refresh token for external use
  String? get refreshToken => _refreshToken;

  // Get the auth state stream
  Stream<bool> get authStateChanges => _authStateController.stream;

  // Check if user is authenticated
  bool get isAuthenticated => _accessToken != null && _userId != null;

  // Get current user ID
  String? get userId => _userId;

  // Get current user phone
  String? get userPhone => _userPhone;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize session - call on app start
  Future<void> initialize() async {
    _debugLog('=== INITIALIZING SESSION ===');

    try {
      // Try to restore session from secure storage
      _accessToken = await _secureStorage.read(key: _accessTokenKey);
      _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      _userId = await _secureStorage.read(key: _userIdKey);
      _userPhone = await _secureStorage.read(key: _userPhoneKey);

      _debugLog('Restored from storage:');
      _debugLog('  - hasAccessToken: ${_accessToken != null}');
      _debugLog('  - hasRefreshToken: ${_refreshToken != null}');
      _debugLog('  - userId: $_userId');
      _debugLog('  - userPhone: $_userPhone');

      if (_accessToken != null && _userId != null) {
        // Validate token
        final payload = await _extractJwtPayload(_accessToken);
        
        if (payload.isNotEmpty) {
          // Check if token is expired or near expiry
          if (payload.containsKey('exp')) {
            final expiration = DateTime.fromMillisecondsSinceEpoch((payload['exp'] as int) * 1000);
            final now = DateTime.now();

            if (now.isAfter(expiration)) {
              _debugLog('Token expired, attempting refresh...');
              await refreshSessionIfNeeded(forceRefresh: true);
            } else if (expiration.difference(now).inMinutes < 30) {
              _debugLog('Token near expiry, refreshing proactively...');
              await refreshSessionIfNeeded(forceRefresh: true);
            } else {
              _debugLog('Token valid, setting headers...');
              setSupabaseHeaders();
              _startBackgroundTokenRefresh();
              _authStateController.add(true);
            }
          }
        } else {
          _debugLog('Invalid token format, attempting refresh...');
          await refreshSessionIfNeeded(forceRefresh: true);
        }
      } else if (_refreshToken != null) {
        _debugLog('No access token but have refresh token, attempting refresh...');
        final refreshed = await refreshSessionIfNeeded(forceRefresh: true);
        if (refreshed) {
          _authStateController.add(true);
        }
      } else {
        _debugLog('No session found');
        _authStateController.add(false);
      }
    } catch (e) {
      _debugLog('Error initializing session: $e');
      await clearSession();
      _authStateController.add(false);
    }
  }

  // ============================================================
  // AUTHENTICATION - Phone/OTP via Edge Function (same as main app)
  // ============================================================

  /// Create session with phone number (after OTP verification)
  Future<Map<String, dynamic>> createSession(String phoneNumber) async {
    _debugLog('=== CREATING NEW SESSION ===');
    _debugLog('Phone number: $phoneNumber');

    try {
      final normalizedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+$phoneNumber';
      _debugLog('Normalized phone: $normalizedPhone');

      final requestData = {
        'action': 'create-session',
        'phoneNumber': normalizedPhone,
      };

      final response = await http.post(
        Uri.parse(edgeFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      _debugLog('Session creation response: ${response.statusCode}');

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to create session: ${response.reasonPhrase}'
        };
      }

      final responseData = jsonDecode(response.body);
      if (responseData['success'] != true) {
        final errorMessage = responseData['error']?['message'] ?? 'Unknown error';
        return {
          'success': false,
          'message': 'Failed to create session: $errorMessage'
        };
      }

      final session = responseData['session'];
      if (session == null) {
        return {
          'success': false,
          'message': 'No session data received from server'
        };
      }

      _accessToken = session['access_token'] as String?;
      _refreshToken = session['refresh_token'] as String?;

      _debugLog('Received tokens:');
      _debugLog('  - access token: ${_accessToken != null}');
      _debugLog('  - refresh token: ${_refreshToken != null}');

      if (_accessToken == null || _refreshToken == null) {
        return {
          'success': false,
          'message': 'Invalid session data: missing tokens'
        };
      }

      // Validate tokens before proceeding
      final jwtPayload = await _extractJwtPayload(_accessToken);
      if (jwtPayload.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid access token received'
        };
      }

      if (session['user'] != null) {
        _userId = session['user']['id'] as String?;
        _userPhone = session['user']['phone'] as String?;
      } else {
        _userId = jwtPayload['sub'] as String?;
        _userPhone = jwtPayload['phone'] as String?;
      }

      _debugLog('Session user data:');
      _debugLog('  - user ID (auth): $_userId');
      _debugLog('  - user phone: $_userPhone');

      // Set auth header early so the lookup query works through RLS
      supabaseClient.headers[_authHeader] = 'Bearer $_accessToken';
      supabaseClient.headers['apikey'] = apiKey;

      // Resolve canonical public.users.id by phone number.
      // auth.users.id (from Edge Function) differs from public.users.id
      // (auto-generated), and all app queries use public.users.id.
      if (_userPhone != null) {
        try {
          final userRow = await supabaseClient
              .from('users')
              .select('id')
              .eq('phone_number', _userPhone!)
              .maybeSingle();
          if (userRow != null && userRow['id'] != null) {
            final publicUserId = userRow['id'] as String;
            if (publicUserId != _userId) {
              _debugLog(
                'Resolved public.users.id: $publicUserId (was: $_userId)',
              );
              _userId = publicUserId;
            }
          }
        } catch (e) {
          _debugLog('Error resolving public user ID: $e');
        }
      }

      // Store tokens in secure storage
      await _secureStorage.write(key: _accessTokenKey, value: _accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: _refreshToken);
      if (_userId != null) await _secureStorage.write(key: _userIdKey, value: _userId);
      if (_userPhone != null) await _secureStorage.write(key: _userPhoneKey, value: _userPhone);

      // Write session metadata to SharedPreferences
      await _writeSessionMetadata();

      // Set headers for API access
      setSupabaseHeaders();

      // Get user role
      String? userRole;
      bool isNewUser = (responseData['isNewUser'] as bool?) ?? false;

      try {
        userRole = await getUserRole();
        _debugLog('User role: $userRole');
      } catch (e) {
        _debugLog('Error getting user role: $e');
      }

      // Start background token refresh
      _startBackgroundTokenRefresh();

      // Broadcast auth state change
      _authStateController.add(true);

      return {
        'success': true,
        'userId': _userId,
        'userRole': userRole,
        'isNewUser': isNewUser,
      };
    } catch (e) {
      _debugLog('Error creating session: $e');
      return {
        'success': false,
        'message': 'Unable to sign in. Please try again later.',
      };
    }
  }

  // ============================================================
  // TOKEN REFRESH
  // ============================================================

  /// Refresh session if needed
  Future<bool> refreshSessionIfNeeded({bool forceRefresh = false}) async {
    if (_isRefreshing) {
      _debugLog('Already refreshing, waiting...');
      await Future.delayed(const Duration(milliseconds: 500));
      return isAuthenticated;
    }

    if (_refreshToken == null) {
      _debugLog('No refresh token available');
      return false;
    }

    _isRefreshing = true;

    try {
      // Check if refresh is actually needed
      if (!forceRefresh && _accessToken != null) {
        final payload = await _extractJwtPayload(_accessToken);
        if (payload.containsKey('exp')) {
          final expiration = DateTime.fromMillisecondsSinceEpoch((payload['exp'] as int) * 1000);
          final minutesUntilExpiry = expiration.difference(DateTime.now()).inMinutes;

          if (minutesUntilExpiry > 15) {
            _debugLog('Token still valid for $minutesUntilExpiry minutes, skipping refresh');
            _isRefreshing = false;
            return true;
          }
        }
      }

      _debugLog('Refreshing session...');

      // Try Supabase session refresh
      try {
        final response = await supabaseClient.auth.refreshSession();
        
        if (response.session != null) {
          _accessToken = response.session!.accessToken;
          _refreshToken = response.session!.refreshToken;
          
          await _saveSession();
          setSupabaseHeaders();
          await _writeSessionMetadata();
          
          _consecutiveRefreshFailures = 0;
          _debugLog('Session refreshed successfully via Supabase');
          _isRefreshing = false;
          return true;
        }
      } catch (e) {
        _debugLog('Supabase refresh failed: $e');
      }

      // Fallback: Try edge function refresh
      try {
        final response = await http.post(
          Uri.parse(edgeFunctionUrl),
          headers: {
            'Content-Type': 'application/json',
            'apikey': apiKey,
          },
          body: jsonEncode({
            'action': 'refresh-token',
            'refreshToken': _refreshToken,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['session'] != null) {
            _accessToken = data['session']['access_token'] as String?;
            _refreshToken = data['session']['refresh_token'] as String?;
            
            await _saveSession();
            setSupabaseHeaders();
            await _writeSessionMetadata();
            
            _consecutiveRefreshFailures = 0;
            _debugLog('Session refreshed successfully via edge function');
            _isRefreshing = false;
            return true;
          }
        }
      } catch (e) {
        _debugLog('Edge function refresh failed: $e');
      }

      _consecutiveRefreshFailures++;
      _debugLog('Session refresh failed (attempt $_consecutiveRefreshFailures)');

      if (_consecutiveRefreshFailures >= _maxRefreshAttempts) {
        _debugLog('Max refresh attempts reached, clearing session');
        await clearSession();
        _authStateController.add(false);
      }

      _isRefreshing = false;
      return false;
    } catch (e) {
      _debugLog('Error during refresh: $e');
      _consecutiveRefreshFailures++;
      _isRefreshing = false;
      return false;
    }
  }

  // ============================================================
  // TOKEN MANAGEMENT
  // ============================================================

  /// Get access token (with auto-refresh if needed)
  Future<String?> getAccessToken() async {
    if (_accessToken == null && _refreshToken == null) {
      _debugLog('No tokens available');
      return null;
    }

    try {
      if (_accessToken == null) {
        _debugLog('No access token, attempting refresh...');
        await refreshSessionIfNeeded(forceRefresh: true);
        return _accessToken;
      }

      final payload = await _extractJwtPayload(_accessToken);
      if (payload.isEmpty) {
        _debugLog('Access token invalid, refreshing...');
        await refreshSessionIfNeeded(forceRefresh: true);
        return _accessToken;
      }

      if (payload.containsKey('exp')) {
        final expiration = DateTime.fromMillisecondsSinceEpoch((payload['exp'] as int) * 1000);
        final now = DateTime.now();

        if (now.isAfter(expiration) || expiration.difference(now).inMinutes < 30) {
          _debugLog('Access token expired/near expiry, refreshing...');
          await refreshSessionIfNeeded(forceRefresh: true);
        }
      }

      return _accessToken;
    } catch (e) {
      _debugLog('Error getting access token: $e');
      try {
        await refreshSessionIfNeeded(forceRefresh: true);
        return _accessToken;
      } catch (refreshError) {
        _debugLog('Error refreshing token: $refreshError');
        return null;
      }
    }
  }

  /// Set Supabase headers for authenticated requests
  void setSupabaseHeaders() {
    if (_accessToken == null) {
      _debugLog('Cannot set headers: no access token');
      return;
    }

    try {
      supabaseClient.headers[_authHeader] = 'Bearer $_accessToken';
      supabaseClient.headers['apikey'] = apiKey;
      _debugLog('Headers updated for authenticated requests');
    } catch (e) {
      _debugLog('Error setting Supabase headers: $e');
    }
  }

  // ============================================================
  // SESSION PERSISTENCE
  // ============================================================

  /// Save session to secure storage
  Future<void> _saveSession() async {
    try {
      if (_accessToken != null) {
        await _secureStorage.write(key: _accessTokenKey, value: _accessToken);
      }
      if (_refreshToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: _refreshToken);
      }
      if (_userId != null) {
        await _secureStorage.write(key: _userIdKey, value: _userId);
      }
      if (_userPhone != null) {
        await _secureStorage.write(key: _userPhoneKey, value: _userPhone);
      }
      _debugLog('Session saved to secure storage');
    } catch (e) {
      _debugLog('Error saving session: $e');
    }
  }

  /// Write session metadata to SharedPreferences (backup)
  Future<void> _writeSessionMetadata() async {
    if (_prefs == null) {
      _debugLog('SharedPreferences not available, skipping metadata backup');
      return;
    }

    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      if (_userId != null) {
        await _prefs!.setString(_prefUserId, _userId!);
      }
      if (_userPhone != null) {
        await _prefs!.setString(_prefUserPhone, _userPhone!);
      }

      // Extract token expiry
      if (_accessToken != null) {
        final payload = await _extractJwtPayload(_accessToken);
        if (payload.containsKey('exp')) {
          await _prefs!.setInt(_prefTokenExpiry, payload['exp'] as int);
        }
      }

      await _prefs!.setInt(_prefLastAuth, now);

      if (!_prefs!.containsKey(_prefSessionCreated)) {
        await _prefs!.setInt(_prefSessionCreated, now);
      }

      _debugLog('Session metadata written to SharedPreferences');
    } catch (e) {
      _debugLog('Error writing session metadata: $e');
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  /// Sign out and clear session
  Future<void> signOut() async {
    _debugLog('=== SIGNING OUT ===');

    // Sign out from Supabase auth
    try {
      await supabaseClient.auth.signOut();
      _debugLog('Supabase auth sign out successful');
    } catch (e) {
      _debugLog('Error signing out from Supabase auth: $e');
    }

    await clearSession();
    _authStateController.add(false);
    _debugLog('Sign out completed');
  }

  /// Clear session data
  Future<void> clearSession() async {
    _debugLog('Clearing session data...');

    // Cancel background token refresh
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;

    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _userPhone = null;

    // Clear FlutterSecureStorage
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _userPhoneKey);

    // Clear SharedPreferences metadata
    if (_prefs != null) {
      await _prefs!.remove(_prefUserId);
      await _prefs!.remove(_prefUserPhone);
      await _prefs!.remove(_prefTokenExpiry);
      await _prefs!.remove(_prefLastAuth);
      await _prefs!.remove(_prefSessionCreated);
    }

    // Clear headers
    supabaseClient.headers.remove(_authHeader);

    _debugLog('Session cleared');
  }

  // ============================================================
  // USER DATA
  // ============================================================

  /// Get user role from database
  Future<String?> getUserRole() async {
    if (!isAuthenticated || userId == null) {
      return null;
    }

    try {
      final response = await supabaseClient
          .from('users')
          .select('role')
          .eq('id', userId!)
          .single();

      return response['role'] as String?;
    } catch (e) {
      _debugLog('Error getting user role: $e');
      return null;
    }
  }

  // ============================================================
  // BACKGROUND REFRESH
  // ============================================================

  /// Start background token refresh timer
  void _startBackgroundTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 25),
      (_) => refreshSessionIfNeeded(),
    );
    _debugLog('Background token refresh started (every 25 minutes)');
  }

  // ============================================================
  // JWT UTILITIES
  // ============================================================

  /// Extract JWT payload with validation
  Future<Map<String, dynamic>> _extractJwtPayload(String? token) async {
    if (token == null || token.isEmpty) {
      return {};
    }

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return {};
      }

      String normalized = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;

      // Validate required fields
      if (!decoded.containsKey('sub') || !decoded.containsKey('exp')) {
        return {};
      }

      return decoded;
    } catch (e) {
      _debugLog('JWT extraction error: $e');
      return {};
    }
  }

  // ============================================================
  // AUTHENTICATED REQUESTS
  // ============================================================

  /// Make an authenticated request
  Future<Map<String, dynamic>> authenticatedRequest({
    required String path,
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final requestHeaders = {
        'Content-Type': 'application/json',
        'apikey': apiKey,
        _authHeader: 'Bearer $token',
        ...?headers,
      };

      final baseUrl = supabaseClient.rest.url.toString().replaceAll('/rest/v1', '');
      final uri = Uri.parse('$baseUrl/rest/v1/$path');

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(uri, headers: requestHeaders, body: data != null ? jsonEncode(data) : null);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: requestHeaders, body: data != null ? jsonEncode(data) : null);
          break;
        case 'PUT':
          response = await http.put(uri, headers: requestHeaders, body: data != null ? jsonEncode(data) : null);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': response.body.isNotEmpty ? jsonDecode(response.body) : null,
        };
      } else {
        return {
          'success': false,
          'error': 'Request failed with status ${response.statusCode}: ${response.reasonPhrase}',
          'data': response.body.isNotEmpty ? jsonDecode(response.body) : null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error making authenticated request: $e',
      };
    }
  }

  // ============================================================
  // DEBUG INFO
  // ============================================================

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'isRefreshing': _isRefreshing,
      'hasAccessToken': _accessToken != null,
      'hasRefreshToken': _refreshToken != null,
      'isAuthenticated': isAuthenticated,
      'userId': _userId,
      'userPhone': _userPhone,
      'accessTokenLength': _accessToken?.length,
      'refreshTokenLength': _refreshToken?.length,
      'consecutiveRefreshFailures': _consecutiveRefreshFailures,
      'supabaseHeaders': {
        'hasAuth': supabaseClient.headers.containsKey(_authHeader),
        'hasApiKey': supabaseClient.headers.containsKey('apikey'),
      },
    };
  }

  /// Dispose resources
  void dispose() {
    _tokenRefreshTimer?.cancel();
    _authStateController.close();
  }
}
