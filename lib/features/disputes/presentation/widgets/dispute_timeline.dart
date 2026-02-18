// lib/features/disputes/presentation/widgets/dispute_timeline.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/dispute_entity.dart';
import '../../domain/entities/evidence_entity.dart';

class DisputeTimeline extends StatelessWidget {
  final List<DisputeTimelineEvent> timeline;
  final DisputeEntity dispute;

  const DisputeTimeline({
    super.key,
    required this.timeline,
    required this.dispute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Create a combined timeline with dispute creation
    final allEvents = <_TimelineItem>[
      _TimelineItem(
        type: 'created',
        title: 'Dispute Created',
        description: 'Dispute was raised by ${dispute.raisedBy?.displayName ?? "user"}',
        timestamp: dispute.createdAt,
        icon: Icons.flag,
        color: Colors.blue,
      ),
      ...timeline.map((event) => _TimelineItem(
            type: event.eventType,
            title: event.eventDisplayName,
            description: event.description,
            timestamp: event.createdAt,
            performer: event.performedBy?.displayName,
            icon: _getEventIcon(event.eventType),
            color: _getEventColor(event.eventType),
            metadata: event.metadata,
          )),
    ];

    // Sort by timestamp descending (newest first)
    allEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (allEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No timeline events',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allEvents.length,
      itemBuilder: (context, index) {
        final item = allEvents[index];
        final isFirst = index == 0;
        final isLast = index == allEvents.length - 1;

        return _TimelineItemWidget(
          item: item,
          isFirst: isFirst,
          isLast: isLast,
        );
      },
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'created':
        return Icons.flag;
      case 'assigned':
        return Icons.person_add;
      case 'status_changed':
        return Icons.update;
      case 'evidence_added':
        return Icons.add_photo_alternate;
      case 'escalated':
        return Icons.arrow_upward;
      case 'resolved':
        return Icons.check_circle;
      case 'closed':
        return Icons.archive;
      case 'comment_added':
        return Icons.comment;
      case 'priority_changed':
        return Icons.priority_high;
      case 'evidence_requested':
        return Icons.request_page;
      case 'dispute_resolved':
        return Icons.gavel;
      case 'dispute_escalated':
        return Icons.trending_up;
      case 'dispute_status_changed':
        return Icons.sync;
      case 'dispute_priority_changed':
        return Icons.flag;
      case 'dispute_assigned':
        return Icons.assignment_ind;
      default:
        return Icons.circle;
    }
  }

  Color _getEventColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'created':
        return Colors.blue;
      case 'assigned':
      case 'dispute_assigned':
        return Colors.purple;
      case 'status_changed':
      case 'dispute_status_changed':
        return Colors.orange;
      case 'evidence_added':
        return Colors.teal;
      case 'escalated':
      case 'dispute_escalated':
        return Colors.red;
      case 'resolved':
      case 'dispute_resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      case 'comment_added':
        return Colors.indigo;
      case 'priority_changed':
      case 'dispute_priority_changed':
        return Colors.amber;
      case 'evidence_requested':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}

class _TimelineItem {
  final String type;
  final String title;
  final String? description;
  final DateTime timestamp;
  final String? performer;
  final IconData icon;
  final Color color;
  final Map<String, dynamic>? metadata;

  const _TimelineItem({
    required this.type,
    required this.title,
    this.description,
    required this.timestamp,
    this.performer,
    required this.icon,
    required this.color,
    this.metadata,
  });
}

class _TimelineItemWidget extends StatelessWidget {
  final _TimelineItem item;
  final bool isFirst;
  final bool isLast;

  const _TimelineItemWidget({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and icon
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Line above icon
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 20,
                    color: theme.colorScheme.outlineVariant,
                  ),
                // Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.color,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    size: 16,
                    color: item.color,
                  ),
                ),
                // Line below icon
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(item.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),

                  // Performer
                  if (item.performer != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'by ${item.performer}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],

                  // Description
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.description!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],

                  // Metadata display
                  if (item.metadata != null && item.metadata!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: item.metadata!.entries
                          .where((e) => e.key != 'notes' && e.value != null)
                          .map((e) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${_formatKey(e.key)}: ${e.value}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ))
                          .toList(),
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat.jm().format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat.MMMd().add_jm().format(dateTime);
    }
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}

/// Compact timeline view for summaries
class DisputeTimelineCompact extends StatelessWidget {
  final List<DisputeTimelineEvent> timeline;
  final int maxItems;
  final VoidCallback? onViewAll;

  const DisputeTimelineCompact({
    super.key,
    required this.timeline,
    this.maxItems = 3,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayEvents = timeline.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayEvents.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getEventColor(event.eventType),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.eventDisplayName,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    _formatTimeAgo(event.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )),
        if (timeline.length > maxItems && onViewAll != null) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('View all ${timeline.length} events'),
          ),
        ],
      ],
    );
  }

  Color _getEventColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'created':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'evidence_added':
        return Colors.teal;
      case 'escalated':
        return Colors.red;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}

/// Add note widget
class AddNoteWidget extends StatefulWidget {
  final Future<bool> Function(String note) onAddNote;

  const AddNoteWidget({
    super.key,
    required this.onAddNote,
  });

  @override
  State<AddNoteWidget> createState() => _AddNoteWidgetState();
}

class _AddNoteWidgetState extends State<AddNoteWidget> {
  final _controller = TextEditingController();
  bool _isExpanded = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isExpanded) {
      return OutlinedButton.icon(
        onPressed: () => setState(() => _isExpanded = true),
        icon: const Icon(Icons.add_comment),
        label: const Text('Add Note'),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Add an internal note...',
                border: InputBorder.none,
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const Divider(),
            Row(
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isExpanded = false;
                            _controller.clear();
                          });
                        },
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _isLoading || _controller.text.isEmpty
                      ? null
                      : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Note'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_controller.text.isEmpty) return;

    setState(() => _isLoading = true);

    final success = await widget.onAddNote(_controller.text);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _controller.clear();
        setState(() => _isExpanded = false);
      }
    }
  }
}
