import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// Service for secure and persistent storage
class StorageService {
  StorageService._();

  static final StorageService _instance = StorageService._();
  static StorageService get instance => _instance;

  late final FlutterSecureStorage _secureStorage;
  late final SharedPreferences _prefs;
  bool _initialized = false;

  /// Initialize storage service
  Future<void> initialize() async {
    if (_initialized) return;

    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );

    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
  }

  // ===========================================
  // SECURE STORAGE (for sensitive data)
  // ===========================================

  /// Save secure value
  Future<void> saveSecure(String key, String value) async {
    _ensureInitialized();
    await _secureStorage.write(key: key, value: value);
  }

  /// Read secure value
  Future<String?> readSecure(String key) async {
    _ensureInitialized();
    return await _secureStorage.read(key: key);
  }

  /// Delete secure value
  Future<void> deleteSecure(String key) async {
    _ensureInitialized();
    await _secureStorage.delete(key: key);
  }

  /// Delete all secure values
  Future<void> deleteAllSecure() async {
    _ensureInitialized();
    await _secureStorage.deleteAll();
  }

  /// Check if secure key exists
  Future<bool> containsSecureKey(String key) async {
    _ensureInitialized();
    return await _secureStorage.containsKey(key: key);
  }

  // ===========================================
  // AUTH TOKEN HELPERS
  // ===========================================

  /// Save auth token
  Future<void> saveAuthToken(String token) async {
    await saveSecure(AppConstants.tokenKey, token);
  }

  /// Get auth token
  Future<String?> getAuthToken() async {
    return await readSecure(AppConstants.tokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await saveSecure(AppConstants.refreshTokenKey, token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await readSecure(AppConstants.refreshTokenKey);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await saveSecure(AppConstants.userIdKey, userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await readSecure(AppConstants.userIdKey);
  }

  /// Clear all auth data
  Future<void> clearAuthData() async {
    await deleteSecure(AppConstants.tokenKey);
    await deleteSecure(AppConstants.refreshTokenKey);
    await deleteSecure(AppConstants.userIdKey);
  }

  /// Check if user is logged in (has auth token)
  Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  // ===========================================
  // SHARED PREFERENCES (for non-sensitive data)
  // ===========================================

  /// Save string value
  Future<bool> saveString(String key, String value) async {
    _ensureInitialized();
    return await _prefs.setString(key, value);
  }

  /// Get string value
  String? getString(String key) {
    _ensureInitialized();
    return _prefs.getString(key);
  }

  /// Save int value
  Future<bool> saveInt(String key, int value) async {
    _ensureInitialized();
    return await _prefs.setInt(key, value);
  }

  /// Get int value
  int? getInt(String key) {
    _ensureInitialized();
    return _prefs.getInt(key);
  }

  /// Save bool value
  Future<bool> saveBool(String key, bool value) async {
    _ensureInitialized();
    return await _prefs.setBool(key, value);
  }

  /// Get bool value
  bool? getBool(String key) {
    _ensureInitialized();
    return _prefs.getBool(key);
  }

  /// Save double value
  Future<bool> saveDouble(String key, double value) async {
    _ensureInitialized();
    return await _prefs.setDouble(key, value);
  }

  /// Get double value
  double? getDouble(String key) {
    _ensureInitialized();
    return _prefs.getDouble(key);
  }

  /// Save string list
  Future<bool> saveStringList(String key, List<String> value) async {
    _ensureInitialized();
    return await _prefs.setStringList(key, value);
  }

  /// Get string list
  List<String>? getStringList(String key) {
    _ensureInitialized();
    return _prefs.getStringList(key);
  }

  /// Remove value
  Future<bool> remove(String key) async {
    _ensureInitialized();
    return await _prefs.remove(key);
  }

  /// Check if key exists
  bool containsKey(String key) {
    _ensureInitialized();
    return _prefs.containsKey(key);
  }

  /// Clear all preferences
  Future<bool> clearAll() async {
    _ensureInitialized();
    return await _prefs.clear();
  }

  // ===========================================
  // THEME HELPERS
  // ===========================================

  /// Save theme mode
  Future<void> saveThemeMode(String mode) async {
    await saveString(AppConstants.themeKey, mode);
  }

  /// Get theme mode
  String? getThemeMode() {
    return getString(AppConstants.themeKey);
  }

  // ===========================================
  // SYNC HELPERS
  // ===========================================

  /// Save last sync timestamp
  Future<void> saveLastSync(DateTime dateTime) async {
    await saveString(AppConstants.lastSyncKey, dateTime.toIso8601String());
  }

  /// Get last sync timestamp
  DateTime? getLastSync() {
    final value = getString(AppConstants.lastSyncKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
}
