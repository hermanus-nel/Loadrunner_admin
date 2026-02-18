import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/approval_history_item.dart';

/// Timeline widget for displaying approval history
class ApprovalTimeline extends StatefulWidget {
  final List<ApprovalHistoryItem> history;
  final bool isLoading;
  final int initialDisplayCount;

  const ApprovalTimeline({
    super.key,
    required this.history,
    this.isLoading = false,
    this.initialDisplayCount = 5,
  });

  @override
  State<ApprovalTimeline> createState() => _ApprovalTimelineState();
}

class _ApprovalTimelineState extends State<ApprovalTimeline> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (widget.history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No approval history',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayList = _showAll
        ? widget.history
        : widget.history.take(widget.initialDisplayCount).toList();
    final hasMore = widget.history.length > widget.initialDisplayCount;

    return Column(
      children: [
        ...displayList.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == displayList.length - 1;

          return _TimelineItem(
            item: item,
            isLast: isLast,
          );
        }),

        // Show more/less button
        if (hasMore)
          TextButton(
            onPressed: () {
              setState(() {
                _showAll = !_showAll;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_showAll ? 'Show less' : 'Show all'),
                Icon(
                  _showAll ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final ApprovalHistoryItem item;
  final bool isLast;

  const _TimelineItem({
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: item.actionColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.actionColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    item.actionIcon,
                    size: 12,
                    color: item.actionColor,
                  ),
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action description
                  Text(
                    item.actionDescription,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Status change
                  if (item.previousStatus != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.statusChangeDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),

                  // Admin and timestamp
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.adminDisplayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(item.createdAt)} at ${timeFormat.format(item.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  // Reason
                  if (item.reason != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.reason!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Notes
                  if (item.notes != null && item.notes != item.reason) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  // Documents reviewed
                  if (item.documentsReviewed != null &&
                      item.documentsReviewed!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: item.documentsReviewed!.map((doc) {
                        return Chip(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            doc,
                            style: theme.textTheme.labelSmall,
                          ),
                          avatar: const Icon(Icons.description, size: 14),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
