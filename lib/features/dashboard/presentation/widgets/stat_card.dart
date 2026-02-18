// lib/features/dashboard/presentation/widgets/stat_card.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../domain/entities/dashboard_stats.dart';
import 'trend_indicator.dart';

/// Data class for stat card configuration
class StatCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final TrendIndicator? trend;
  final bool showSparkline;

  const StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.trend,
    this.showSparkline = false,
  });
}

/// A card widget displaying a single statistic with optional trend and sparkline
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  final TrendIndicator? trend;
  final bool showSparkline;
  final bool featured;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.isLoading = false,
    this.trend,
    this.showSparkline = false,
    this.featured = false,
  });

  factory StatCard.fromData(StatCardData data, {bool isLoading = false}) {
    return StatCard(
      title: data.title,
      value: data.value,
      icon: data.icon,
      color: data.color,
      onTap: data.onTap,
      trend: data.trend,
      showSparkline: data.showSparkline,
      isLoading: isLoading,
    );
  }

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
          color: isDark
              ? colorScheme.outlineVariant.withOpacity(0.3)
              : colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(isDark ? 0.15 : 0.08),
                color.withOpacity(isDark ? 0.05 : 0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row with icon and title
              Row(
                mainAxisAlignment: featured
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  // Icon container
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (featured)
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Value with inline trend percentage
              if (isLoading)
                _buildLoadingIndicator(colorScheme)
              else
                _buildValueWithTrend(theme, colorScheme),

              // Sparkline chart (if enabled and has data)
              if (showSparkline &&
                  trend != null &&
                  trend!.sparklineData.isNotEmpty &&
                  !isLoading) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: _SparklineChart(
                    data: trend!.sparklineData,
                    color: color,
                    isPositive: trend!.isPositive,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueWithTrend(ThemeData theme, ColorScheme colorScheme) {
    final isNeutral = trend == null || trend!.percentageChange == 0;

    final valueStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    );

    if (isNeutral) {
      return Text(value, style: valueStyle);
    }

    final percentColor = trend!.isPositive ? color : colorScheme.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: valueStyle),
        const SizedBox(width: 6),
        Text(
          '(${trend!.formattedPercentage})',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: percentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator(ColorScheme colorScheme) {
    return Container(
      height: 28,
      width: 60,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

/// Mini sparkline chart widget using fl_chart
class _SparklineChart extends StatelessWidget {
  final List<TrendDataPoint> data;
  final Color color;
  final bool isPositive;

  const _SparklineChart({
    required this.data,
    required this.color,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    // Calculate min and max for better scaling
    final values = data.map((d) => d.value).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    // When all values are identical (range == 0), use a minimum padding
    // so the chart has vertical space and the line renders centered
    final padding = range > 0
        ? range * 0.1
        : (maxY.abs() > 0 ? maxY.abs() * 0.1 : 1.0);

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color.withOpacity(0.8),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Only show dot on the last point
                if (index == data.length - 1) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: color,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of stat cards with responsive layout
class StatCardsGrid extends StatelessWidget {
  final List<StatCardData> cards;
  final bool isLoading;
  final int crossAxisCount;
  final double spacing;
  final double childAspectRatio;

  const StatCardsGrid({
    super.key,
    required this.cards,
    this.isLoading = false,
    this.crossAxisCount = 2,
    this.spacing = 12,
    this.childAspectRatio = 1.3,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return StatCard.fromData(cards[index], isLoading: isLoading);
      },
    );
  }
}

/// Enhanced stat card with larger sparkline for featured metrics
class FeaturedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final TrendIndicator? trend;
  final VoidCallback? onTap;
  final bool isLoading;

  const FeaturedStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
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
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(isDark ? 0.2 : 0.1),
                color.withOpacity(isDark ? 0.08 : 0.03),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(isDark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trend != null && !isLoading)
                    TrendBadge(trend: trend!, cardColor: color),
                ],
              ),
              const SizedBox(height: 20),

              // Value
              if (isLoading)
                Container(
                  height: 36,
                  width: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              else
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),

              // Sparkline
              if (trend != null &&
                  trend!.sparklineData.isNotEmpty &&
                  !isLoading) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 60,
                  child: _SparklineChart(
                    data: trend!.sparklineData,
                    color: color,
                    isPositive: trend!.isPositive,
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

/// Weekly stats summary card
class WeeklyStatsCard extends StatelessWidget {
  final WeeklyStats stats;
  final TrendIndicator? revenueTrend;
  final TrendIndicator? shipmentsTrend;
  final bool isLoading;

  const WeeklyStatsCard({
    super.key,
    required this.stats,
    this.revenueTrend,
    this.shipmentsTrend,
    this.isLoading = false,
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
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'This Week',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats grid
            Row(
              children: [
                // Completed Shipments
                Expanded(
                  child: _WeeklyStatItem(
                    label: 'Completed',
                    value: stats.completedShipments.toString(),
                    icon: Icons.local_shipping_outlined,
                    color: Colors.blue,
                    trend: shipmentsTrend,
                    isLoading: isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                // Revenue
                Expanded(
                  child: _WeeklyStatItem(
                    label: 'Revenue',
                    value: stats.formattedRevenue,
                    icon: Icons.attach_money,
                    color: Colors.green,
                    trend: revenueTrend,
                    isLoading: isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Avg Delivery Time
                Expanded(
                  child: _WeeklyStatItem(
                    label: 'Avg Delivery',
                    value: stats.formattedDeliveryTime,
                    icon: Icons.access_time,
                    color: Colors.orange,
                    isLoading: isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                // Driver Utilization
                Expanded(
                  child: _WeeklyStatItem(
                    label: 'Utilization',
                    value: stats.formattedUtilization,
                    icon: Icons.people_outline,
                    color: Colors.purple,
                    isLoading: isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final TrendIndicator? trend;
  final bool isLoading;

  const _WeeklyStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            Container(
              height: 20,
              width: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            )
          else
            _buildValueWithTrend(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildValueWithTrend(ThemeData theme, ColorScheme colorScheme) {
    final isNeutral = trend == null || trend!.percentageChange == 0;

    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    );

    if (isNeutral) {
      return Text(value, style: valueStyle);
    }

    final percentColor = trend!.isPositive ? color : colorScheme.error;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: valueStyle),
        const SizedBox(width: 4),
        Text(
          '(${trend!.formattedPercentage})',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: percentColor,
          ),
        ),
      ],
    );
  }
}
