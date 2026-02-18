// lib/features/analytics/presentation/widgets/metric_card.dart

import 'package:flutter/material.dart';

/// A simple metric card displaying a single value with label
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isLoading;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.subtitle,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: iconColor ?? colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Value
              if (isLoading)
                Container(
                  height: 28,
                  width: 60,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              else
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),

              // Optional subtitle
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of metric cards for summary display
class MetricCardsRow extends StatelessWidget {
  final List<MetricCardData> metrics;
  final bool isLoading;

  const MetricCardsRow({
    super.key,
    required this.metrics,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: metrics
            .map((metric) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: MetricCard(
                      label: metric.label,
                      value: metric.value,
                      icon: metric.icon,
                      iconColor: metric.iconColor,
                      subtitle: metric.subtitle,
                      isLoading: isLoading,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// Data class for metric card
class MetricCardData {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final String? subtitle;

  const MetricCardData({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.subtitle,
  });
}

/// Chart container card with title and optional actions
class ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget chart;
  final Widget? trailing;
  final VoidCallback? onRefresh;
  final bool isLoading;
  final double height;

  const ChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.chart,
    this.trailing,
    this.onRefresh,
    this.isLoading = false,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (onRefresh != null)
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: colorScheme.primary,
                    ),
                    onPressed: isLoading ? null : onRefresh,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Chart
            SizedBox(
              height: height,
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : chart,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header with optional action
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Empty state widget for charts/data
class EmptyChartState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyChartState({
    super.key,
    this.message = 'No data available',
    this.icon = Icons.bar_chart_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
