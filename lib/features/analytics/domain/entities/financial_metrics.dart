// lib/features/analytics/domain/entities/financial_metrics.dart

import 'package:flutter/foundation.dart';

/// Payment breakdown by status
@immutable
class PaymentsByStatus {
  final double pending;
  final double completed;
  final double failed;
  final double refunded;

  const PaymentsByStatus({
    this.pending = 0,
    this.completed = 0,
    this.failed = 0,
    this.refunded = 0,
  });

  double get total => pending + completed + failed + refunded;

  factory PaymentsByStatus.fromJson(Map<String, dynamic> json) {
    return PaymentsByStatus(
      pending: (json['pending'] as num?)?.toDouble() ?? 0,
      completed: (json['completed'] as num?)?.toDouble() ?? 0,
      failed: (json['failed'] as num?)?.toDouble() ?? 0,
      refunded: (json['refunded'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'pending': pending,
        'completed': completed,
        'failed': failed,
        'refunded': refunded,
      };

  /// Convert to pie chart data
  List<PaymentChartData> toPieChartData() => [
        PaymentChartData(
          label: 'Completed',
          value: completed,
          color: 0xFF4CAF50,
          percentage: total > 0 ? (completed / total) * 100 : 0,
        ),
        PaymentChartData(
          label: 'Pending',
          value: pending,
          color: 0xFFFF9800,
          percentage: total > 0 ? (pending / total) * 100 : 0,
        ),
        PaymentChartData(
          label: 'Failed',
          value: failed,
          color: 0xFFF44336,
          percentage: total > 0 ? (failed / total) * 100 : 0,
        ),
        PaymentChartData(
          label: 'Refunded',
          value: refunded,
          color: 0xFF9C27B0,
          percentage: total > 0 ? (refunded / total) * 100 : 0,
        ),
      ].where((item) => item.value > 0).toList();
}

/// Payment chart data point
@immutable
class PaymentChartData {
  final String label;
  final double value;
  final int color;
  final double percentage;

  const PaymentChartData({
    required this.label,
    required this.value,
    required this.color,
    required this.percentage,
  });
}

/// Daily revenue data point
@immutable
class DailyRevenue {
  final DateTime date;
  final double revenue;
  final double commission;
  final int transactionCount;

  const DailyRevenue({
    required this.date,
    this.revenue = 0,
    this.commission = 0,
    this.transactionCount = 0,
  });

  factory DailyRevenue.fromJson(Map<String, dynamic> json) {
    return DailyRevenue(
      date: DateTime.parse(json['date'] as String),
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0,
      transactionCount: json['transaction_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'revenue': revenue,
        'commission': commission,
        'transaction_count': transactionCount,
      };
}

/// Revenue summary stats
@immutable
class RevenueSummary {
  final double totalRevenue;
  final double totalCommission;
  final double averageTransactionValue;
  final int totalTransactions;
  final double revenueGrowth; // percentage
  final double todayRevenue;
  final double thisWeekRevenue;
  final double thisMonthRevenue;

  const RevenueSummary({
    this.totalRevenue = 0,
    this.totalCommission = 0,
    this.averageTransactionValue = 0,
    this.totalTransactions = 0,
    this.revenueGrowth = 0,
    this.todayRevenue = 0,
    this.thisWeekRevenue = 0,
    this.thisMonthRevenue = 0,
  });

  factory RevenueSummary.fromJson(Map<String, dynamic> json) {
    return RevenueSummary(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      totalCommission: (json['total_commission'] as num?)?.toDouble() ?? 0,
      averageTransactionValue:
          (json['average_transaction_value'] as num?)?.toDouble() ?? 0,
      totalTransactions: json['total_transactions'] as int? ?? 0,
      revenueGrowth: (json['revenue_growth'] as num?)?.toDouble() ?? 0,
      todayRevenue: (json['today_revenue'] as num?)?.toDouble() ?? 0,
      thisWeekRevenue: (json['this_week_revenue'] as num?)?.toDouble() ?? 0,
      thisMonthRevenue: (json['this_month_revenue'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_revenue': totalRevenue,
        'total_commission': totalCommission,
        'average_transaction_value': averageTransactionValue,
        'total_transactions': totalTransactions,
        'revenue_growth': revenueGrowth,
        'today_revenue': todayRevenue,
        'this_week_revenue': thisWeekRevenue,
        'this_month_revenue': thisMonthRevenue,
      };

  /// Format amount as ZAR
  String formatAmount(double amount) {
    if (amount >= 1000000) {
      return 'R${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'R${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'R${amount.toStringAsFixed(0)}';
  }
}

/// Top earner data
@immutable
class TopEarner {
  final String id;
  final String name;
  final String type; // 'driver' or 'shipper'
  final double totalEarnings;
  final int completedShipments;
  final double averageRating;

  const TopEarner({
    required this.id,
    required this.name,
    required this.type,
    this.totalEarnings = 0,
    this.completedShipments = 0,
    this.averageRating = 0,
  });

  factory TopEarner.fromJson(Map<String, dynamic> json) {
    return TopEarner(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? 'driver',
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0,
      completedShipments: json['completed_shipments'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'total_earnings': totalEarnings,
        'completed_shipments': completedShipments,
        'average_rating': averageRating,
      };
}

/// Complete financial metrics
@immutable
class FinancialMetrics {
  final RevenueSummary revenueSummary;
  final PaymentsByStatus paymentsByStatus;
  final List<DailyRevenue> dailyRevenue;
  final List<TopEarner> topDrivers;
  final List<TopEarner> topShippers;
  final double paymentSuccessRate;
  final int failedPaymentsCount;
  final double outstandingPayments;

  const FinancialMetrics({
    required this.revenueSummary,
    required this.paymentsByStatus,
    required this.dailyRevenue,
    required this.topDrivers,
    required this.topShippers,
    this.paymentSuccessRate = 0,
    this.failedPaymentsCount = 0,
    this.outstandingPayments = 0,
  });

  factory FinancialMetrics.empty() => FinancialMetrics(
        revenueSummary: const RevenueSummary(),
        paymentsByStatus: const PaymentsByStatus(),
        dailyRevenue: const [],
        topDrivers: const [],
        topShippers: const [],
      );

  factory FinancialMetrics.fromJson(Map<String, dynamic> json) {
    return FinancialMetrics(
      revenueSummary: json['revenue_summary'] != null
          ? RevenueSummary.fromJson(
              json['revenue_summary'] as Map<String, dynamic>)
          : const RevenueSummary(),
      paymentsByStatus: json['payments_by_status'] != null
          ? PaymentsByStatus.fromJson(
              json['payments_by_status'] as Map<String, dynamic>)
          : const PaymentsByStatus(),
      dailyRevenue: (json['daily_revenue'] as List<dynamic>?)
              ?.map((e) => DailyRevenue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topDrivers: (json['top_drivers'] as List<dynamic>?)
              ?.map((e) => TopEarner.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topShippers: (json['top_shippers'] as List<dynamic>?)
              ?.map((e) => TopEarner.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      paymentSuccessRate:
          (json['payment_success_rate'] as num?)?.toDouble() ?? 0,
      failedPaymentsCount: json['failed_payments_count'] as int? ?? 0,
      outstandingPayments:
          (json['outstanding_payments'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'revenue_summary': revenueSummary.toJson(),
        'payments_by_status': paymentsByStatus.toJson(),
        'daily_revenue': dailyRevenue.map((e) => e.toJson()).toList(),
        'top_drivers': topDrivers.map((e) => e.toJson()).toList(),
        'top_shippers': topShippers.map((e) => e.toJson()).toList(),
        'payment_success_rate': paymentSuccessRate,
        'failed_payments_count': failedPaymentsCount,
        'outstanding_payments': outstandingPayments,
      };
}
