// lib/features/disputes/presentation/widgets/dispute_status_badge.dart

import 'package:flutter/material.dart';

import '../../domain/entities/dispute_entity.dart';

class DisputeStatusBadge extends StatelessWidget {
  final DisputeStatus status;
  final bool compact;

  const DisputeStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: config.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status.displayName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: config.color,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 16, color: config.color),
          const SizedBox(width: 6),
          Text(
            status.displayName,
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

  _StatusConfig _getStatusConfig(DisputeStatus status) {
    switch (status) {
      case DisputeStatus.open:
        return _StatusConfig(
          color: Colors.orange,
          icon: Icons.folder_open,
        );
      case DisputeStatus.investigating:
        return _StatusConfig(
          color: Colors.blue,
          icon: Icons.search,
        );
      case DisputeStatus.awaitingEvidence:
        return _StatusConfig(
          color: Colors.purple,
          icon: Icons.hourglass_empty,
        );
      case DisputeStatus.resolved:
        return _StatusConfig(
          color: Colors.green,
          icon: Icons.check_circle,
        );
      case DisputeStatus.escalated:
        return _StatusConfig(
          color: Colors.red,
          icon: Icons.arrow_upward,
        );
      case DisputeStatus.closed:
        return _StatusConfig(
          color: Colors.grey,
          icon: Icons.archive,
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;

  const _StatusConfig({
    required this.color,
    required this.icon,
  });
}

/// Status chip for filter selection
class DisputeStatusChip extends StatelessWidget {
  final DisputeStatus status;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const DisputeStatusChip({
    super.key,
    required this.status,
    this.selected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return FilterChip(
      label: Text(status.displayName),
      avatar: Icon(
        config.icon,
        size: 18,
        color: selected ? config.color : null,
      ),
      selected: selected,
      selectedColor: config.color.withOpacity(0.2),
      onSelected: onSelected,
    );
  }

  _StatusConfig _getStatusConfig(DisputeStatus status) {
    switch (status) {
      case DisputeStatus.open:
        return _StatusConfig(color: Colors.orange, icon: Icons.folder_open);
      case DisputeStatus.investigating:
        return _StatusConfig(color: Colors.blue, icon: Icons.search);
      case DisputeStatus.awaitingEvidence:
        return _StatusConfig(color: Colors.purple, icon: Icons.hourglass_empty);
      case DisputeStatus.resolved:
        return _StatusConfig(color: Colors.green, icon: Icons.check_circle);
      case DisputeStatus.escalated:
        return _StatusConfig(color: Colors.red, icon: Icons.arrow_upward);
      case DisputeStatus.closed:
        return _StatusConfig(color: Colors.grey, icon: Icons.archive);
    }
  }
}
