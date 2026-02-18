// lib/features/disputes/presentation/widgets/dispute_priority_badge.dart

import 'package:flutter/material.dart';

import '../../domain/entities/dispute_entity.dart';

class DisputePriorityBadge extends StatelessWidget {
  final DisputePriority priority;
  final bool compact;

  const DisputePriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getPriorityConfig(priority);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: config.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 12, color: config.color),
            const SizedBox(width: 4),
            Text(
              priority.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: config.color,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 16, color: config.color),
          const SizedBox(width: 6),
          Text(
            priority.displayName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  _PriorityConfig _getPriorityConfig(DisputePriority priority) {
    switch (priority) {
      case DisputePriority.low:
        return _PriorityConfig(
          color: Colors.grey,
          icon: Icons.arrow_downward,
        );
      case DisputePriority.medium:
        return _PriorityConfig(
          color: Colors.blue,
          icon: Icons.remove,
        );
      case DisputePriority.high:
        return _PriorityConfig(
          color: Colors.orange,
          icon: Icons.arrow_upward,
        );
      case DisputePriority.urgent:
        return _PriorityConfig(
          color: Colors.red,
          icon: Icons.priority_high,
        );
    }
  }
}

class _PriorityConfig {
  final Color color;
  final IconData icon;

  const _PriorityConfig({
    required this.color,
    required this.icon,
  });
}

/// Priority indicator bar (colored line)
class PriorityIndicator extends StatelessWidget {
  final DisputePriority priority;
  final double width;
  final double height;

  const PriorityIndicator({
    super.key,
    required this.priority,
    this.width = 4,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _getPriorityColor(priority),
        borderRadius: BorderRadius.circular(width / 2),
      ),
    );
  }

  Color _getPriorityColor(DisputePriority priority) {
    switch (priority) {
      case DisputePriority.low:
        return Colors.grey;
      case DisputePriority.medium:
        return Colors.blue;
      case DisputePriority.high:
        return Colors.orange;
      case DisputePriority.urgent:
        return Colors.red;
    }
  }
}

/// Pulsing urgent indicator for critical disputes
class UrgentIndicator extends StatefulWidget {
  const UrgentIndicator({super.key});

  @override
  State<UrgentIndicator> createState() => _UrgentIndicatorState();
}

class _UrgentIndicatorState extends State<UrgentIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(_animation.value * 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.red.withOpacity(_animation.value),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber,
                size: 16,
                color: Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                'URGENT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
