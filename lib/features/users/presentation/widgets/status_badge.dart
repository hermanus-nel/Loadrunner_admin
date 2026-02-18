import 'package:flutter/material.dart';

/// Size options for status badge
enum StatusBadgeSize { small, medium, large }

/// A badge widget for displaying verification status
class StatusBadge extends StatelessWidget {
  final String status;
  final StatusBadgeSize size;

  const StatusBadge({
    super.key,
    required this.status,
    this.size = StatusBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();

    double fontSize;
    EdgeInsets padding;
    double iconSize;

    switch (size) {
      case StatusBadgeSize.small:
        fontSize = 10;
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
        iconSize = 12;
        break;
      case StatusBadgeSize.medium:
        fontSize = 12;
        padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4);
        iconSize = 14;
        break;
      case StatusBadgeSize.large:
        fontSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
        iconSize = 16;
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: iconSize,
            color: config.color,
          ),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig() {
    switch (status.toLowerCase()) {
      case 'approved':
        return _StatusConfig(
          color: Colors.green,
          icon: Icons.check_circle,
          label: 'Approved',
        );
      case 'pending':
        return _StatusConfig(
          color: Colors.orange,
          icon: Icons.pending,
          label: 'Pending',
        );
      case 'rejected':
        return _StatusConfig(
          color: Colors.red,
          icon: Icons.cancel,
          label: 'Rejected',
        );
      case 'under_review':
        return _StatusConfig(
          color: Colors.blue,
          icon: Icons.visibility,
          label: 'Under Review',
        );
      case 'documents_requested':
        return _StatusConfig(
          color: Colors.purple,
          icon: Icons.upload_file,
          label: 'Docs Requested',
        );
      case 'suspended':
        return _StatusConfig(
          color: Colors.brown,
          icon: Icons.block,
          label: 'Suspended',
        );
      default:
        return _StatusConfig(
          color: Colors.grey,
          icon: Icons.help_outline,
          label: status,
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;

  _StatusConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}
