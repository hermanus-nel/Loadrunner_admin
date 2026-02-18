// lib/features/sms_usage/presentation/widgets/sms_log_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/repositories/sms_usage_repository.dart';

/// Full card tile for SMS log entries
class SmsLogTile extends StatelessWidget {
  final SmsLogEntity log;
  final VoidCallback? onTap;

  const SmsLogTile({
    super.key,
    required this.log,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Type badge + Phone + Time
              Row(
                children: [
                  SmsTypeBadge(type: log.smsType),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.maskedPhoneNumber,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  SmsStatusBadge(status: log.status),
                ],
              ),
              const SizedBox(height: 8),

              // Message preview
              Text(
                log.messagePreview,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Bottom row: Cost + Time
              Row(
                children: [
                  if (log.cost != null) ...[
                    Icon(
                      Icons.attach_money,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    Text(
                      log.cost!.toStringAsFixed(2),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (log.errorMessage != null) ...[
                    Icon(
                      Icons.error_outline,
                      size: 14,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        log.errorMessage!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  Text(
                    _formatTime(log.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
  }
}

/// Status badge with color coding
class SmsStatusBadge extends StatelessWidget {
  final SmsStatus status;

  const SmsStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = _statusColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color) _statusColors(BuildContext context) {
    switch (status) {
      case SmsStatus.sent:
        return (Colors.blue.shade700, Colors.blue.shade50);
      case SmsStatus.delivered:
        return (Colors.green.shade700, Colors.green.shade50);
      case SmsStatus.failed:
        return (Colors.red.shade700, Colors.red.shade50);
      case SmsStatus.pending:
        return (Colors.orange.shade700, Colors.orange.shade50);
    }
  }
}

/// Type badge with icon
class SmsTypeBadge extends StatelessWidget {
  final SmsType type;

  const SmsTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _typeIcon(),
        size: 16,
        color: color,
      ),
    );
  }

  IconData _typeIcon() {
    switch (type) {
      case SmsType.otp:
        return Icons.lock;
      case SmsType.notification:
        return Icons.notifications;
      case SmsType.broadcast:
        return Icons.campaign;
      case SmsType.custom:
        return Icons.sms;
    }
  }

  Color _typeColor() {
    switch (type) {
      case SmsType.otp:
        return Colors.purple;
      case SmsType.notification:
        return Colors.blue;
      case SmsType.broadcast:
        return Colors.orange;
      case SmsType.custom:
        return Colors.teal;
    }
  }
}
