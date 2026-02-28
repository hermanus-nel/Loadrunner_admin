// lib/features/auth/data/services/auth_service.dart
// Exact copy from main LoadRunner app's AuthService
// Uses BulkSmsService for OTP, with admin role verification

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/bulksms_service.dart';

class AuthService {
  final SessionService _sessionService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final BulkSmsService bulkSmsService;

  // Storage keys
  static const String _phonePrefKey = 'admin_last_phone_number';

  AuthService({
    required SessionService sessionService,
    required this.bulkSmsService,
  }) : _sessionService = sessionService;

  // Get stored phone number
  Future<String?> getStoredPhoneNumber() async {
    return await _secureStorage.read(key: _phonePrefKey);
  }

  // Store phone number
  Future<void> storePhoneNumber(String phoneNumber) async {
    await _secureStorage.write(key: _phonePrefKey, value: phoneNumber);
  }

  // Send OTP to a phone number
  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    try {
      // Normalize phone number
      final normalizedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+$phoneNumber';
      debugPrint('AuthService: Sending OTP to normalized phone: $normalizedPhone');

      // Use BulkSmsService to send OTP
      debugPrint('AuthService: Using BulkSmsService to send OTP');
      final result = await bulkSmsService.sendOtp(normalizedPhone);

      // Store phone number for convenience regardless of success
      await storePhoneNumber(normalizedPhone);

      return result;
    } catch (e) {
      debugPrint('AuthService: Error sending OTP: $e');
      return {
        'success': false,
        'message': 'Failed to send OTP: $e',
      };
    }
  }

  // Verify OTP and sign in
  Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String otp) async {
    try {
      // Normalize phone number
      final normalizedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+$phoneNumber';

      // Use BulkSmsService to verify OTP
      final isValid = await bulkSmsService.verifyOtp(normalizedPhone, otp);

      if (!isValid) {
        debugPrint('AuthService: Invalid OTP for $normalizedPhone');
        return {
          'success': false,
          'message': 'Invalid OTP code',
        };
      }

      debugPrint('AuthService: OTP verified successfully for $normalizedPhone');

      // Create session using our custom session service
      final sessionResult = await _sessionService.createSession(normalizedPhone);

      if (!(sessionResult['success'] as bool)) {
        debugPrint('AuthService: Session creation failed: ${sessionResult['message']}');
        return {
          'success': false,
          'message': sessionResult['message'] ?? 'Unable to sign in. Please try again later.',
        };
      }

      // ✅ ADMIN CHECK: Verify user has Admin role
      final userRole = sessionResult['userRole'];
      debugPrint('AuthService: User role: $userRole');

      if (userRole != 'Admin') {
        debugPrint('AuthService: User is not an admin, signing out');
        await _sessionService.signOut();
        return {
          'success': false,
          'message': 'Access denied. Admin privileges required.',
        };
      }

      debugPrint('AuthService: Admin login successful');

      // Register FCM token now that userId is available
      await FcmService.instance.registerCurrentToken();

      // Return appropriate data from session result
      return {
        'success': true,
        'message': 'Successfully signed in',
        'userId': sessionResult['userId'],
        'userRole': userRole,
        'isNewUser': sessionResult['isNewUser'],
      };
    } catch (e) {
      debugPrint('AuthService: Error verifying OTP: $e');
      return {
        'success': false,
        'message': 'Unable to sign in. Please try again later.',
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _sessionService.signOut();
  }

  // Check if user is authenticated
  bool get isAuthenticated => _sessionService.isAuthenticated;

  // Get auth state changes stream
  Stream<bool> get authStateChanges => _sessionService.authStateChanges;

  // Get user ID
  String? get userId => _sessionService.userId;

  // Get user phone
  String? get userPhone => _sessionService.userPhone;

  // Get user role
  Future<String?> getUserRole() async {
    return await _sessionService.getUserRole();
  }
}
