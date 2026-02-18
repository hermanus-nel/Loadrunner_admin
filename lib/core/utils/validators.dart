/// Utility class for form field validation
class Validators {
  Validators._();

  // ===========================================
  // REQUIRED VALIDATION
  // ===========================================

  /// Validate required field
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName is required' : 'This field is required';
    }
    return null;
  }

  // ===========================================
  // EMAIL VALIDATION
  // ===========================================

  /// Validate email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate optional email format
  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional, so empty is valid
    }
    return email(value);
  }

  // ===========================================
  // PHONE VALIDATION
  // ===========================================

  /// Validate South African phone number
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');

    // SA phone formats: 0XX XXX XXXX or +27XX XXX XXXX
    final saPhoneRegex = RegExp(r'^(\+27|0)[1-9][0-9]{8}$');

    if (!saPhoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // ===========================================
  // PASSWORD VALIDATION
  // ===========================================

  /// Validate password strength
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    return null;
  }

  /// Validate password confirmation matches
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ===========================================
  // LENGTH VALIDATION
  // ===========================================

  /// Validate minimum length
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.length < minLength) {
      final name = fieldName ?? 'This field';
      return '$name must be at least $minLength characters';
    }
    return null;
  }

  /// Validate maximum length
  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value != null && value.length > maxLength) {
      final name = fieldName ?? 'This field';
      return '$name must not exceed $maxLength characters';
    }
    return null;
  }

  /// Validate length range
  static String? lengthRange(
    String? value,
    int minLength,
    int maxLength, {
    String? fieldName,
  }) {
    final name = fieldName ?? 'This field';

    if (value == null || value.length < minLength) {
      return '$name must be at least $minLength characters';
    }

    if (value.length > maxLength) {
      return '$name must not exceed $maxLength characters';
    }

    return null;
  }

  // ===========================================
  // NUMBER VALIDATION
  // ===========================================

  /// Validate numeric value
  static String? numeric(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return null; // Use with required() for required fields
    }

    if (double.tryParse(value) == null) {
      final name = fieldName ?? 'This field';
      return '$name must be a valid number';
    }

    return null;
  }

  /// Validate positive number
  static String? positiveNumber(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final number = double.tryParse(value);
    if (number == null) {
      final name = fieldName ?? 'This field';
      return '$name must be a valid number';
    }

    if (number <= 0) {
      final name = fieldName ?? 'This field';
      return '$name must be a positive number';
    }

    return null;
  }

  /// Validate number range
  static String? numberRange(
    String? value,
    num min,
    num max, {
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final number = double.tryParse(value);
    if (number == null) {
      final name = fieldName ?? 'This field';
      return '$name must be a valid number';
    }

    if (number < min || number > max) {
      final name = fieldName ?? 'Value';
      return '$name must be between $min and $max';
    }

    return null;
  }

  // ===========================================
  // SOUTH AFRICAN ID VALIDATION
  // ===========================================

  /// Validate South African ID number
  static String? saIdNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ID number is required';
    }

    // Remove spaces
    final cleaned = value.replaceAll(' ', '');

    // Must be 13 digits
    if (cleaned.length != 13 || int.tryParse(cleaned) == null) {
      return 'ID number must be 13 digits';
    }

    // Validate using Luhn algorithm
    if (!_validateLuhn(cleaned)) {
      return 'Please enter a valid ID number';
    }

    // Validate date portion (YYMMDD)
    final year = int.parse(cleaned.substring(0, 2));
    final month = int.parse(cleaned.substring(2, 4));
    final day = int.parse(cleaned.substring(4, 6));

    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return 'Please enter a valid ID number';
    }

    return null;
  }

  /// Luhn algorithm validation
  static bool _validateLuhn(String number) {
    var sum = 0;
    var isDouble = false;

    for (var i = number.length - 1; i >= 0; i--) {
      var digit = int.parse(number[i]);

      if (isDouble) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }

      sum += digit;
      isDouble = !isDouble;
    }

    return sum % 10 == 0;
  }

  // ===========================================
  // BANK ACCOUNT VALIDATION
  // ===========================================

  /// Validate bank account number (basic validation)
  static String? bankAccountNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length < 7 || cleaned.length > 15) {
      return 'Please enter a valid account number';
    }

    return null;
  }

  // ===========================================
  // URL VALIDATION
  // ===========================================

  /// Validate URL format
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // ===========================================
  // COMPOSITE VALIDATORS
  // ===========================================

  /// Combine multiple validators
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
