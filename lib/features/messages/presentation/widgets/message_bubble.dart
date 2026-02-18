// lib/features/messages/presentation/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/message_entity.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isFromAdmin;
  final VoidCallback? onLongPress;
  final bool showTime;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromAdmin,
    this.onLongPress,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.only(
          left: isFromAdmin ? 48 : 0,
          right: isFromAdmin ? 0 : 48,
          bottom: 8,
        ),
        child: Column(
          crossAxisAlignment:
              isFromAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isFromAdmin
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isFromAdmin ? 16 : 4),
                  bottomRight: Radius.circular(isFromAdmin ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject if present
                  if (message.subject != null && message.subject!.isNotEmpty) ...[
                    Text(
                      message.subject!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isFromAdmin
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Message body
                  Text(
                    message.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isFromAdmin
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Time and status row
            if (showTime)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.sentAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontSize: 11,
                      ),
                    ),
                    if (isFromAdmin) ...[
                      const SizedBox(width: 4),
                      _buildStatusIcon(context),
                    ],
                    if (message.pushNotificationSent) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.notifications_active,
                        size: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    final theme = Theme.of(context);

    if (message.readAt != null) {
      return Icon(
        Icons.done_all,
        size: 14,
        color: theme.colorScheme.primary,
      );
    }

    return Icon(
      Icons.done,
      size: 14,
      color: theme.colorScheme.outline,
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime);
  }
}

/// Date separator for message list
class MessageDateSeparator extends StatelessWidget {
  final DateTime date;

  const MessageDateSeparator({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: theme.colorScheme.outlineVariant),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: theme.colorScheme.outlineVariant),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat.EEEE().format(date);
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }
}

/// System message bubble for special notifications
class SystemMessageBubble extends StatelessWidget {
  final String message;
  final IconData? icon;

  const SystemMessageBubble({
    super.key,
    required this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Typing indicator bubble
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 48, bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * 0.2;
                final progress = (_controller.value - delay) % 1.0;
                final offset = (progress < 0.5 ? progress : 1 - progress) * 6;

                return Transform.translate(
                  offset: Offset(0, -offset),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
