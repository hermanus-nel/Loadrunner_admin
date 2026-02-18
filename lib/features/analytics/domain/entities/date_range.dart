// lib/features/analytics/domain/entities/date_range.dart

import 'package:flutter/foundation.dart';

/// Preset date range options
enum DateRangePreset {
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  lastMonth,
  thisQuarter,
  thisYear,
  custom,
}

extension DateRangePresetExtension on DateRangePreset {
  String get label {
    switch (this) {
      case DateRangePreset.today:
        return 'Today';
      case DateRangePreset.yesterday:
        return 'Yesterday';
      case DateRangePreset.last7Days:
        return 'Last 7 Days';
      case DateRangePreset.last30Days:
        return 'Last 30 Days';
      case DateRangePreset.thisMonth:
        return 'This Month';
      case DateRangePreset.lastMonth:
        return 'Last Month';
      case DateRangePreset.thisQuarter:
        return 'This Quarter';
      case DateRangePreset.thisYear:
        return 'This Year';
      case DateRangePreset.custom:
        return 'Custom Range';
    }
  }

  DateRange toDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case DateRangePreset.today:
        return DateRange(
          startDate: today,
          endDate: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
          preset: this,
        );
      case DateRangePreset.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateRange(
          startDate: yesterday,
          endDate: today.subtract(const Duration(seconds: 1)),
          preset: this,
        );
      case DateRangePreset.last7Days:
        return DateRange(
          startDate: today.subtract(const Duration(days: 6)),
          endDate: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
          preset: this,
        );
      case DateRangePreset.last30Days:
        return DateRange(
          startDate: today.subtract(const Duration(days: 29)),
          endDate: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
          preset: this,
        );
      case DateRangePreset.thisMonth:
        final firstOfMonth = DateTime(now.year, now.month, 1);
        return DateRange(
          startDate: firstOfMonth,
          endDate: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
          preset: this,
        );
      case DateRangePreset.lastMonth:
        final firstOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final lastOfLastMonth = DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1));
        return DateRange(
          startDate: firstOfLastMonth,
          endDate: lastOfLastMonth,
          preset: this,
        );
      case DateRangePreset.thisQuarter:
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        final firstOfQuarter = DateTime(now.year, quarterStartMonth, 1);
        return DateRange(
          startDate: firstOfQuarter,
          endDate: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
          preset: this,
        );
      case DateRangePreset.thisYear:
        final firstOfYear = DateTime(now.year, 1, 1);
        return DateRange(
          startDate: firstOfYear,
          endDate: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
          preset: this,
        );
      case DateRangePreset.custom:
        // Default to last 7 days for custom
        return DateRange(
          startDate: today.subtract(const Duration(days: 6)),
          endDate: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
          preset: this,
        );
    }
  }
}

/// Date range for analytics queries
@immutable
class DateRange {
  final DateTime startDate;
  final DateTime endDate;
  final DateRangePreset preset;

  const DateRange({
    required this.startDate,
    required this.endDate,
    this.preset = DateRangePreset.custom,
  });

  factory DateRange.last7Days() => DateRangePreset.last7Days.toDateRange();
  factory DateRange.last30Days() => DateRangePreset.last30Days.toDateRange();
  factory DateRange.thisMonth() => DateRangePreset.thisMonth.toDateRange();

  /// Number of days in this range
  int get dayCount => endDate.difference(startDate).inDays + 1;

  /// Check if this is a single day range
  bool get isSingleDay =>
      startDate.year == endDate.year &&
      startDate.month == endDate.month &&
      startDate.day == endDate.day;

  /// Format range for display
  String get displayText {
    if (preset != DateRangePreset.custom) {
      return preset.label;
    }

    final startStr = _formatDate(startDate);
    final endStr = _formatDate(endDate);

    if (isSingleDay) {
      return startStr;
    }
    return '$startStr - $endStr';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Create new range with different dates
  DateRange copyWith({
    DateTime? startDate,
    DateTime? endDate,
    DateRangePreset? preset,
  }) {
    return DateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      preset: preset ?? DateRangePreset.custom,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}
