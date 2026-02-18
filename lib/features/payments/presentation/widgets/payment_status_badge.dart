// lib/features/payments/presentation/widgets/payment_status_badge.dart

import 'package:flutter/material.dart';
import '../../domain/entities/payment_entity.dart';

/// Widget to display payment status as a colored badge
class PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;
  final bool compact;

  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors(context);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
        border: Border.all(
          color: colors.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            colors.icon,
            size: compact ? 12 : 14,
            color: colors.textColor,
          ),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: colors.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _StatusColors _getStatusColors(BuildContext context) {
    switch (status) {
      case PaymentStatus.success:
        return _StatusColors(
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade200,
          textColor: Colors.green.shade700,
          icon: Icons.check_circle_outline,
        );
      case PaymentStatus.pending:
        return _StatusColors(
          backgroundColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade200,
          textColor: Colors.orange.shade700,
          icon: Icons.schedule,
        );
      case PaymentStatus.failed:
        return _StatusColors(
          backgroundColor: Colors.red.shade50,
          borderColor: Colors.red.shade200,
          textColor: Colors.red.shade700,
          icon: Icons.error_outline,
        );
      case PaymentStatus.refunded:
        return _StatusColors(
          backgroundColor: Colors.blue.shade50,
          borderColor: Colors.blue.shade200,
          textColor: Colors.blue.shade700,
          icon: Icons.replay,
        );
      case PaymentStatus.cancelled:
        return _StatusColors(
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade600,
          icon: Icons.cancel_outlined,
        );
    }
  }
}

/// Helper class for status colors
class _StatusColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;

  const _StatusColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
  });
}

/// Chip version for filter selection
class PaymentStatusChip extends StatelessWidget {
  final PaymentStatus? status;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentStatusChip({
    super.key,
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = status?.displayName ?? 'All';
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primary.withOpacity(0.15),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected 
            ? theme.colorScheme.primary 
            : theme.colorScheme.outline.withOpacity(0.5),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
