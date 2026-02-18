// test/features/auth/auth_flow_test.dart

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/features/auth/presentation/providers/auth_notifier.dart';
import '../../../lib/features/auth/presentation/providers/auth_state.dart';
import '../../helpers/mock_auth_service.dart';

void main() {
  late MockAuthService mockAuthService;
  late AuthNotifier authNotifier;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  tearDown(() {
    mockAuthService.dispose();
  });

  group('Authentication Flow', () {
    group('OTP Sending', () {
      test('should send OTP successfully', () async {
        authNotifier = AuthNotifier(mockAuthService);
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        final result = await authNotifier.sendOtp('+27821234567');

        expect(result['success'], isTrue);
        expect(authNotifier.state.phoneNumber, equals('+27821234567'));
        expect(authNotifier.state.isOtpSent, isTrue);
        expect(authNotifier.state.isLoading, isFalse);
      });

      test('should handle OTP sending failure', () async {
        mockAuthService.shouldFailOtp = true;
        authNotifier = AuthNotifier(mockAuthService);
        await Future.delayed(const Duration(milliseconds: 100));

        final result = await authNotifier.sendOtp('+27821234567');

        expect(result['success'], isFalse);
        expect(authNotifier.state.isOtpSent, isFalse);
        expect(authNotifier.state.hasError, isTrue);
      });

      test('should reset OTP state', () async {
        authNotifier = AuthNotifier(mockAuthService);
        await Future.delayed(const Duration(milliseconds: 100));

        await authNotifier.sendOtp('+27821234567');
        expect(authNotifier.state.isOtpSent, isTrue);

        authNotifier.resetOtpState();
        expect(authNotifier.state.isOtpSent, isFalse);
      });
    });

    group('OTP Verification', () {
      test('should verify OTP and authenticate admin', () async {
        authNotifier = AuthNotifier(mockAuthService);
        await Future.delayed(const Duration(milliseconds: 100));

        await authNotifier.sendOtp('+27821234567');
        final result = await authNotifier.verifyOtp('123456');

        expect(result['success'], isTrue);
        expect(authNotifier.state.isLoading, isFalse);
      });

      test('should reject invalid OTP', () async {
        authNotifier = AuthNotifier(mockAuthService);
        await Future.delayed(const Duration(milliseconds: 100));

        await authNotifier.sendOtp('+27821234567');
        final result = await authNotifier.verifyOtp('000000');

        expect(result['success'], isFalse);
        expect(result['message'], contains('Invalid'));
      });

      test('should reject non-admin users', () async {
        mockAuthService.mockRole = 'Driver';
        authNotifier = AuthNotifier(mockAuthService);
        await Future.delayed(const Duration(milliseconds: 100));

        await authNotifier.sendOtp('+27821234567');
        await authNotifier.verifyOtp('123456');

        // Auth listener should detect non-admin role and sign out
        await Future.delayed(const Duration(milliseconds: 100));
        expect(authNotifier.state.isAdmin, isFalse);
      });

      test('should fail when phone number not set', () async {
        authNotifier = AuthNotifier(mockAuthService);
        await Future.delayed(const Duration(milliseconds: 100));

        final result = await authNotifier.verifyOtp('123456');

        expect(result['success'], isFalse);
        expect(result['message'], equals('Phone number not set'));
      });
    });

    group('Sign Out', () {
      test('should sign out successfully', () async {
        authNotifier = AuthNotifier(mockAuthService);
        await Future.delayed(const Duration(milliseconds: 100));

        // First authenticate
        await authNotifier.sendOtp('+27821234567');
        await authNotifier.verifyOtp('123456');
        await Future.delayed(const Duration(milliseconds: 100));

        // Then sign out
        await authNotifier.signOut();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(authNotifier.state.isLoading, isFalse);
      });
    });

    group('Error Handling', () {
      test('should clear error', () async {
        mockAuthService.shouldFailOtp = true;
        authNotifier = AuthNotifier(mockAuthService);
        await Future.delayed(const Duration(milliseconds: 100));

        await authNotifier.sendOtp('+27821234567');
        expect(authNotifier.state.hasError, isTrue);

        authNotifier.clearError();
        expect(authNotifier.state.hasError, isFalse);
      });
    });

    group('Admin Role Verification', () {
      test('isAdmin returns true for Admin role', () {
        const state = AppAuthState(
          isAuthenticated: true,
          userRole: 'Admin',
        );
        expect(state.isAdmin, isTrue);
      });

      test('isAdmin returns false for non-Admin role', () {
        const state = AppAuthState(
          isAuthenticated: true,
          userRole: 'Driver',
        );
        expect(state.isAdmin, isFalse);
      });

      test('isAdmin returns false when role is null', () {
        const state = AppAuthState(isAuthenticated: true);
        expect(state.isAdmin, isFalse);
      });
    });
  });
}
