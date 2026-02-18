// lib/core/services/bulksms_service.dart
// Exact copy from main LoadRunner app

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BulkSmsService {
  final String _apiUrl = 'https://api.bulksms.com/v1/messages';
  final String _username;
  final String _password;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  BulkSmsService({
    required String username,
    required String password,
  })  : _username = username,
        _password = password;

  /// Generate a 6-digit OTP
  String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Store OTP securely with expiration
  Future<bool> storeOtp(String phoneNumber, String otp) async {
    try {
      // Normalize phone number for consistent storage
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);

      // Store with expiration time (5 minutes from now)
      final expiresAt = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
      final data = {
        'otp': otp,
        'expiresAt': expiresAt,
      };

      await _secureStorage.write(
        key: 'otp_$normalizedPhone',
        value: jsonEncode(data),
      );

      debugPrint('BulkSmsService: OTP stored securely for $normalizedPhone: $otp');
      return true;
    } catch (e) {
      debugPrint('BulkSmsService: Error storing OTP: $e');
      return false;
    }
  }

  /// Verify OTP
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    try {
      // Normalize phone number for consistent lookup
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);

      final storedDataString = await _secureStorage.read(key: 'otp_$normalizedPhone');
      if (storedDataString == null) {
        debugPrint('BulkSmsService: No OTP found for $normalizedPhone');
        return false;
      }

      final storedData = jsonDecode(storedDataString) as Map<String, dynamic>;
      final storedOtp = storedData['otp'] as String?;
      final expiryTime = (storedData['expiresAt'] as num).toInt();

      debugPrint('BulkSmsService: OTP expiry time: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}');
      debugPrint('BulkSmsService: Current time: ${DateTime.now()}');

      if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
        // Expired
        debugPrint('BulkSmsService: OTP expired for $normalizedPhone');
        await clearOtp(normalizedPhone);
        return false;
      }

      debugPrint('BulkSmsService: Verifying OTP - Input: $otp, Stored: $storedOtp');
      if (storedOtp == otp) {
        debugPrint('BulkSmsService: OTP verified successfully for $normalizedPhone');
        await clearOtp(normalizedPhone);
        return true;
      }

      debugPrint('BulkSmsService: OTP verification failed for $normalizedPhone');
      return false;
    } catch (e) {
      debugPrint('BulkSmsService: Error verifying OTP: $e');
      return false;
    }
  }

  /// Clear OTP after verification or expiry
  Future<void> clearOtp(String phoneNumber) async {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    await _secureStorage.delete(key: 'otp_$normalizedPhone');
    debugPrint('BulkSmsService: OTP cleared for $normalizedPhone');
  }

  /// Send OTP via BulkSMS
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      // Normalize phone number
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);
      debugPrint('BulkSmsService: Sending OTP to normalized phone: $normalizedPhone');

      // Generate OTP
      final otp = generateOtp();
      debugPrint('BulkSmsService: Generated OTP: $otp');

      // Store securely
      final stored = await storeOtp(normalizedPhone, otp);
      if (!stored) {
        debugPrint('BulkSmsService: Failed to store OTP');
        return {
          'success': false,
          'message': 'Failed to store OTP',
        };
      }

      // Create auth credentials
      final credentials = base64Encode(utf8.encode('$_username:$_password'));

      // Prepare message
      final message = {
        'to': normalizedPhone,
        'body': '$otp: Your LoadRunner Admin verification code is: $otp. Valid for 5 minutes.',
        'encoding': 'TEXT',
      };

      debugPrint('BulkSmsService: Sending SMS with message: ${message['body']}');

      // Send SMS
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $credentials',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('BulkSmsService: OTP sent successfully to $normalizedPhone');
        return {
          'success': true,
          'message': 'OTP sent successfully',
        };
      } else {
        debugPrint('BulkSmsService: Failed to send OTP: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to send OTP: ${response.body}',
        };
      }
    } catch (e) {
      debugPrint('BulkSmsService: Error in sendOtp: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Send custom SMS message
  Future<Map<String, dynamic>> sendCustomMessage(String phoneNumber, String message) async {
    try {
      // Normalize phone number
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);
      debugPrint('BulkSmsService: Sending custom message to normalized phone: $normalizedPhone');

      // Create auth credentials
      final credentials = base64Encode(utf8.encode('$_username:$_password'));

      // Prepare message
      final messageData = {
        'to': normalizedPhone,
        'body': message,
        'encoding': 'TEXT',
      };

      debugPrint('BulkSmsService: Sending SMS with message: $message');

      // Send SMS
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $credentials',
        },
        body: jsonEncode(messageData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('BulkSmsService: Custom message sent successfully to $normalizedPhone');
        return {
          'success': true,
          'message': 'SMS sent successfully',
        };
      } else {
        debugPrint('BulkSmsService: Failed to send custom message: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to send SMS: ${response.body}',
        };
      }
    } catch (e) {
      debugPrint('BulkSmsService: Error in sendCustomMessage: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Normalize phone number to ensure consistent format with country code
  String _normalizePhoneNumber(String phone) {
    if (phone.isEmpty) return '';

    // Remove all non-digit characters except +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Ensure it has a + prefix
    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }

    return cleaned;
  }
}
