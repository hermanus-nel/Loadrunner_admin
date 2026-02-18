// lib/features/sms_usage/presentation/widgets/sms_usage_chart.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/repositories/sms_usage_repository.dart';

/// Bar chart showing daily SMS usage over time
class SmsUsageChart extends StatelessWidget {
  final List<DailyUsage> dailyUsage;

  const SmsUsageChart({super.key, required this.dailyUsage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (dailyUsage.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No usage data available',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    final maxCount = dailyUsage.fold<int>(
      0,
      (max, d) => d.count > max ? d.count : max,
    );
    final effectiveMax = maxCount == 0 ? 1 : maxCount;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily SMS Volume',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // Legend
          Row(
            children: [
              _LegendItem(color: Colors.green.shade400, label: 'Delivered'),
              const SizedBox(width: 16),
              _LegendItem(color: Colors.red.shade400, label: 'Failed'),
              const SizedBox(width: 16),
              _LegendItem(color: Colors.orange.shade300, label: 'Other'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-axis labels
                SizedBox(
                  width: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$effectiveMax',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${(effectiveMax / 2).round()}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '0',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Bars
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = math.min(
                        (constraints.maxWidth / dailyUsage.length) - 2,
                        24.0,
                      );
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: dailyUsage.map((day) {
                          final totalHeight =
                              (day.count / effectiveMax) * constraints.maxHeight;
                          final deliveredHeight = day.count > 0
                              ? (day.delivered / day.count) * totalHeight
                              : 0.0;
                          final failedHeight = day.count > 0
                              ? (day.failed / day.count) * totalHeight
                              : 0.0;
                          final otherHeight =
                              totalHeight - deliveredHeight - failedHeight;

                          return Tooltip(
                            message:
                                '${day.date.day}/${day.date.month}: ${day.count} total\n'
                                '${day.delivered} delivered, ${day.failed} failed',
                            child: SizedBox(
                              width: math.max(barWidth, 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (otherHeight > 0)
                                    Container(
                                      height: otherHeight,
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade300,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(
                                              deliveredHeight == 0 &&
                                                      failedHeight == 0
                                                  ? 3
                                                  : 0),
                                          topRight: Radius.circular(
                                              deliveredHeight == 0 &&
                                                      failedHeight == 0
                                                  ? 3
                                                  : 0),
                                        ),
                                      ),
                                    ),
                                  if (failedHeight > 0)
                                    Container(
                                      height: failedHeight,
                                      color: Colors.red.shade400,
                                    ),
                                  if (deliveredHeight > 0)
                                    Container(
                                      height: deliveredHeight,
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade400,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(3),
                                          topRight: Radius.circular(3),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // X-axis labels (show first, middle, last)
          if (dailyUsage.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${dailyUsage.first.date.day}/${dailyUsage.first.date.month}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${dailyUsage.last.date.day}/${dailyUsage.last.date.month}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}

/// Cost breakdown card showing cost by SMS type
class CostBreakdownCard extends StatelessWidget {
  final SmsUsageStats stats;

  const CostBreakdownCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (stats.costByType.isEmpty) {
      return const SizedBox.shrink();
    }

    final typeColors = {
      'otp': Colors.purple,
      'notification': Colors.blue,
      'broadcast': Colors.orange,
      'custom': Colors.teal,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cost Breakdown',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...stats.costByType.entries.map((entry) {
            final type = SmsType.fromString(entry.key);
            final color = typeColors[entry.key] ?? Colors.grey;
            final percentage = stats.totalCost > 0
                ? (entry.value / stats.totalCost * 100)
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      type.displayName,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    'R ${entry.value.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Overview stat cards row
class UsageOverviewCards extends StatelessWidget {
  final SmsUsageStats stats;

  const UsageOverviewCards({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(
            icon: Icons.send,
            value: '${stats.totalSent}',
            label: 'Total Sent',
            color: Colors.blue,
          ),
          _StatColumn(
            icon: Icons.check_circle,
            value: '${stats.totalDelivered}',
            label: 'Delivered',
            color: Colors.green,
          ),
          _StatColumn(
            icon: Icons.error,
            value: '${stats.totalFailed}',
            label: 'Failed',
            color: Colors.red,
          ),
          _StatColumn(
            icon: Icons.attach_money,
            value: 'R${stats.totalCost.toStringAsFixed(0)}',
            label: 'Total Cost',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
