import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Utility class for formatting dates, times, currency, etc.
class Formatters {
  Formatters._();

  // ===========================================
  // DATE & TIME FORMATTERS
  // ===========================================

  /// Format date as "15 Jan 2026"
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format date as "15/01/2026"
  static String formatDateShort(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format time as "14:30"
  static String formatTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('HH:mm').format(date);
  }

  /// Format date and time as "15 Jan 2026, 14:30"
  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  /// Format as relative time "2 hours ago", "yesterday", etc.
  static String formatRelativeTime(DateTime? date) {
    if (date == null) return '-';
    return timeago.format(date);
  }

  /// Format as relative time with short format "2h", "1d", etc.
  static String formatRelativeTimeShort(DateTime? date) {
    if (date == null) return '-';
    return timeago.format(date, locale: 'en_short');
  }

  /// Format date for API (ISO 8601)
  static String formatDateForApi(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  /// Parse date from API (ISO 8601)
  static DateTime? parseDateFromApi(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    return DateTime.tryParse(dateString)?.toLocal();
  }

  // ===========================================
  // CURRENCY FORMATTERS
  // ===========================================

  /// Format currency as "R 1,234.56"
  static String formatCurrency(num? amount, {String currency = 'ZAR'}) {
    if (amount == null) return '-';

    final symbol = _getCurrencySymbol(currency);
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );

    return formatter.format(amount);
  }

  /// Format currency without decimals "R 1,235"
  static String formatCurrencyWhole(num? amount, {String currency = 'ZAR'}) {
    if (amount == null) return '-';

    final symbol = _getCurrencySymbol(currency);
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 0,
    );

    return formatter.format(amount);
  }

  /// Format as compact currency "R 1.2K", "R 1.5M"
  static String formatCurrencyCompact(num? amount, {String currency = 'ZAR'}) {
    if (amount == null) return '-';

    final symbol = _getCurrencySymbol(currency);
    final formatter = NumberFormat.compactCurrency(
      symbol: symbol,
      decimalDigits: 1,
    );

    return formatter.format(amount);
  }

  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'ZAR':
        return 'R ';
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '$currency ';
    }
  }

  // ===========================================
  // NUMBER FORMATTERS
  // ===========================================

  /// Format number with thousand separators "1,234,567"
  static String formatNumber(num? number) {
    if (number == null) return '-';
    return NumberFormat('#,###').format(number);
  }

  /// Format as compact number "1.2K", "1.5M"
  static String formatNumberCompact(num? number) {
    if (number == null) return '-';
    return NumberFormat.compact().format(number);
  }

  /// Format percentage "85.5%"
  static String formatPercentage(num? value, {int decimals = 1}) {
    if (value == null) return '-';
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format decimal "1.23"
  static String formatDecimal(num? value, {int decimals = 2}) {
    if (value == null) return '-';
    return value.toStringAsFixed(decimals);
  }

  // ===========================================
  // PHONE NUMBER FORMATTERS
  // ===========================================

  /// Format South African phone number
  static String formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '-';

    // Remove any non-digit characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    // Format SA number
    if (digits.length == 10 && digits.startsWith('0')) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }

    if (digits.length == 11 && digits.startsWith('27')) {
      return '+27 ${digits.substring(2, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    }

    if (digits.length == 12 && digits.startsWith('270')) {
      return '+27 ${digits.substring(3, 5)} ${digits.substring(5, 8)} ${digits.substring(8)}';
    }

    // Return original if can't format
    return phone;
  }

  /// Mask phone number for privacy "081 *** **34"
  static String maskPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '-';

    final formatted = formatPhoneNumber(phone);
    if (formatted.length < 8) return formatted;

    return '${formatted.substring(0, 4)} *** **${formatted.substring(formatted.length - 2)}';
  }

  // ===========================================
  // FILE SIZE FORMATTERS
  // ===========================================

  /// Format file size in bytes to human readable
  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    var size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${suffixes[i]}';
  }

  // ===========================================
  // NAME FORMATTERS
  // ===========================================

  /// Format full name from first and last name
  static String formatFullName(String? firstName, String? lastName) {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';

    if (first.isEmpty && last.isEmpty) return '-';
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;

    return '$first $last';
  }

  /// Get initials from name "JD" from "John Doe"
  static String getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';

    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();

    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // ===========================================
  // DISTANCE FORMATTERS
  // ===========================================

  /// Format distance in kilometers
  static String formatDistance(num? km) {
    if (km == null) return '-';

    if (km < 1) {
      return '${(km * 1000).round()} m';
    }

    return '${km.toStringAsFixed(1)} km';
  }

  // ===========================================
  // DURATION FORMATTERS
  // ===========================================

  /// Format duration in minutes to human readable
  static String formatDuration(int? minutes) {
    if (minutes == null || minutes <= 0) return '-';

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (mins == 0) {
      return '$hours hr';
    }

    return '$hours hr $mins min';
  }
}
