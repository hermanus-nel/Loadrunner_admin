// lib/features/analytics/presentation/widgets/ratings_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../domain/entities/performance_metrics.dart';

/// Horizontal bar chart showing ratings distribution
class RatingsBarChart extends StatelessWidget {
  final RatingsDistribution data;

  const RatingsBarChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.totalRatings == 0) {
      return const _EmptyChart(message: 'No ratings data');
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chartData = data.toChartData();

    // Find max count for scaling
    double maxX = 0;
    for (final item in chartData) {
      if (item.count > maxX) maxX = item.count.toDouble();
    }
    maxX = (maxX * 1.2).ceilToDouble();
    if (maxX == 0) maxX = 10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxX,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = chartData[4 - groupIndex]; // Reversed order
              final percentage = data.totalRatings > 0
                  ? ((item.count / data.totalRatings) * 100).toStringAsFixed(1)
                  : '0';
              return BarTooltipItem(
                '${item.stars} stars: ${item.count} ($percentage%)',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                final stars = 5 - value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$stars',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber.shade600,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  value.toInt().toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: false,
          verticalInterval: maxX / 4,
          getDrawingVerticalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: chartData.reversed.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item.count.toDouble(),
                width: 20,
                color: Color(item.color),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// Compact ratings summary with average and distribution
class RatingsSummary extends StatelessWidget {
  final RatingsDistribution data;
  final bool showDistribution;

  const RatingsSummary({
    super.key,
    required this.data,
    this.showDistribution = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average rating display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.averageRating.toStringAsFixed(1),
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final filled = index < data.averageRating.round();
                  return Icon(
                    filled ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber.shade600,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${data.totalRatings} ratings',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        if (showDistribution) ...[
          const SizedBox(width: 16),
          // Distribution bars
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: data.toChartData().map((item) {
                final percentage = data.totalRatings > 0
                    ? item.count / data.totalRatings
                    : 0.0;
                return _DistributionBar(
                  stars: item.stars,
                  count: item.count,
                  percentage: percentage,
                  color: Color(item.color),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final int stars;
  final int count;
  final double percentage;
  final Color color;

  const _DistributionBar({
    required this.stars,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Stars label
          SizedBox(
            width: 16,
            child: Text(
              '$stars',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.star,
            size: 12,
            color: Colors.amber.shade600,
          ),
          const SizedBox(width: 8),
          // Progress bar
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Count
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// Star rating indicator
class StarRating extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double size;
  final Color? filledColor;
  final Color? emptyColor;
  final bool showValue;

  const StarRating({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.size = 16,
    this.filledColor,
    this.emptyColor,
    this.showValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filled = filledColor ?? Colors.amber.shade600;
    final empty = emptyColor ?? colorScheme.outlineVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxStars, (index) {
          final starValue = index + 1;
          IconData icon;
          Color color;

          if (starValue <= rating) {
            icon = Icons.star;
            color = filled;
          } else if (starValue - 0.5 <= rating) {
            icon = Icons.star_half;
            color = filled;
          } else {
            icon = Icons.star_border;
            color = empty;
          }

          return Icon(icon, size: size, color: color);
        }),
        if (showValue) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Empty chart placeholder
class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({this.message = 'No data'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border_outlined,
            size: 40,
            color: colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
