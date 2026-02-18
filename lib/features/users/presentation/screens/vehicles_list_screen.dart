// lib/features/users/presentation/screens/vehicles_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/vehicle_providers.dart';
import '../widgets/vehicle_card.dart';

/// Screen displaying a list of all vehicles with filtering and search
class VehiclesListScreen extends ConsumerStatefulWidget {
  const VehiclesListScreen({super.key});

  @override
  ConsumerState<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends ConsumerState<VehiclesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _tabs = [
    'All',
    'Pending',
    'Under Review',
    'Docs Requested',
    'Approved',
    'Rejected',
    'Suspended',
  ];
  final Map<String, String> _tabValues = {
    'All': 'all',
    'Pending': 'pending',
    'Under Review': 'under_review',
    'Docs Requested': 'documents_requested',
    'Approved': 'approved',
    'Rejected': 'rejected',
    'Suspended': 'suspended',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vehiclesListControllerProvider.notifier).loadVehicles(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tabValue = _tabValues[_tabs[_tabController.index]]!;
    ref.read(vehiclesListControllerProvider.notifier).changeTab(tabValue);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(vehiclesListControllerProvider.notifier).loadMore();
    }
  }

  void _onSearch(String query) {
    ref.read(vehiclesListControllerProvider.notifier).setSearchQuery(query);
  }

  Future<void> _onRefresh() async {
    await ref.read(vehiclesListControllerProvider.notifier).refresh();
  }

  void _navigateToVehicle(String vehicleId) {
    context.push('/users/vehicle/$vehicleId');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(vehiclesListControllerProvider);
    final countsAsync = ref.watch(vehicleCountsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Vehicle Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by make, model, or plate...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: _onSearch,
                ),
              ),

              // Tab bar with counts
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: _tabs.map((tab) {
                  final tabValue = _tabValues[tab]!;
                  return countsAsync.when(
                    data: (counts) {
                      final count = counts[tabValue] ?? 0;
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tab),
                            if (count > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getTabBadgeColor(tabValue, colorScheme),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  count > 99 ? '99+' : count.toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getTabBadgeTextColor(tabValue),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    loading: () => Tab(text: tab),
                    error: (_, __) => Tab(text: tab),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(context, state),
    );
  }

  Color _getTabBadgeColor(String tabValue, ColorScheme colorScheme) {
    switch (tabValue) {
      case 'pending':
        return Colors.orange.withValues(alpha: 0.2);
      case 'under_review':
        return Colors.blue.withValues(alpha: 0.2);
      case 'documents_requested':
        return Colors.purple.withValues(alpha: 0.2);
      case 'approved':
        return Colors.green.withValues(alpha: 0.2);
      case 'rejected':
        return colorScheme.error.withValues(alpha: 0.2);
      case 'suspended':
        return Colors.brown.withValues(alpha: 0.2);
      default:
        return colorScheme.primary.withValues(alpha: 0.2);
    }
  }

  Color _getTabBadgeTextColor(String tabValue) {
    switch (tabValue) {
      case 'pending':
        return Colors.orange[800]!;
      case 'under_review':
        return Colors.blue[800]!;
      case 'documents_requested':
        return Colors.purple[800]!;
      case 'approved':
        return Colors.green[800]!;
      case 'rejected':
        return Colors.red[800]!;
      case 'suspended':
        return Colors.brown[800]!;
      default:
        return Colors.blue[800]!;
    }
  }

  Widget _buildBody(BuildContext context, VehiclesListState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state.isLoading && state.vehicles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading vehicles', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'No vehicles match your search'
                  : 'No ${state.currentTab == "all" ? "" : state.currentTab} vehicles',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (state.searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearch('');
                },
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.vehicles.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.vehicles.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final vehicle = state.vehicles[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: VehicleCard(
              vehicle: vehicle,
              onTap: () => _navigateToVehicle(vehicle.id),
            ),
          );
        },
      ),
    );
  }
}
