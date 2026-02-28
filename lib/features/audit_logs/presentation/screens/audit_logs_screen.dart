// lib/features/audit_logs/presentation/screens/audit_logs_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/components/loading_state.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../providers/audit_logs_providers.dart';
import '../widgets/audit_log_tile.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final _scrollController = ScrollController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initialize on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auditLogsListNotifierProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(auditLogsListNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(auditLogsListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: state.filters.hasActiveFilters,
              child: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
              ),
            ),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'today',
                child: ListTile(
                  leading: Icon(Icons.today),
                  title: Text('Today'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'week',
                child: ListTile(
                  leading: Icon(Icons.date_range),
                  title: Text('This Week'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'month',
                child: ListTile(
                  leading: Icon(Icons.calendar_month),
                  title: Text('This Month'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          if (state.stats != null) AuditLogStats(stats: state.stats!),

          // Filters panel
          if (_showFilters) _buildFiltersPanel(state),

          // Quick filters (categories)
          _buildCategoryFilters(state),

          // List
          Expanded(
            child: _buildList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel(AuditLogsListState state) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin filter
          Text('Admin', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: state.filters.adminId,
            decoration: InputDecoration(
              hintText: 'All Admins',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Admins'),
              ),
              ...state.availableAdmins.map((admin) => DropdownMenuItem(
                    value: admin.id,
                    child: Text(admin.fullName),
                  )),
            ],
            onChanged: (value) {
              ref.read(auditLogsListNotifierProvider.notifier).filterByAdmin(value);
            },
          ),
          const SizedBox(height: 16),

          // Action filter
          Text('Action', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: state.filters.action,
            decoration: InputDecoration(
              hintText: 'All Actions',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Actions'),
              ),
              ...state.availableActions.map((action) {
                final auditAction = AuditAction.fromString(action);
                return DropdownMenuItem(
                  value: action,
                  child: Row(
                    children: [
                      Text(auditAction.icon),
                      const SizedBox(width: 8),
                      Text(auditAction.displayName),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (value) {
              ref.read(auditLogsListNotifierProvider.notifier).filterByAction(value);
            },
          ),
          const SizedBox(height: 16),

          // Target type filter
          Text('Target Type', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AuditTargetType.values
                .where((t) => t != AuditTargetType.other)
                .map((targetType) => FilterChip(
                      selected: state.filters.targetType == targetType.value,
                      label: Text(targetType.displayName),
                      onSelected: (selected) {
                        ref
                            .read(auditLogsListNotifierProvider.notifier)
                            .filterByTargetType(selected ? targetType.value : null);
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Date range
          Text('Date Range', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    state.filters.dateFrom != null
                        ? DateFormat.MMMd().format(state.filters.dateFrom!)
                        : 'Start Date',
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: state.filters.dateFrom ?? DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      ref
                          .read(auditLogsListNotifierProvider.notifier)
                          .filterByDateRange(date, state.filters.dateTo);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('to'),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    state.filters.dateTo != null
                        ? DateFormat.MMMd().format(state.filters.dateTo!)
                        : 'End Date',
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: state.filters.dateTo ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      ref
                          .read(auditLogsListNotifierProvider.notifier)
                          .filterByDateRange(state.filters.dateFrom, date);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Clear filters
          if (state.filters.hasActiveFilters)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All Filters'),
                onPressed: () {
                  ref.read(auditLogsListNotifierProvider.notifier).clearFilters();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(AuditLogsListState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              selected: state.filters.category == null,
              label: const Text('All'),
              onSelected: (selected) {
                if (selected) {
                  ref
                      .read(auditLogsListNotifierProvider.notifier)
                      .filterByCategory(null);
                }
              },
            ),
            const SizedBox(width: 8),
            ...AuditActionCategory.values.map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AuditCategoryBadge(
                    category: category,
                    selected: state.filters.category == category,
                    onTap: () {
                      ref
                          .read(auditLogsListNotifierProvider.notifier)
                          .filterByCategory(
                            state.filters.category == category ? null : category,
                          );
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildList(AuditLogsListState state) {
    final theme = Theme.of(context);

    if (state.isLoading && state.logs.isEmpty) {
      return const ShimmerList(itemCount: 6, itemHeight: 72);
    }

    if (state.error != null && state.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading audit logs',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(auditLogsListNotifierProvider.notifier).fetchLogs(refresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.logs.isEmpty) {
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
              state.filters.hasActiveFilters
                  ? 'No logs match your filters'
                  : 'No audit logs yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Admin actions will appear here',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (state.filters.hasActiveFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ref.read(auditLogsListNotifierProvider.notifier).clearFilters();
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    // Group logs by date
    final groupedLogs = _groupLogsByDate(state.logs);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(auditLogsListNotifierProvider.notifier).fetchLogs(refresh: true);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        itemCount: groupedLogs.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == groupedLogs.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final entry = groupedLogs.entries.elementAt(index);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  entry.key,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Logs for this date
              ...entry.value.map((log) => AuditLogTile(
                    log: log,
                    onTap: () => _showLogDetails(log),
                    onTargetTap: log.targetId != null
                        ? () => _navigateToTarget(log)
                        : null,
                  )),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<AuditLogEntity>> _groupLogsByDate(List<AuditLogEntity> logs) {
    final grouped = <String, List<AuditLogEntity>>{};
    for (final log in logs) {
      final date = _formatDateHeader(log.createdAt);
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(log);
    }
    return grouped;
  }

  String _formatDateHeader(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (logDate == today) {
      return 'Today';
    } else if (logDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat.EEEE().format(dateTime); // Day name
    } else {
      return DateFormat.yMMMd().format(dateTime);
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'today':
        ref.read(auditLogsListNotifierProvider.notifier).filterToday();
        break;
      case 'week':
        ref.read(auditLogsListNotifierProvider.notifier).filterThisWeek();
        break;
      case 'month':
        ref.read(auditLogsListNotifierProvider.notifier).filterThisMonth();
        break;
      case 'export':
        _exportLogs();
        break;
      case 'refresh':
        ref.read(auditLogsListNotifierProvider.notifier).initialize();
        break;
    }
  }

  void _showLogDetails(AuditLogEntity log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _LogDetailSheet(
          log: log,
          scrollController: scrollController,
          onTargetTap: log.targetId != null ? () => _navigateToTarget(log) : null,
        ),
      ),
    );
  }

  void _navigateToTarget(AuditLogEntity log) {
    if (log.targetId == null) return;

    Navigator.pop(context); // Close bottom sheet if open

    switch (log.targetType.toLowerCase()) {
      case 'user':
      case 'shipper':
        context.push('/shippers/${log.targetId}');
        break;
      case 'driver':
        context.push('/users/driver/${log.targetId}');
        break;
      case 'vehicle':
        context.push('/users/vehicle/${log.targetId}');
        break;
      case 'dispute':
        context.push('/disputes/${log.targetId}');
        break;
      case 'payment':
        context.push('/payments/transaction/${log.targetId}');
        break;
      // Add more target types as needed
    }
  }

  Future<void> _exportLogs() async {
    final state = ref.read(auditLogsListNotifierProvider);

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting logs...')),
    );

    final csv = await ref.read(exportLogsProvider(state.filters).future);

    if (csv != null && mounted) {
      // In a real app, you would save the file or share it
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${state.pagination.totalCount} logs'),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () {
              // Copy to clipboard
            },
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export logs')),
      );
    }
  }
}

/// Log detail bottom sheet
class _LogDetailSheet extends StatelessWidget {
  final AuditLogEntity log;
  final ScrollController scrollController;
  final VoidCallback? onTargetTap;

  const _LogDetailSheet({
    required this.log,
    required this.scrollController,
    this.onTargetTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    AuditAction.fromString(log.action).icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.actionDescription,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().add_jms().format(log.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          // Admin section
          _DetailSection(
            title: 'Performed By',
            icon: Icons.person,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: log.admin?.profilePhotoUrl != null
                      ? CachedNetworkImageProvider(log.admin!.profilePhotoUrl!)
                      : null,
                  child: log.admin?.profilePhotoUrl == null
                      ? Text(log.admin?.initials ?? 'A')
                      : null,
                ),
                title: Text(log.admin?.fullName ?? 'Unknown Admin'),
                subtitle: log.admin?.email != null ? Text(log.admin!.email!) : null,
              ),
            ],
          ),

          // Target section
          if (log.targetId != null)
            _DetailSection(
              title: 'Target',
              icon: Icons.gps_fixed,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_getTargetIcon(log.targetType)),
                  title: Text(
                    log.targetName != null
                        ? '${log.targetTypeDisplay}: ${log.targetName}'
                        : log.targetTypeDisplay,
                  ),
                  subtitle: Text(
                    'ID: ${log.targetId!}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontSize: 11,
                    ),
                  ),
                  trailing: onTargetTap != null
                      ? TextButton(
                          onPressed: onTargetTap,
                          child: const Text('View'),
                        )
                      : null,
                ),
              ],
            ),

          // Changes section
          if (log.hasChanges)
            _DetailSection(
              title: 'Changes',
              icon: Icons.change_history,
              children: [
                if (log.oldValues != null) ...[
                  Text(
                    'Previous Values:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatJson(log.oldValues!),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (log.newValues != null) ...[
                  Text(
                    'New Values:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatJson(log.newValues!),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),

          // Context section
          if (log.ipAddress != null || log.userAgent != null)
            _DetailSection(
              title: 'Context',
              icon: Icons.computer,
              children: [
                if (log.ipAddress != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language),
                    title: const Text('IP Address'),
                    subtitle: Text(
                      log.ipAddress!,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                if (log.userAgent != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.devices),
                    title: const Text('User Agent'),
                    subtitle: Text(
                      log.userAgent!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),

          // ID section
          _DetailSection(
            title: 'Log ID',
            icon: Icons.fingerprint,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  log.id,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  String _formatJson(Map<String, dynamic> json) {
    final buffer = StringBuffer();
    json.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trim();
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
