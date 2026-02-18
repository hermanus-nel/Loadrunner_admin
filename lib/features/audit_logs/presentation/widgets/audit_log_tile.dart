// lib/features/audit_logs/presentation/widgets/audit_log_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/audit_log_entity.dart';

class AuditLogTile extends StatelessWidget {
  final AuditLogEntity log;
  final VoidCallback? onTap;
  final VoidCallback? onTargetTap;

  const AuditLogTile({
    super.key,
    required this.log,
    this.onTap,
    this.onTargetTap,
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
              // Header row: Action + Time
              Row(
                children: [
                  _buildActionBadge(theme),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.actionDescription,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _formatTime(log.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Admin info
              Row(
                children: [
                  _buildAdminAvatar(theme),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.admin?.fullName ?? 'Unknown Admin',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (log.admin?.email != null)
                          Text(
                            log.admin!.email!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Target info
              if (log.targetId != null) ...[
                const SizedBox(height: 8),
                _buildTargetChip(theme),
              ],

              // Changes summary
              if (log.changesSummary != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.change_history,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.changesSummary!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // IP Address (if available)
              if (log.ipAddress != null) ...[
                const SizedBox(height: 4),
                Text(
                  'IP: ${log.ipAddress}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBadge(ThemeData theme) {
    final action = AuditAction.fromString(log.action);
    final color = _getCategoryColor(action.category);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          action.icon,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildAdminAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: log.admin?.profilePhotoUrl != null
          ? NetworkImage(log.admin!.profilePhotoUrl!)
          : null,
      child: log.admin?.profilePhotoUrl == null
          ? Text(
              log.admin?.initials ?? 'A',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            )
          : null,
    );
  }

  Widget _buildTargetChip(ThemeData theme) {
    return InkWell(
      onTap: onTargetTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTargetIcon(log.targetType),
              size: 14,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              '${log.targetTypeDisplay}: ${_truncateId(log.targetId!)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontFamily: 'monospace',
              ),
            ),
            if (onTargetTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.open_in_new,
                size: 12,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ],
          ],
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

  String _truncateId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 8)}...';
  }

  Color _getCategoryColor(AuditActionCategory category) {
    switch (category) {
      case AuditActionCategory.driver:
        return Colors.blue;
      case AuditActionCategory.shipper:
        return Colors.purple;
      case AuditActionCategory.user:
        return Colors.teal;
      case AuditActionCategory.payment:
        return Colors.green;
      case AuditActionCategory.dispute:
        return Colors.orange;
      case AuditActionCategory.message:
        return Colors.indigo;
      case AuditActionCategory.vehicle:
        return Colors.cyan;
      case AuditActionCategory.auth:
        return Colors.red;
      case AuditActionCategory.other:
        return Colors.grey;
    }
  }

  IconData _getTargetIcon(String targetType) {
    switch (targetType.toLowerCase()) {
      case 'user':
        return Icons.person;
      case 'driver':
        return Icons.local_shipping;
      case 'shipper':
        return Icons.business;
      case 'vehicle':
        return Icons.directions_car;
      case 'payment':
        return Icons.payment;
      case 'dispute':
        return Icons.gavel;
      case 'message':
        return Icons.message;
      case 'shipment':
      case 'freight_post':
        return Icons.inventory;
      default:
        return Icons.circle;
    }
  }
}

/// Compact version for smaller spaces
class AuditLogTileCompact extends StatelessWidget {
  final AuditLogEntity log;
  final VoidCallback? onTap;

  const AuditLogTileCompact({
    super.key,
    required this.log,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = AuditAction.fromString(log.action);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: _getCategoryColor(action.category).withOpacity(0.1),
        child: Text(
          action.icon,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      title: Text(
        log.actionDescription,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${log.admin?.fullName ?? 'Unknown'} • ${_formatTimeCompact(log.createdAt)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }

  String _formatTimeCompact(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
  }

  Color _getCategoryColor(AuditActionCategory category) {
    switch (category) {
      case AuditActionCategory.driver:
        return Colors.blue;
      case AuditActionCategory.shipper:
        return Colors.purple;
      case AuditActionCategory.user:
        return Colors.teal;
      case AuditActionCategory.payment:
        return Colors.green;
      case AuditActionCategory.dispute:
        return Colors.orange;
      case AuditActionCategory.message:
        return Colors.indigo;
      case AuditActionCategory.vehicle:
        return Colors.cyan;
      case AuditActionCategory.auth:
        return Colors.red;
      case AuditActionCategory.other:
        return Colors.grey;
    }
  }
}

/// Category badge widget
class AuditCategoryBadge extends StatelessWidget {
  final AuditActionCategory category;
  final bool selected;
  final VoidCallback? onTap;

  const AuditCategoryBadge({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getCategoryColor(category);

    return FilterChip(
      selected: selected,
      label: Text(category.displayName),
      avatar: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      onSelected: onTap != null ? (_) => onTap!() : null,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
    );
  }

  Color _getCategoryColor(AuditActionCategory category) {
    switch (category) {
      case AuditActionCategory.driver:
        return Colors.blue;
      case AuditActionCategory.shipper:
        return Colors.purple;
      case AuditActionCategory.user:
        return Colors.teal;
      case AuditActionCategory.payment:
        return Colors.green;
      case AuditActionCategory.dispute:
        return Colors.orange;
      case AuditActionCategory.message:
        return Colors.indigo;
      case AuditActionCategory.vehicle:
        return Colors.cyan;
      case AuditActionCategory.auth:
        return Colors.red;
      case AuditActionCategory.other:
        return Colors.grey;
    }
  }
}

/// Stats summary widget
class AuditLogStats extends StatelessWidget {
  final AuditLogsStats stats;

  const AuditLogStats({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(
            icon: Icons.history,
            value: '${stats.totalLogs}',
            label: 'Total',
            color: Colors.blue,
          ),
          _StatColumn(
            icon: Icons.today,
            value: '${stats.logsToday}',
            label: 'Today',
            color: Colors.green,
          ),
          _StatColumn(
            icon: Icons.date_range,
            value: '${stats.logsThisWeek}',
            label: 'This Week',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
