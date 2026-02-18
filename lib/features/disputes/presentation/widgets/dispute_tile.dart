// lib/features/disputes/presentation/widgets/dispute_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/dispute_entity.dart';
import 'dispute_status_badge.dart';
import 'dispute_priority_badge.dart';

class DisputeTile extends StatelessWidget {
  final DisputeEntity dispute;
  final VoidCallback? onTap;

  const DisputeTile({
    super.key,
    required this.dispute,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: dispute.isUrgent ? 2 : 0,
      color: dispute.isUrgent
          ? theme.colorScheme.errorContainer.withOpacity(0.3)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Priority indicator
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(dispute.priority),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dispute.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#${dispute.id.substring(0, 8)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  DisputeStatusBadge(status: dispute.status, compact: true),
                ],
              ),
              const SizedBox(height: 12),

              // Description preview
              Text(
                dispute.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Type and Priority badges
              Row(
                children: [
                  // Type chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTypeIcon(dispute.disputeType),
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dispute.disputeType.displayName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Priority badge
                  DisputePriorityBadge(priority: dispute.priority, compact: true),

                  const Spacer(),

                  // Evidence count
                  if (dispute.evidenceCount != null && dispute.evidenceCount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 12,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${dispute.evidenceCount}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Parties and date
              Row(
                children: [
                  // Raised by
                  if (dispute.raisedBy != null) ...[
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: dispute.raisedBy!.profilePhotoUrl != null
                          ? NetworkImage(dispute.raisedBy!.profilePhotoUrl!)
                          : null,
                      child: dispute.raisedBy!.profilePhotoUrl == null
                          ? Text(
                              dispute.raisedBy!.initials[0],
                              style: const TextStyle(fontSize: 10),
                            )
                          : null,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'vs',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (dispute.raisedAgainst != null)
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      backgroundImage: dispute.raisedAgainst!.profilePhotoUrl != null
                          ? NetworkImage(dispute.raisedAgainst!.profilePhotoUrl!)
                          : null,
                      child: dispute.raisedAgainst!.profilePhotoUrl == null
                          ? Text(
                              dispute.raisedAgainst!.initials[0],
                              style: const TextStyle(fontSize: 10),
                            )
                          : null,
                    ),

                  const Spacer(),

                  // Date
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(dispute.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),

                  // Arrow
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
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

  IconData _getTypeIcon(DisputeType type) {
    switch (type) {
      case DisputeType.damage:
        return Icons.broken_image;
      case DisputeType.nonDelivery:
        return Icons.local_shipping;
      case DisputeType.payment:
        return Icons.payment;
      case DisputeType.wrongItem:
        return Icons.swap_horiz;
      case DisputeType.lateDelivery:
        return Icons.schedule;
      case DisputeType.overcharge:
        return Icons.attach_money;
      case DisputeType.other:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat.MMMd().format(date);
    }
  }
}

/// Compact version for smaller spaces
class DisputeTileCompact extends StatelessWidget {
  final DisputeEntity dispute;
  final VoidCallback? onTap;

  const DisputeTileCompact({
    super.key,
    required this.dispute,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: _getPriorityColor(dispute.priority),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        dispute.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '#${dispute.id.substring(0, 8)} • ${dispute.disputeType.displayName}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: DisputeStatusBadge(status: dispute.status, compact: true),
      onTap: onTap,
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
