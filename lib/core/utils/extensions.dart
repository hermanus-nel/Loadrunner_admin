import 'package:flutter/material.dart';

/// String extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Check if string is valid email
  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(this);
  }

  /// Check if string is valid phone number (SA format)
  bool get isValidPhoneNumber {
    final cleaned = replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^(\+27|0)[1-9][0-9]{8}$').hasMatch(cleaned);
  }

  /// Check if string contains only digits
  bool get isDigitsOnly {
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Convert to nullable int
  int? get toIntOrNull => int.tryParse(this);

  /// Convert to nullable double
  double? get toDoubleOrNull => double.tryParse(this);

  /// Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Check if string is not null or empty
  bool get isNotNullOrEmpty => isNotEmpty;
}

/// Nullable String extensions
extension NullableStringExtensions on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if string is not null or empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  /// Return default value if null or empty
  String orDefault(String defaultValue) {
    return isNullOrEmpty ? defaultValue : this!;
  }
}

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Check if date is in the future
  bool get isFuture => isAfter(DateTime.now());

  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Get start of month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Get end of month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// Add business days (excluding weekends)
  DateTime addBusinessDays(int days) {
    var result = this;
    var addedDays = 0;

    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.saturday &&
          result.weekday != DateTime.sunday) {
        addedDays++;
      }
    }

    return result;
  }

  /// Format as ISO 8601 date string
  String get toIsoDateString =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// Nullable DateTime extensions
extension NullableDateTimeExtensions on DateTime? {
  /// Check if date is null
  bool get isNull => this == null;

  /// Check if date is not null
  bool get isNotNull => this != null;

  /// Return epoch if null
  DateTime get orEpoch => this ?? DateTime.fromMillisecondsSinceEpoch(0);
}

/// Number extensions
extension NumberExtensions on num {
  /// Clamp value between min and max
  num clampValue(num min, num max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// Convert to duration in milliseconds
  Duration get milliseconds => Duration(milliseconds: toInt());

  /// Convert to duration in seconds
  Duration get seconds => Duration(seconds: toInt());

  /// Convert to duration in minutes
  Duration get minutes => Duration(minutes: toInt());

  /// Convert to duration in hours
  Duration get hours => Duration(hours: toInt());
}

/// List extensions
extension ListExtensions<T> on List<T> {
  /// Safe get element at index or null
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Safe get first element or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Safe get last element or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Separate list into chunks
  List<List<T>> chunked(int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += chunkSize) {
      final end = (i + chunkSize < length) ? i + chunkSize : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }
}

/// Map extensions
extension MapExtensions<K, V> on Map<K, V> {
  /// Safe get value or null
  V? getOrNull(K key) => containsKey(key) ? this[key] : null;

  /// Safe get value or default
  V getOrDefault(K key, V defaultValue) => containsKey(key) ? this[key]! : defaultValue;
}

/// BuildContext extensions
extension BuildContextExtensions on BuildContext {
  /// Get theme data
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Check if dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Get bottom padding (for keyboard)
  double get bottomPadding => MediaQuery.of(this).viewInsets.bottom;

  /// Show snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(message, isError: true);
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Pop with result
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  /// Check if can pop
  bool get canPop => Navigator.of(this).canPop();
}

/// Duration extensions
extension DurationExtensions on Duration {
  /// Format as "HH:MM:SS"
  String get formatted {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = (inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Format as "MM:SS"
  String get formattedShort {
    final minutes = inMinutes.toString().padLeft(2, '0');
    final seconds = (inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
