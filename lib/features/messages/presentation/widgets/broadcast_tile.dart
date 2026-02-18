// lib/features/messages/presentation/widgets/broadcast_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/message_entity.dart';

class BroadcastTile extends StatelessWidget {
  final MessageEntity message;
  final VoidCallback? onTap;

  const BroadcastTile({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipientCount = message.recipientCount ?? 0;
    final audience = message.recipientRole != null
        ? BroadcastAudience.fromString(message.recipientRole!)
        : BroadcastAudience.all;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  // Campaign icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.campaign,
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and audience
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.subject ?? 'Broadcast',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 14,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              audience.displayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Time
                  Text(
                    _formatTime(message.sentAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Message preview
              Text(
                message.previewText,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer row with stats
              Row(
                children: [
                  // Recipients count
                  _StatChip(
                    icon: Icons.people,
                    label: '$recipientCount recipients',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),

                  // Push notification indicator
                  if (message.pushNotificationSent)
                    _StatChip(
                      icon: Icons.notifications_active,
                      label: 'Push sent',
                      color: Colors.green,
                    ),

                  const Spacer(),

                  // View details indicator
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(dateTime);
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact broadcast tile for smaller spaces
class BroadcastTileCompact extends StatelessWidget {
  final MessageEntity message;
  final VoidCallback? onTap;

  const BroadcastTileCompact({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audience = message.recipientRole != null
        ? BroadcastAudience.fromString(message.recipientRole!)
        : BroadcastAudience.all;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.campaign,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        message.subject ?? 'Broadcast',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            audience.displayName,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          Text(
            '• ${_formatDate(message.sentAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
      trailing: message.pushNotificationSent
          ? Icon(
              Icons.notifications_active,
              size: 16,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(date);
  }
}

/// Empty state widget for broadcasts
class BroadcastsEmptyState extends StatelessWidget {
  final VoidCallback? onCreateBroadcast;

  const BroadcastsEmptyState({
    super.key,
    this.onCreateBroadcast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.campaign_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No broadcasts yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Send your first broadcast to reach all your users at once',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (onCreateBroadcast != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCreateBroadcast,
                icon: const Icon(Icons.campaign),
                label: const Text('Create Broadcast'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
