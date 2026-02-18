// lib/features/sms_usage/presentation/screens/sms_usage_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/components/loading_state.dart';
import '../../domain/repositories/sms_usage_repository.dart';
import '../providers/sms_usage_providers.dart';
import '../widgets/sms_log_tile.dart';
import '../widgets/sms_usage_chart.dart';

class SmsUsageScreen extends ConsumerStatefulWidget {
  const SmsUsageScreen({super.key});

  @override
  ConsumerState<SmsUsageScreen> createState() => _SmsUsageScreenState();
}

class _SmsUsageScreenState extends ConsumerState<SmsUsageScreen> {
  final _scrollController = ScrollController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(smsUsageNotifierProvider.notifier).initialize();
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
      ref.read(smsUsageNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsUsageNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('SMS Usage'),
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
          if (state.stats != null) UsageOverviewCards(stats: state.stats!),

          // Filters panel
          if (_showFilters) _buildFiltersPanel(state),

          // Quick filter chips (by type)
          _buildTypeFilters(state),

          // Main content
          Expanded(
            child: _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel(SmsUsageState state) {
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
          // Status filter
          Text('Status', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SmsStatus.values
                .map((status) => FilterChip(
                      selected: state.filters.status == status,
                      label: Text(status.displayName),
                      onSelected: (selected) {
                        ref
                            .read(smsUsageNotifierProvider.notifier)
                            .filterByStatus(selected ? status : null);
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Type filter
          Text('SMS Type', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SmsType.values
                .map((type) => FilterChip(
                      selected: state.filters.type == type,
                      label: Text(type.displayName),
                      onSelected: (selected) {
                        ref
                            .read(smsUsageNotifierProvider.notifier)
                            .filterByType(selected ? type : null);
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
                      initialDate: state.filters.dateFrom ??
                          DateTime.now()
                              .subtract(const Duration(days: 30)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      ref
                          .read(smsUsageNotifierProvider.notifier)
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
                          .read(smsUsageNotifierProvider.notifier)
                          .filterByDateRange(state.filters.dateFrom, date);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search by phone number
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by phone number...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSubmitted: (value) {
              ref
                  .read(smsUsageNotifierProvider.notifier)
                  .filterBySearch(value.isEmpty ? null : value);
            },
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
                  ref.read(smsUsageNotifierProvider.notifier).clearFilters();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeFilters(SmsUsageState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              selected: state.filters.type == null,
              label: const Text('All'),
              onSelected: (selected) {
                if (selected) {
                  ref
                      .read(smsUsageNotifierProvider.notifier)
                      .filterByType(null);
                }
              },
            ),
            const SizedBox(width: 8),
            ...SmsType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: state.filters.type == type,
                    label: Text(type.displayName),
                    avatar: Icon(
                      _typeIcon(type),
                      size: 16,
                    ),
                    onSelected: (selected) {
                      ref
                          .read(smsUsageNotifierProvider.notifier)
                          .filterByType(
                            selected ? type : null,
                          );
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SmsUsageState state) {
    final theme = Theme.of(context);

    if (state.isLoading && state.logs.isEmpty) {
      return const ShimmerList(itemCount: 5, itemHeight: 80);
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
              'Error loading SMS usage',
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
                ref.read(smsUsageNotifierProvider.notifier).initialize();
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
              Icons.sms_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              state.filters.hasActiveFilters
                  ? 'No SMS logs match your filters'
                  : 'No SMS logs yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'SMS messages will appear here',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (state.filters.hasActiveFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ref.read(smsUsageNotifierProvider.notifier).clearFilters();
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(smsUsageNotifierProvider.notifier).initialize();
      },
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Chart section
          if (state.dailyUsage.isNotEmpty)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SmsUsageChart(dailyUsage: state.dailyUsage),
            ),

          // Cost breakdown
          if (state.stats != null &&
              state.stats!.costByType.isNotEmpty)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: CostBreakdownCard(stats: state.stats!),
            ),

          // Recent SMS logs header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Recent SMS Logs',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${state.pagination.totalCount} total',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),

          // SMS log tiles
          ...state.logs.map((log) => SmsLogTile(
                log: log,
                onTap: () => _showLogDetails(log),
              )),

          // Loading more indicator
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'today':
        ref.read(smsUsageNotifierProvider.notifier).filterToday();
        break;
      case 'week':
        ref.read(smsUsageNotifierProvider.notifier).filterThisWeek();
        break;
      case 'month':
        ref.read(smsUsageNotifierProvider.notifier).filterThisMonth();
        break;
      case 'refresh':
        ref.read(smsUsageNotifierProvider.notifier).initialize();
        break;
    }
  }

  void _showLogDetails(SmsLogEntity log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => _SmsLogDetailSheet(
          log: log,
          scrollController: scrollController,
        ),
      ),
    );
  }

  IconData _typeIcon(SmsType type) {
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
}

/// SMS log detail bottom sheet
class _SmsLogDetailSheet extends StatelessWidget {
  final SmsLogEntity log;
  final ScrollController scrollController;

  const _SmsLogDetailSheet({
    required this.log,
    required this.scrollController,
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
              SmsTypeBadge(type: log.smsType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.smsType.displayName,
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
              SmsStatusBadge(status: log.status),
            ],
          ),
          const Divider(height: 32),

          // Phone number
          _DetailRow(
            icon: Icons.phone,
            label: 'Phone Number',
            value: log.phoneNumber,
          ),

          // Message body
          if (log.messageBody != null) ...[
            const SizedBox(height: 12),
            Text(
              'Message',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                log.messageBody!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],

          // Cost
          if (log.cost != null)
            _DetailRow(
              icon: Icons.attach_money,
              label: 'Cost',
              value: 'R ${log.cost!.toStringAsFixed(4)}',
            ),

          // BulkSMS Message ID
          if (log.bulksmsMessageId != null)
            _DetailRow(
              icon: Icons.fingerprint,
              label: 'BulkSMS ID',
              value: log.bulksmsMessageId!,
              mono: true,
            ),

          // Error message
          if (log.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Delivered at
          if (log.deliveredAt != null)
            _DetailRow(
              icon: Icons.check_circle,
              label: 'Delivered At',
              value: DateFormat.yMMMd().add_jms().format(log.deliveredAt!),
            ),

          // Log ID
          _DetailRow(
            icon: Icons.tag,
            label: 'Log ID',
            value: log.id,
            mono: true,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
