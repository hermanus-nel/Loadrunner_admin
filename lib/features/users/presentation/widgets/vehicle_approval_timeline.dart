// lib/features/users/presentation/widgets/vehicle_approval_timeline.dart
import 'package:flutter/material.dart';
import '../../domain/repositories/vehicles_repository.dart';

/// Widget displaying the vehicle approval history as a timeline
class VehicleApprovalTimeline extends StatelessWidget {
  final List<VehicleApprovalHistoryItem> history;
  final int maxItems;
  final VoidCallback? onViewAll;

  const VehicleApprovalTimeline({
    super.key,
    required this.history,
    this.maxItems = 5,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (history.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Approval History', style: theme.textTheme.titleMedium),
                ],
              ),
              const Divider(height: 24),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 48,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No history yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayItems = history.take(maxItems).toList();
    final hasMore = history.length > maxItems;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Approval History', style: theme.textTheme.titleMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${history.length} ${history.length == 1 ? "entry" : "entries"}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...displayItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == displayItems.length - 1;
              return _buildTimelineItem(context, item, isLast);
            }),
            if (hasMore && onViewAll != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: Text('View all ${history.length} entries'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    VehicleApprovalHistoryItem item,
    bool isLast,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getStatusColor(item.newStatus).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getStatusColor(item.newStatus),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getStatusIcon(item.newStatus),
                    size: 16,
                    color: _getStatusColor(item.newStatus),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action title
                  Text(
                    _getActionTitle(item),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Admin and timestamp
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.adminName ?? 'System',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(item.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),

                  // Reason (if rejected)
                  if (item.reason != null && item.reason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.reason!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Notes (if any)
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.notes!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
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

  String _getActionTitle(VehicleApprovalHistoryItem item) {
    switch (item.newStatus.toLowerCase()) {
      case 'approved':
        return 'Vehicle Approved';
      case 'rejected':
        return 'Vehicle Rejected';
      case 'pending':
        if (item.previousStatus == 'rejected') {
          return 'Documents Requested (Re-submission)';
        }
        return 'Documents Requested';
      case 'under_review':
        return 'Marked as Under Review';
      case 'documents_requested':
        return 'Documents Requested';
      case 'suspended':
        return 'Vehicle Suspended';
      default:
        return 'Status Changed to ${item.newStatus}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'under_review':
        return Colors.blue;
      case 'documents_requested':
        return Colors.purple;
      case 'suspended':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check;
      case 'rejected':
        return Icons.close;
      case 'pending':
        return Icons.schedule;
      case 'under_review':
        return Icons.visibility;
      case 'documents_requested':
        return Icons.upload_file;
      case 'suspended':
        return Icons.block;
      default:
        return Icons.info_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}
