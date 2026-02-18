// lib/core/services/core_providers.dart
// Adapted from main LoadRunner app's core_providers.dart
// Compatible with existing LoadRunner implementation + Lifecycle Management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_service.dart';
import 'supabase_provider.dart';
import 'jwt_recovery_handler.dart';
import 'bulksms_service.dart';
import 'connectivity_service.dart';
import 'storage_service.dart';
import 'fcm_service.dart';

// ============================================================
// SESSION SERVICE PROVIDER
// ============================================================

/// Provider for SessionService
/// This is overridden in main.dart with the actual instance
final sessionServiceProvider = Provider<SessionService>((ref) {
  throw UnimplementedError(
    'SessionService must be overridden in main.dart'
  );
});

// ============================================================
// BULKSMS SERVICE PROVIDER
// ============================================================

/// Provider for BulkSmsService
/// This is overridden in main.dart with the actual instance
final bulkSmsServiceProvider = Provider<BulkSmsService>((ref) {
  throw UnimplementedError(
    'BulkSmsService must be overridden in main.dart'
  );
});

// ============================================================
// SUPABASE PROVIDER
// ============================================================

/// Provider for the SupabaseProvider singleton
/// This is the core provider that should be used throughout the app
/// for accessing the Supabase client instance.
final supabaseProviderInstance = Provider<SupabaseProvider>((ref) {
  final provider = SupabaseProvider();
  if (!provider.isInitialized) {
    provider.initialize();
  }
  return provider;
});

// ============================================================
// JWT RECOVERY HANDLER PROVIDER
// ============================================================

/// Provider for JwtRecoveryHandler
/// This is overridden in main.dart with the actual initialized instance
final jwtRecoveryHandlerProvider = Provider<JwtRecoveryHandler>((ref) {
  throw UnimplementedError(
    'JwtRecoveryHandler must be overridden in main.dart'
  );
});

// ============================================================
// CONNECTIVITY PROVIDER
// ============================================================

/// Provider for ConnectivityService singleton
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

/// Stream provider for connectivity status
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.instance.connectivityStream;
});

/// Provider for current connectivity state
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityStatusProvider);
  return connectivityAsync.when(
    data: (isConnected) => isConnected,
    loading: () => ConnectivityService.instance.isConnected,
    error: (_, __) => ConnectivityService.instance.isConnected,
  );
});

// ============================================================
// FCM SERVICE PROVIDER
// ============================================================

/// Provider for FcmService singleton
final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService.instance;
});

// ============================================================
// STORAGE PROVIDER
// ============================================================

/// Provider for StorageService singleton
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

// ============================================================
// AUTH STATE PROVIDERS (convenience)
// ============================================================

/// Provider for authentication state stream
final authStateStreamProvider = StreamProvider<bool>((ref) {
  final sessionService = ref.watch(sessionServiceProvider);
  return sessionService.authStateChanges;
});

/// Provider for current authentication state
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authStateAsync = ref.watch(authStateStreamProvider);
  return authStateAsync.when(
    data: (isAuthenticated) => isAuthenticated,
    loading: () {
      try {
        final sessionService = ref.read(sessionServiceProvider);
        return sessionService.isAuthenticated;
      } catch (_) {
        return false;
      }
    },
    error: (_, __) => false,
  );
});

/// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) return null;

  try {
    final sessionService = ref.read(sessionServiceProvider);
    return sessionService.userId;
  } catch (_) {
    return null;
  }
});

/// Provider for current user phone
final currentUserPhoneProvider = Provider<String?>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) return null;

  try {
    final sessionService = ref.read(sessionServiceProvider);
    return sessionService.userPhone;
  } catch (_) {
    return null;
  }
});
