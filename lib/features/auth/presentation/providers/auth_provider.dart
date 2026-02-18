// lib/features/auth/presentation/providers/auth_provider.dart
// Exact copy from main LoadRunner app's auth_provider.dart
// Uses core_providers for SessionService and BulkSmsService

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/core_providers.dart';
import '../../data/services/auth_service.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

// ============================================================
// AUTH SERVICE PROVIDER
// ============================================================

/// Auth service provider
/// Uses sessionServiceProvider and bulkSmsServiceProvider from core_providers.dart
final authServiceProvider = Provider<AuthService>((ref) {
  final sessionService = ref.read(sessionServiceProvider);
  final bulkSmsService = ref.read(bulkSmsServiceProvider);

  return AuthService(
    sessionService: sessionService,
    bulkSmsService: bulkSmsService,
  );
});

// ============================================================
// AUTH NOTIFIER PROVIDER
// ============================================================

/// Auth notifier provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});

// ============================================================
// CONVENIENCE PROVIDERS
// ============================================================

/// Provider for checking if user is authenticated
final isUserAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isAuthenticated;
});

/// Provider for checking if auth is initialized
final isAuthInitializedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isInitialized;
});

/// Provider for checking if auth is loading
final isAuthLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isLoading;
});

/// Provider for current user ID
final authUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.userId;
});

/// Provider for current user phone number
final authUserPhoneProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.phoneNumber;
});

/// Provider for current user role
final authUserRoleProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.userRole;
});

/// Provider for auth error message
final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.error;
});

/// Provider for checking if user is admin
final isAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isAdmin;
});

/// Provider for OTP sent state
final isOtpSentProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isOtpSent;
});
