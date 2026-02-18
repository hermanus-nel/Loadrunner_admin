// lib/features/dashboard/presentation/widgets/trend_indicator.dart

import 'package:flutter/material.dart';

import '../../domain/entities/dashboard_stats.dart';

/// A widget that displays a trend indicator with percentage change
/// Shows an up or down arrow with the percentage value
class TrendIndicatorWidget extends StatelessWidget {
  final TrendIndicator trend;
  final double fontSize;
  final bool showPercentage;
  final Color? cardColor;
  final Color? neutralColor;

  const TrendIndicatorWidget({
    super.key,
    required this.trend,
    this.fontSize = 12,
    this.showPercentage = true,
    this.cardColor,
    this.neutralColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final neutColor = neutralColor ?? colorScheme.onSurfaceVariant;

    final isNeutral = trend.percentageChange.abs() < 0.1;
    final color = isNeutral
        ? neutColor
        : (trend.isPositive
            ? (cardColor ?? Colors.green.shade600)
            : colorScheme.error);

    final icon = isNeutral
        ? Icons.remove
        : (trend.isPositive ? Icons.arrow_upward : Icons.arrow_downward);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: fontSize + 2,
          color: color,
        ),
        if (showPercentage) ...[
          const SizedBox(width: 2),
          Text(
            trend.formattedPercentage,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact trend indicator for use in stat cards
class CompactTrendIndicator extends StatelessWidget {
  final TrendIndicator trend;
  final String? label;
  final Color? cardColor;

  const CompactTrendIndicator({
    super.key,
    required this.trend,
    this.label,
    this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isNeutral = trend.percentageChange.abs() < 0.1;
    final isPositive = trend.isPositive;

    final textColor = isNeutral
        ? colorScheme.onSurfaceVariant
        : (isPositive
            ? (cardColor ?? Colors.green.shade700)
            : colorScheme.error);

    final icon = isNeutral
        ? Icons.remove
        : (isPositive ? Icons.trending_up : Icons.trending_down);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: textColor,
        ),
        const SizedBox(width: 2),
        Text(
          trend.formattedPercentage,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label!,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Trend badge that shows week-over-week comparison
class TrendBadge extends StatelessWidget {
  final TrendIndicator trend;
  final String period;
  final Color? cardColor;

  const TrendBadge({
    super.key,
    required this.trend,
    this.period = 'vs last week',
    this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isNeutral = trend.percentageChange.abs() < 0.1;
    final isPositive = trend.isPositive;

    final textColor = isNeutral
        ? colorScheme.onSurfaceVariant
        : (isPositive
            ? (cardColor ?? Colors.green.shade700)
            : colorScheme.error);

    final icon = isNeutral
        ? Icons.remove
        : (isPositive ? Icons.north_east : Icons.south_east);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: textColor,
        ),
        const SizedBox(width: 4),
        Text(
          trend.formattedPercentage,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          period,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Animated trend indicator with optional pulse effect
class AnimatedTrendIndicator extends StatefulWidget {
  final TrendIndicator trend;
  final bool animate;

  const AnimatedTrendIndicator({
    super.key,
    required this.trend,
    this.animate = true,
  });

  @override
  State<AnimatedTrendIndicator> createState() => _AnimatedTrendIndicatorState();
}

class _AnimatedTrendIndicatorState extends State<AnimatedTrendIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedTrendIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trend != oldWidget.trend && widget.animate) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: TrendIndicatorWidget(trend: widget.trend),
    );
  }
}
