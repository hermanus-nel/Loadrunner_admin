// lib/features/shippers/presentation/screens/shippers_list_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/shipper_entity.dart';
import '../providers/shippers_providers.dart';
import '../widgets/shipper_tile.dart';

class ShippersListScreen extends ConsumerWidget {
  const ShippersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Shippers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(shippersListNotifierProvider.notifier).fetchShippers(refresh: true);
              ref.read(shippersListNotifierProvider.notifier).fetchOverviewStats();
            },
          ),
        ],
      ),
      body: const ShippersListScreenContent(),
    );
  }
}

/// Content-only version of ShippersListScreen for embedding in tabs.
/// This excludes the AppBar since it's meant to be used within another Scaffold.
class ShippersListScreenContent extends ConsumerStatefulWidget {
  const ShippersListScreenContent({super.key});

  @override
  ConsumerState<ShippersListScreenContent> createState() => _ShippersListScreenContentState();
}

class _ShippersListScreenContentState extends ConsumerState<ShippersListScreenContent> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Fetch shippers on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shippersListNotifierProvider.notifier).fetchShippers(refresh: true);
      ref.read(shippersListNotifierProvider.notifier).fetchOverviewStats();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(shippersListNotifierProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(shippersListNotifierProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(shippersListNotifierProvider);

    return Column(
      children: [
        // Stats bar
        if (state.overviewStats != null) _buildStatsBar(state.overviewStats!),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, email, or phone...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(shippersListNotifierProvider.notifier).search(null);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // Filter toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ActionChip(
                avatar: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  size: 18,
                ),
                label: Text(_showFilters ? 'Hide Filters' : 'Filters'),
                onPressed: () {
                  setState(() => _showFilters = !_showFilters);
                },
              ),
              if (state.filters.hasActiveFilters) ...[
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear'),
                  onPressed: () {
                    ref.read(shippersListNotifierProvider.notifier).clearFilters();
                  },
                ),
              ],
            ],
          ),
        ),

        // Filters panel
        if (_showFilters) _buildFiltersPanel(),

        // Quick filters
        _buildQuickFilters(state.filters),

        // List
        Expanded(
          child: _buildList(state),
        ),
      ],
    );
  }

  Widget _buildStatsBar(ShippersOverviewStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.people,
            value: '${stats.totalShippers}',
            label: 'Total',
            color: Colors.blue,
          ),
          _StatItem(
            icon: Icons.check_circle,
            value: '${stats.activeShippers}',
            label: 'Active',
            color: Colors.green,
          ),
          _StatItem(
            icon: Icons.block,
            value: '${stats.suspendedShippers}',
            label: 'Suspended',
            color: Colors.red,
          ),
          _StatItem(
            icon: Icons.person_add,
            value: '${stats.newThisWeek}',
            label: 'New/Week',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    final theme = Theme.of(context);
    final state = ref.watch(shippersListNotifierProvider);
    final filters = state.filters;

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
          Text(
            'Status',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ...ShipperStatus.values.map((status) => FilterChip(
                    selected: filters.status == status,
                    label: Text(status.displayName),
                    onSelected: (selected) {
                      ref
                          .read(shippersListNotifierProvider.notifier)
                          .filterByStatus(selected ? status : null);
                    },
                  )),
            ],
          ),
          const SizedBox(height: 16),

          // Sort by
          Text(
            'Sort By',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ...ShipperSortBy.values.map((sortBy) => ChoiceChip(
                    selected: filters.sortBy == sortBy,
                    label: Text(sortBy.displayName),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(shippersListNotifierProvider.notifier).sortBy(sortBy);
                      }
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
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    filters.registeredAfter != null
                        ? 'From: ${DateFormat.MMMd().format(filters.registeredAfter!)}'
                        : 'Start Date',
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: filters.registeredAfter ?? DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      ref
                          .read(shippersListNotifierProvider.notifier)
                          .filterByDateRange(date, filters.registeredBefore);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    filters.registeredBefore != null
                        ? 'To: ${DateFormat.MMMd().format(filters.registeredBefore!)}'
                        : 'End Date',
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: filters.registeredBefore ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      ref
                          .read(shippersListNotifierProvider.notifier)
                          .filterByDateRange(filters.registeredAfter, date);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Clear filters
          if (filters.hasActiveFilters)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All Filters'),
                onPressed: () {
                  ref.read(shippersListNotifierProvider.notifier).clearFilters();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(ShipperFilters filters) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              selected: filters.status == ShipperStatus.active,
              label: const Text('Active Only'),
              onSelected: (selected) {
                ref
                    .read(shippersListNotifierProvider.notifier)
                    .filterByStatus(selected ? ShipperStatus.active : null);
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              selected: filters.status == ShipperStatus.suspended,
              label: const Text('Suspended'),
              onSelected: (selected) {
                ref
                    .read(shippersListNotifierProvider.notifier)
                    .filterByStatus(selected ? ShipperStatus.suspended : null);
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              selected: filters.status == ShipperStatus.inactive,
              label: const Text('Inactive (30d+)'),
              onSelected: (selected) {
                ref
                    .read(shippersListNotifierProvider.notifier)
                    .filterByStatus(selected ? ShipperStatus.inactive : null);
              },
            ),
            const SizedBox(width: 8),
            ActionChip(
              avatar: Icon(
                filters.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
              ),
              label: Text(filters.sortBy.displayName),
              onPressed: () {
                ref
                    .read(shippersListNotifierProvider.notifier)
                    .sortBy(filters.sortBy, ascending: !filters.sortAscending);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ShippersListState state) {
    final theme = Theme.of(context);

    if (state.isLoading && state.shippers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.shippers.isEmpty) {
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
              'Error loading shippers',
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
                ref.read(shippersListNotifierProvider.notifier).fetchShippers(refresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.shippers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              state.filters.hasActiveFilters
                  ? 'No shippers match your filters'
                  : 'No shippers found',
              style: theme.textTheme.titleMedium,
            ),
            if (state.filters.hasActiveFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ref.read(shippersListNotifierProvider.notifier).clearFilters();
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
        await ref.read(shippersListNotifierProvider.notifier).fetchShippers(refresh: true);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        itemCount: state.shippers.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.shippers.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final shipper = state.shippers[index];
          return ShipperTile(
            shipper: shipper,
            onTap: () => context.push('/shippers/${shipper.id}'),
          );
        },
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
