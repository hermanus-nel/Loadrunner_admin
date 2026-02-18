// test/helpers/mock_auth_service.dart

import 'dart:async';
import '../../lib/features/auth/data/services/auth_service.dart';
import '../../lib/core/services/bulksms_service.dart';

/// Mock AuthService for testing authentication flows
class MockAuthService implements AuthService {
  bool _isAuthenticated = false;
  String? _userId;
  String? _userPhone;
  String? _userRole;
  String? _storedPhoneNumber;
  final _authStateController = StreamController<bool>.broadcast();

  @override
  BulkSmsService get bulkSmsService => throw UnimplementedError('Not needed in tests');

  @override
  Future<void> storePhoneNumber(String phoneNumber) async {
    _storedPhoneNumber = phoneNumber;
  }

  // Control mock behavior
  bool shouldFailOtp = false;
  bool shouldFailVerify = false;
  String mockOtp = '123456';
  String mockRole = 'Admin';

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  String? get userId => _userId;

  @override
  String? get userPhone => _userPhone;

  @override
  Stream<bool> get authStateChanges => _authStateController.stream;

  @override
  Future<String?> getUserRole() async => _userRole;

  @override
  Future<String?> getStoredPhoneNumber() async => _storedPhoneNumber;

  @override
  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    if (shouldFailOtp) {
      return {'success': false, 'message': 'Failed to send OTP'};
    }
    _storedPhoneNumber = phoneNumber;
    _userPhone = phoneNumber;
    return {'success': true, 'message': 'OTP sent successfully'};
  }

  @override
  Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String otp) async {
    if (shouldFailVerify) {
      return {'success': false, 'message': 'Invalid OTP'};
    }
    if (otp != mockOtp) {
      return {'success': false, 'message': 'Invalid OTP code'};
    }

    _isAuthenticated = true;
    _userId = 'test-user-id';
    _userPhone = phoneNumber;
    _userRole = mockRole;
    _authStateController.add(true);

    return {'success': true, 'message': 'OTP verified'};
  }

  @override
  Future<void> signOut() async {
    _isAuthenticated = false;
    _userId = null;
    _userRole = null;
    _authStateController.add(false);
  }

  void dispose() {
    _authStateController.close();
  }
}
