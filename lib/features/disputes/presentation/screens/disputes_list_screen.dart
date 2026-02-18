// lib/features/disputes/presentation/screens/disputes_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/components/loading_state.dart';
import '../../domain/entities/dispute_entity.dart';
import '../providers/disputes_providers.dart';
import '../widgets/dispute_tile.dart';
import '../widgets/dispute_status_badge.dart';

class DisputesListScreen extends ConsumerStatefulWidget {
  const DisputesListScreen({super.key});

  @override
  ConsumerState<DisputesListScreen> createState() => _DisputesListScreenState();
}

class _DisputesListScreenState extends ConsumerState<DisputesListScreen> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(disputesListNotifierProvider.notifier).fetchDisputes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(disputesListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Disputes'),
        elevation: 0,
        actions: [
          Badge(
            isLabelVisible: state.filters.hasActiveFilters,
            child: IconButton(
              icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
              tooltip: 'Filters',
              onPressed: () {
                setState(() => _showFilters = !_showFilters);
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          _StatsBar(stats: state.stats),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search disputes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(disputesListNotifierProvider.notifier).search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                ref.read(disputesListNotifierProvider.notifier).search(value);
              },
            ),
          ),

          // Filters panel
          if (_showFilters) _FiltersPanel(state: state),

          // Quick filter chips
          _QuickFilters(state: state),

          // Disputes list
          Expanded(
            child: _buildDisputesList(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputesList(BuildContext context, DisputesListState state) {
    if (state.isLoading && state.disputes.isEmpty) {
      return const ShimmerList(itemCount: 5, itemHeight: 80);
    }

    if (state.error != null && state.disputes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading disputes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(state.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(disputesListNotifierProvider.notifier).fetchDisputes(refresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.disputes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gavel_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No disputes found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (state.filters.hasActiveFilters)
              TextButton.icon(
                onPressed: () {
                  ref.read(disputesListNotifierProvider.notifier).clearFilters();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear filters'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(disputesListNotifierProvider.notifier).fetchDisputes(refresh: true);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200) {
            ref.read(disputesListNotifierProvider.notifier).loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: state.disputes.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.disputes.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final dispute = state.disputes[index];
            return DisputeTile(
              dispute: dispute,
              onTap: () {
                context.push('/disputes/${dispute.id}');
              },
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// STATS BAR
// ============================================================================

class _StatsBar extends StatelessWidget {
  final DisputeStats stats;

  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          _StatItem(
            icon: Icons.folder_open,
            value: '${stats.openDisputes}',
            label: 'Open',
            color: Colors.orange,
          ),
          const SizedBox(width: 16),
          _StatItem(
            icon: Icons.search,
            value: '${stats.investigatingDisputes}',
            label: 'Investigating',
            color: Colors.blue,
          ),
          const SizedBox(width: 16),
          _StatItem(
            icon: Icons.check_circle,
            value: '${stats.resolvedDisputes}',
            label: 'Resolved',
            color: Colors.green,
          ),
          const SizedBox(width: 16),
          _StatItem(
            icon: Icons.priority_high,
            value: '${stats.urgentDisputes}',
            label: 'Urgent',
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// FILTERS PANEL
// ============================================================================

class _FiltersPanel extends ConsumerWidget {
  final DisputesListState state;

  const _FiltersPanel({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filter
          Text(
            'Status',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: state.filters.status == null,
                onSelected: (_) {
                  ref.read(disputesListNotifierProvider.notifier).filterByStatus(null);
                },
              ),
              ...DisputeStatus.values.map((status) => FilterChip(
                    label: Text(status.displayName),
                    selected: state.filters.status == status,
                    onSelected: (_) {
                      ref.read(disputesListNotifierProvider.notifier).filterByStatus(
                            state.filters.status == status ? null : status,
                          );
                    },
                  )),
            ],
          ),
          const SizedBox(height: 16),

          // Type filter
          Text(
            'Type',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: state.filters.type == null,
                onSelected: (_) {
                  ref.read(disputesListNotifierProvider.notifier).filterByType(null);
                },
              ),
              ...DisputeType.values.map((type) => FilterChip(
                    label: Text(type.displayName),
                    selected: state.filters.type == type,
                    onSelected: (_) {
                      ref.read(disputesListNotifierProvider.notifier).filterByType(
                            state.filters.type == type ? null : type,
                          );
                    },
                  )),
            ],
          ),
          const SizedBox(height: 16),

          // Priority filter
          Text(
            'Priority',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: state.filters.priority == null,
                onSelected: (_) {
                  ref.read(disputesListNotifierProvider.notifier).filterByPriority(null);
                },
              ),
              ...DisputePriority.values.map((priority) => FilterChip(
                    label: Text(priority.displayName),
                    selected: state.filters.priority == priority,
                    onSelected: (_) {
                      ref.read(disputesListNotifierProvider.notifier).filterByPriority(
                            state.filters.priority == priority ? null : priority,
                          );
                    },
                  )),
            ],
          ),
          const SizedBox(height: 16),

          // Date range
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDateRange(context, ref),
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    state.filters.startDate != null && state.filters.endDate != null
                        ? '${DateFormat.MMMd().format(state.filters.startDate!)} - ${DateFormat.MMMd().format(state.filters.endDate!)}'
                        : 'Select Date Range',
                  ),
                ),
              ),
              if (state.filters.startDate != null || state.filters.endDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    ref.read(disputesListNotifierProvider.notifier).filterByDateRange(null, null);
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Clear all filters
          if (state.filters.hasActiveFilters)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  ref.read(disputesListNotifierProvider.notifier).clearFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All Filters'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final state = ref.read(disputesListNotifierProvider);
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: state.filters.startDate != null && state.filters.endDate != null
          ? DateTimeRange(
              start: state.filters.startDate!,
              end: state.filters.endDate!,
            )
          : null,
    );

    if (result != null) {
      ref.read(disputesListNotifierProvider.notifier).filterByDateRange(
            result.start,
            result.end,
          );
    }
  }
}

// ============================================================================
// QUICK FILTERS
// ============================================================================

class _QuickFilters extends ConsumerWidget {
  final DisputesListState state;

  const _QuickFilters({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            avatar: const Icon(Icons.person, size: 18),
            label: const Text('Assigned to me'),
            selected: state.filters.assignedToMe == true,
            onSelected: (selected) {
              ref.read(disputesListNotifierProvider.notifier).filterAssignedToMe(selected);
            },
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.priority_high, size: 18),
            label: const Text('Urgent Only'),
            onPressed: () {
              ref.read(disputesListNotifierProvider.notifier).filterByPriority(
                    state.filters.priority == DisputePriority.urgent
                        ? null
                        : DisputePriority.urgent,
                  );
            },
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.folder_open, size: 18),
            label: const Text('Open Only'),
            onPressed: () {
              ref.read(disputesListNotifierProvider.notifier).filterByStatus(
                    state.filters.status == DisputeStatus.open
                        ? null
                        : DisputeStatus.open,
                  );
            },
          ),
        ],
      ),
    );
  }
}
