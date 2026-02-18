// lib/features/auth/presentation/providers/auth_state.dart
// Exact copy from main LoadRunner app's AppAuthState

class AppAuthState {
  final bool isInitialized;
  final bool isAuthenticated;
  final bool isLoading;
  final String? userId;
  final String? phoneNumber;
  final String? userRole;
  final String? error;
  final bool isOtpSent; // Track OTP state
  final int resendCountdown; // Countdown timer

  const AppAuthState({
    this.isInitialized = false,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.userId,
    this.phoneNumber,
    this.userRole,
    this.error,
    this.isOtpSent = false,
    this.resendCountdown = 0,
  });

  AppAuthState copyWith({
    bool? isInitialized,
    bool? isAuthenticated,
    bool? isLoading,
    String? userId,
    String? phoneNumber,
    String? userRole,
    String? error,
    bool? isOtpSent,
    int? resendCountdown,
  }) {
    return AppAuthState(
      isInitialized: isInitialized ?? this.isInitialized,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userRole: userRole ?? this.userRole,
      error: error, // Pass null to clear error
      isOtpSent: isOtpSent ?? this.isOtpSent,
      resendCountdown: resendCountdown ?? this.resendCountdown,
    );
  }

  /// Check if user has Admin role
  bool get isAdmin => userRole == 'Admin';

  /// Check if there's an error
  bool get hasError => error != null && error!.isNotEmpty;

  /// Get user initials for avatar
  String get initials {
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      return 'A'; // Admin
    }
    return 'A';
  }

  @override
  String toString() {
    return 'AppAuthState(isInitialized: $isInitialized, isAuthenticated: $isAuthenticated, '
        'isLoading: $isLoading, userId: $userId, phoneNumber: $phoneNumber, userRole: $userRole, '
        'isOtpSent: $isOtpSent, hasError: $hasError)';
  }
}
