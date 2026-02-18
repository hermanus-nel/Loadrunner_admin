// lib/features/auth/presentation/screens/signup_screen.dart
// Adapted from main LoadRunner app's SignupScreen
// Same OTP pattern, with admin branding

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String _selectedCountryCode = '+27';
  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initFromState();
  }

  void _initFromState() {
    // Initialize from auth state if available
    final authState = ref.read(authNotifierProvider);
    if (authState.phoneNumber != null) {
      _phoneController.text = _extractLocalNumber(authState.phoneNumber!);
      if (authState.phoneNumber!.startsWith('+')) {
        final countryCode = authState.phoneNumber!.substring(
          0,
          authState.phoneNumber!.length - _phoneController.text.length,
        );
        _selectedCountryCode = countryCode;
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // Extract local number from international format
  String _extractLocalNumber(String phoneNumber) {
    // Handle different country code formats
    for (final prefix in ['+27', '+1', '+44', '+91']) {
      if (phoneNumber.startsWith(prefix)) {
        return phoneNumber.substring(prefix.length);
      }
    }
    return phoneNumber;
  }

  /// Validate phone number format
  bool _isPhoneNumberValid(String phoneNumber) {
    final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^\d{7,15}$').hasMatch(cleanPhoneNumber);
  }

  /// Format phone number with country code
  String _formatPhoneNumber() {
    // If the controller is empty but we have stored phone number in state, use that
    final authState = ref.read(authNotifierProvider);
    if (_phoneController.text.isEmpty && authState.phoneNumber != null) {
      return authState.phoneNumber!;
    }

    String cleanPhoneNumber = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhoneNumber.startsWith('0')) {
      cleanPhoneNumber = cleanPhoneNumber.substring(1);
    }
    return '$_selectedCountryCode$cleanPhoneNumber';
  }

  /// Show snackbar for messages
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Start resend countdown timer
  void _startResendCountdown() {
    _resendCountdown = 60; // 60 seconds countdown
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// Send OTP verification code
  Future<void> _sendOtp() async {
    if (!_isPhoneNumberValid(_phoneController.text)) {
      _showSnackBar('Please enter a valid phone number.', isError: true);
      return;
    }

    final phoneNumber = _formatPhoneNumber();
    final authNotifier = ref.read(authNotifierProvider.notifier);

    // Set phone number in state immediately
    authNotifier.setPhoneNumber(phoneNumber);

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await authNotifier.sendOtp(phoneNumber);

      if (!mounted) return;

      if (!(result['success'] as bool)) {
        throw Exception(result['message'] ?? 'Failed to send OTP');
      }

      _showSnackBar('Verification code sent! Check your messages.');

      setState(() {
        _startResendCountdown();
      });
    } catch (e) {
      if (!mounted) return;

      final error = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = error;
      });
      _showSnackBar('Error: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Verify the OTP code
  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _otpController.text.length < 6) {
      _showSnackBar('Please enter a valid 6-digit verification code.', isError: true);
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final result = await authNotifier.verifyOtp(_otpController.text);

      if (!mounted) return;

      if (!(result['success'] as bool)) {
        throw Exception(result['message'] ?? 'Verification failed');
      }

      // Success - navigate to dashboard
      // The auth state listener will handle the navigation via GoRouter
      _showSnackBar('Admin login successful!');
      
      // Navigate to dashboard
      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      if (!mounted) return;

      final error = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = error;
      });
      _showSnackBar('Error: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Reset OTP state
  void _resetOtpState() {
    _countdownTimer?.cancel();

    // Reset global state
    final authNotifier = ref.read(authNotifierProvider.notifier);
    authNotifier.resetOtpState();

    if (mounted) {
      setState(() {
        _otpController.clear();
        _errorMessage = null;
        _resendCountdown = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isOtpSent = authState.isOtpSent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  
                  // Logo / Icon
                  Image.asset(
                    isDark ? 'assets/images/logo_d.png' : 'assets/images/logo_l.png',
                    height: 300,
                  ),
                  const SizedBox(height: 24),
                  
                 
                  // Subtitle
                  Text(
                    'Administrator Access Only',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phone number input section
                  if (!isOtpSent) ...[
                    const Text(
                      'Enter your phone number to receive a verification code',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),

                    // Country code and phone number input
                    Row(
                      children: [
                        // Country code picker
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CountryCodePicker(
                            onChanged: (code) {
                              if (mounted) {
                                setState(() {
                                  _selectedCountryCode = code.dialCode ?? '+27';
                                });
                              }
                            },
                            initialSelection: 'ZA',
                            favorite: const ['+27', '+1', '+44'],
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                            alignLeft: false,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Phone number input
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Phone number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Send OTP button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Send Verification Code'),
                      ),
                    ),
                  ],

                  // OTP verification section
                  if (isOtpSent) ...[
                    Text(
                      'Enter the verification code sent to\n${authState.phoneNumber ?? _formatPhoneNumber()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),

                    // OTP input
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '000000',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Verify OTP button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Verify Code'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resend OTP button with countdown
                    TextButton(
                      onPressed: (_isLoading || _resendCountdown > 0) ? null : _sendOtp,
                      child: Text(
                        _resendCountdown > 0
                            ? 'Resend code in ${_resendCountdown ~/ 60}:${(_resendCountdown % 60).toString().padLeft(2, '0')}'
                            : 'Resend verification code',
                      ),
                    ),

                    // Change phone number button
                    TextButton(
                      onPressed: _isLoading ? null : _resetOtpState,
                      child: const Text('Change phone number'),
                    ),
                  ],

                  const SizedBox(height: 32),
                  
                  // Admin notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Only users with Admin role can access this app.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Version
                  Text(
                    'Version 1.0.0',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
