// lib/features/users/presentation/screens/drivers_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/components/loading_state.dart';
import '../providers/drivers_providers.dart';
import '../widgets/driver_list_tile.dart';
import '../widgets/search_header.dart';
import '../widgets/status_badge.dart';

/// Screen displaying list of drivers with tabs for filtering by status
class DriversListScreen extends ConsumerStatefulWidget {
  const DriversListScreen({super.key});

  @override
  ConsumerState<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends ConsumerState<DriversListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: DriverTab.values.length,
      vsync: this,
      initialIndex: DriverTab.pending.index, // Start on Pending tab
    );

    // Listen to tab changes
    _tabController.addListener(_onTabChanged);

    // Listen to scroll for pagination
    _scrollController.addListener(_onScroll);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    final tab = DriverTab.values[_tabController.index];
    ref.read(driversListNotifierProvider.notifier).setTab(tab);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(driversListNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driversState = ref.watch(driversListNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Drivers'),
        actions: [
          IconButton(
            icon: driversState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: driversState.isLoading
                ? null
                : () => ref.read(driversListNotifierProvider.notifier).refresh(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabBar(context, driversState, isDark),
        ),
      ),
      body: Column(
        children: [
          // Search header
          SearchHeader(
            hintText: 'Search drivers by name, phone, or email...',
            initialValue: driversState.searchQuery,
            onSearchChanged: (query) {
              ref.read(driversListNotifierProvider.notifier).setSearchQuery(query);
            },
          ),

          // Error banner
          if (driversState.hasError)
            _buildErrorBanner(context, driversState.error!),

          // Drivers list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(driversListNotifierProvider.notifier).refresh();
              },
              child: _buildDriversList(context, driversState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(
    BuildContext context, 
    DriversListState state, 
    bool isDark,
  ) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: isDark ? AppColors.borderDark : AppColors.borderLight,
      tabs: DriverTab.values.map((tab) {
        final count = state.getCountForTab(tab);
        final isSelected = state.currentTab == tab;

        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tab.label),
              if (count > 0) ...[
                const SizedBox(width: 6),
                _CountBadge(
                  count: count,
                  isSelected: isSelected,
                  color: tab == DriverTab.pending ? AppColors.warning : null,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String error) {
    return Container(
      width: double.infinity,
      padding: AppDimensions.cardPaddingCompact,
      color: AppColors.errorLight.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.errorLight,
            size: 20,
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.errorLight,
                  ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(driversListNotifierProvider.notifier).refresh();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDriversList(BuildContext context, DriversListState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Loading state
    if (state.isLoading && state.drivers.isEmpty) {
      return const ShimmerList(itemCount: 6, itemHeight: 72);
    }

    // Empty state
    if (state.isEmpty) {
      return _buildEmptyState(context, state, isDark);
    }

    // Drivers list
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
      itemCount: state.drivers.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading more indicator
        if (index == state.drivers.length) {
          return const Padding(
            padding: EdgeInsets.all(AppDimensions.spacingMd),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final driver = state.drivers[index];
        return DriverListTile(
          driver: driver,
          onTap: () => _onDriverTap(driver.id),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context, 
    DriversListState state, 
    bool isDark,
  ) {
    String message;
    IconData icon;

    if (state.searchQuery.isNotEmpty) {
      message = 'No drivers found matching "${state.searchQuery}"';
      icon = Icons.search_off;
    } else {
      switch (state.currentTab) {
        case DriverTab.pending:
          message = 'No pending driver approvals';
          icon = Icons.check_circle_outline;
          break;
        case DriverTab.approved:
          message = 'No approved drivers yet';
          icon = Icons.people_outline;
          break;
        case DriverTab.rejected:
          message = 'No rejected drivers';
          icon = Icons.block_outlined;
          break;
        case DriverTab.all:
          message = 'No drivers registered yet';
          icon = Icons.person_add_outlined;
          break;
      }
    }

    return Center(
      child: Padding(
        padding: AppDimensions.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
              textAlign: TextAlign.center,
            ),
            if (state.searchQuery.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spacingMd),
              TextButton.icon(
                onPressed: () {
                  ref.read(driversListNotifierProvider.notifier).clearSearch();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear search'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onDriverTap(String driverId) {
    context.push('/users/driver/$driverId');
  }
}

/// Content-only version of DriversListScreen for embedding in tabs
/// This excludes the AppBar since it's meant to be used within another Scaffold
class DriversListScreenContent extends ConsumerStatefulWidget {
  const DriversListScreenContent({super.key});

  @override
  ConsumerState<DriversListScreenContent> createState() =>
      _DriversListScreenContentState();
}

class _DriversListScreenContentState
    extends ConsumerState<DriversListScreenContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: DriverTab.values.length,
      vsync: this,
      initialIndex: DriverTab.pending.index,
    );

    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = DriverTab.values[_tabController.index];
    ref.read(driversListNotifierProvider.notifier).setTab(tab);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(driversListNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driversState = ref.watch(driversListNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Status tabs
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: DriverTab.values.map((tab) {
              final count = driversState.getCountForTab(tab);
              final isSelected = driversState.currentTab == tab;

              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tab.label),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      _CountBadge(
                        count: count,
                        isSelected: isSelected,
                        color: tab == DriverTab.pending ? AppColors.warning : null,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // Search header
        SearchHeader(
          hintText: 'Search drivers...',
          initialValue: driversState.searchQuery,
          onSearchChanged: (query) {
            ref.read(driversListNotifierProvider.notifier).setSearchQuery(query);
          },
        ),

        // Error banner
        if (driversState.hasError)
          Container(
            width: double.infinity,
            padding: AppDimensions.cardPaddingCompact,
            color: AppColors.errorLight.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.errorLight,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spacingSm),
                Expanded(
                  child: Text(
                    driversState.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.errorLight,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(driversListNotifierProvider.notifier).refresh();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),

        // Drivers list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(driversListNotifierProvider.notifier).refresh();
            },
            child: _buildDriversList(context, driversState, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildDriversList(
    BuildContext context,
    DriversListState state,
    bool isDark,
  ) {
    // Loading state
    if (state.isLoading && state.drivers.isEmpty) {
      return const ShimmerList(itemCount: 6, itemHeight: 72);
    }

    // Empty state
    if (state.isEmpty) {
      return _buildEmptyState(context, state, isDark);
    }

    // Drivers list
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
      itemCount: state.drivers.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.drivers.length) {
          return const Padding(
            padding: EdgeInsets.all(AppDimensions.spacingMd),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final driver = state.drivers[index];
        return DriverListTile(
          driver: driver,
          onTap: () => _onDriverTap(driver.id),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    DriversListState state,
    bool isDark,
  ) {
    String message;
    IconData icon;

    if (state.searchQuery.isNotEmpty) {
      message = 'No drivers found matching "${state.searchQuery}"';
      icon = Icons.search_off;
    } else {
      switch (state.currentTab) {
        case DriverTab.pending:
          message = 'No pending driver approvals';
          icon = Icons.check_circle_outline;
          break;
        case DriverTab.approved:
          message = 'No approved drivers yet';
          icon = Icons.people_outline;
          break;
        case DriverTab.rejected:
          message = 'No rejected drivers';
          icon = Icons.block_outlined;
          break;
        case DriverTab.all:
          message = 'No drivers registered yet';
          icon = Icons.person_add_outlined;
          break;
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
            textAlign: TextAlign.center,
          ),
          if (state.searchQuery.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            TextButton.icon(
              onPressed: () {
                ref.read(driversListNotifierProvider.notifier).clearSearch();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }

  void _onDriverTap(String driverId) {
    context.push('/users/driver/$driverId');
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final bool isSelected;
  final Color? color;

  const _CountBadge({
    required this.count,
    this.isSelected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? badgeColor : badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : badgeColor,
        ),
      ),
    );
  }
}
