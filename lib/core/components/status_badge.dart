import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Size options for status badge
enum StatusBadgeSize { small, medium, large }

/// Reusable status indicator badge (pending, approved, rejected, etc.)
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
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: iconSize,
            color: config.textColor,
          ),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.textColor,
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
      case 'completed':
      case 'delivered':
      case 'active':
        return _StatusConfig(
          backgroundColor: AppColors.statusApproved,
          textColor: AppColors.statusApprovedText,
          icon: Icons.check_circle,
          label: _formatLabel(status),
        );
      case 'pending':
      case 'bidding':
      case 'pickup':
        return _StatusConfig(
          backgroundColor: AppColors.statusPending,
          textColor: AppColors.statusPendingText,
          icon: Icons.pending,
          label: _formatLabel(status),
        );
      case 'rejected':
      case 'failed':
      case 'cancelled':
        return _StatusConfig(
          backgroundColor: AppColors.statusRejected,
          textColor: AppColors.statusRejectedText,
          icon: Icons.cancel,
          label: _formatLabel(status),
        );
      case 'under_review':
      case 'on_route':
      case 'in_progress':
        return _StatusConfig(
          backgroundColor: AppColors.statusDocumentsRequested,
          textColor: AppColors.statusDocumentsRequestedText,
          icon: Icons.visibility,
          label: _formatLabel(status),
        );
      case 'documents_requested':
        return _StatusConfig(
          backgroundColor: AppColors.statusDocumentsRequested,
          textColor: AppColors.statusDocumentsRequestedText,
          icon: Icons.upload_file,
          label: 'Docs Requested',
        );
      case 'suspended':
        return _StatusConfig(
          backgroundColor: AppColors.statusSuspended,
          textColor: AppColors.statusSuspendedText,
          icon: Icons.block,
          label: 'Suspended',
        );
      default:
        return _StatusConfig(
          backgroundColor: AppColors.statusSuspended,
          textColor: AppColors.statusSuspendedText,
          icon: Icons.help_outline,
          label: _formatLabel(status),
        );
    }
  }

  String _formatLabel(String s) {
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class _StatusConfig {
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final String label;

  _StatusConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.label,
  });
}
