// lib/features/auth/presentation/providers/auth_notifier.dart
// Exact copy from main LoadRunner app's AuthNotifier
// Same pattern, with admin role verification

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AppAuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AppAuthState(isInitialized: false)) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Check if the user is already authenticated
      final isAuthenticated = _authService.isAuthenticated;
      String? userRole;

      if (isAuthenticated) {
        userRole = await _authService.getUserRole();

        // Verify admin role
        if (userRole != 'Admin') {
          debugPrint('AuthNotifier: User is not admin, signing out');
          await _authService.signOut();
          state = state.copyWith(
            isInitialized: true,
            isAuthenticated: false,
            isLoading: false,
            error: 'Access denied. Admin privileges required.',
          );
          return;
        }
      }

      // Set last used phone number if available
      final storedPhone = await _authService.getStoredPhoneNumber();

      state = state.copyWith(
        isInitialized: true,
        isAuthenticated: isAuthenticated,
        userId: _authService.userId,
        phoneNumber: storedPhone ?? _authService.userPhone,
        userRole: userRole,
        isLoading: false,
      );

      // Listen to auth state changes
      _authService.authStateChanges.listen(_onAuthStateChanged);
    } catch (e) {
      debugPrint('AuthNotifier: Error initializing: $e');
      state = state.copyWith(
        isInitialized: true,
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void _onAuthStateChanged(bool isAuthenticated) async {
    debugPrint('AuthNotifier: Auth state changed, isAuthenticated: $isAuthenticated');

    if (isAuthenticated) {
      try {
        final userRole = await _authService.getUserRole();
        debugPrint('AuthNotifier: User authenticated with role: $userRole');

        // Verify admin role
        if (userRole != 'Admin') {
          debugPrint('AuthNotifier: User is not admin');
          await _authService.signOut();
          state = state.copyWith(
            isAuthenticated: false,
            userId: null,
            userRole: null,
            error: 'Access denied. Admin privileges required.',
          );
          return;
        }

        state = state.copyWith(
          isAuthenticated: true,
          userId: _authService.userId,
          phoneNumber: _authService.userPhone,
          userRole: userRole,
        );
      } catch (e) {
        debugPrint('AuthNotifier: Error getting user role: $e');
        // Still mark as authenticated even if we can't get the role
        state = state.copyWith(
          isAuthenticated: true,
          userId: _authService.userId,
          phoneNumber: _authService.userPhone,
        );
      }
    } else {
      debugPrint('AuthNotifier: User not authenticated');
      state = state.copyWith(
        isAuthenticated: false,
        userId: null,
        userRole: null,
      );
    }
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    debugPrint('AuthNotifier: Refreshing user data...');

    if (!_authService.isAuthenticated) {
      debugPrint('AuthNotifier: User not authenticated, cannot refresh data');
      return;
    }

    try {
      final userRole = await _authService.getUserRole();
      debugPrint('AuthNotifier: Refreshed user role: $userRole');

      state = state.copyWith(
        userId: _authService.userId,
        phoneNumber: _authService.userPhone,
        userRole: userRole,
      );

      debugPrint('AuthNotifier: User data refreshed successfully');
    } catch (e) {
      debugPrint('AuthNotifier: Error refreshing user data: $e');
      // Don't update error state for refresh operations
    }
  }

  /// Update user role directly (for immediate updates)
  void updateUserRole(String newRole) {
    debugPrint('AuthNotifier: Updating user role to: $newRole');
    state = state.copyWith(userRole: newRole);
  }

  /// Set phone number
  void setPhoneNumber(String phoneNumber) {
    debugPrint('AuthNotifier: Setting phoneNumber to $phoneNumber');
    state = state.copyWith(phoneNumber: phoneNumber);
  }

  /// Send OTP
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    debugPrint('AuthNotifier: Sending OTP to $phoneNumber');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.sendOTP(phoneNumber);

      if (result['success'] as bool) {
        debugPrint('AuthNotifier: OTP sent successfully');
        state = state.copyWith(
          isLoading: false,
          phoneNumber: phoneNumber,
          isOtpSent: true, // Set this to true when OTP is sent successfully
        );
      } else {
        debugPrint('AuthNotifier: OTP sending failed: ${result['message']}');
        state = state.copyWith(
          isLoading: false,
          error: result['message'] as String?,
        );
      }

      return result;
    } catch (e) {
      debugPrint('AuthNotifier: Error sending OTP: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return {
        'success': false,
        'message': 'Failed to send OTP: $e',
      };
    }
  }

  /// Reset OTP state
  void resetOtpState() {
    state = state.copyWith(isOtpSent: false);
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String otp) async {
    if (state.phoneNumber == null) {
      return {
        'success': false,
        'message': 'Phone number not set',
      };
    }

    debugPrint('AuthNotifier: Verifying OTP for ${state.phoneNumber}: $otp');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.verifyOTP(state.phoneNumber!, otp);

      if (result['success'] as bool) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userId: result['userId'] as String?,
          userRole: result['userRole'] as String?,
        );
      } else {
        debugPrint('AuthNotifier: OTP verification failed: ${result['message']}');
        state = state.copyWith(
          isLoading: false,
          error: result['message'] as String?,
        );
      }

      return result;
    } catch (e) {
      debugPrint('AuthNotifier: Error verifying OTP: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return {
        'success': false,
        'message': 'Failed to verify OTP: $e',
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.signOut();
      // Auth state listener will handle the rest
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('AuthNotifier: Error signing out: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(error: null);
    }
  }
}
