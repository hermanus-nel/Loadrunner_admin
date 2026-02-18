// lib/features/analytics/presentation/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/date_range.dart';
import '../providers/analytics_providers.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/metric_card.dart';
import '../widgets/revenue_chart.dart';
import '../widgets/shipments_chart.dart';
import '../widgets/ratings_chart.dart';

/// Main analytics screen with tabs for Activity, Financial, and Performance metrics
class AnalyticsScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const AnalyticsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(analyticsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Analytics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: state.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: state.isLoading
                ? null
                : () => ref.read(analyticsNotifierProvider.notifier).loadAllMetrics(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Date range selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DateRangeSelector(
                  selectedRange: state.dateRange,
                  onRangeChanged: (range) {
                    ref.read(analyticsNotifierProvider.notifier).setDateRange(range);
                  },
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Activity'),
                  Tab(text: 'Financial'),
                  Tab(text: 'Performance'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ActivityTab(),
          _FinancialTab(),
          _PerformanceTab(),
        ],
      ),
    );
  }
}

/// Activity Metrics Tab
class _ActivityTab extends ConsumerWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoading = ref.watch(isLoadingActivityProvider);
    final metrics = ref.watch(activityMetricsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(analyticsNotifierProvider.notifier).refreshActivity(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User stats summary
          SectionHeader(
            title: 'User Statistics',
          ),
          const SizedBox(height: 12),
          MetricCardsRow(
            isLoading: isLoading,
            metrics: [
              MetricCardData(
                label: 'Total Users',
                value: metrics.userStats.totalUsers.toString(),
                icon: Icons.people_outline,
                iconColor: colorScheme.primary,
              ),
              MetricCardData(
                label: 'Drivers',
                value: metrics.userStats.totalDrivers.toString(),
                icon: Icons.local_shipping_outlined,
                iconColor: Colors.blue,
              ),
              MetricCardData(
                label: 'Shippers',
                value: metrics.userStats.totalShippers.toString(),
                icon: Icons.business_outlined,
                iconColor: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          MetricCardsRow(
            isLoading: isLoading,
            metrics: [
              MetricCardData(
                label: 'Verified Drivers',
                value: metrics.userStats.verifiedDrivers.toString(),
                icon: Icons.verified_outlined,
                iconColor: Colors.green,
              ),
              MetricCardData(
                label: 'Active Today',
                value: metrics.userStats.activeUsersToday.toString(),
                icon: Icons.person_outline,
                iconColor: Colors.purple,
              ),
              MetricCardData(
                label: 'New This Week',
                value: metrics.userStats.newUsersThisWeek.toString(),
                icon: Icons.person_add_outlined,
                iconColor: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Shipments by status
          SectionHeader(
            title: 'Shipments by Status',
          ),
          const SizedBox(height: 12),
          ChartCard(
            title: 'Status Distribution',
            height: 200,
            isLoading: isLoading,
            chart: ShipmentsByStatusChart(data: metrics.shipmentsByStatus),
          ),
          const SizedBox(height: 24),

          // Daily shipments chart
          SectionHeader(
            title: 'Daily Shipments',
          ),
          const SizedBox(height: 12),
          ChartCard(
            title: 'Shipments by Day',
            height: 220,
            isLoading: isLoading,
            chart: ShipmentsBarChart(data: metrics.dailyShipments),
          ),
          const SizedBox(height: 24),

          // Bid statistics
          SectionHeader(
            title: 'Bid Statistics',
          ),
          const SizedBox(height: 12),
          MetricCardsRow(
            isLoading: isLoading,
            metrics: [
              MetricCardData(
                label: 'Total Bids',
                value: metrics.totalBids.toString(),
                icon: Icons.gavel_outlined,
                iconColor: colorScheme.primary,
              ),
              MetricCardData(
                label: 'Avg Bids/Shipment',
                value: metrics.avgBidsPerShipment.toStringAsFixed(1),
                icon: Icons.analytics_outlined,
                iconColor: Colors.indigo,
              ),
              MetricCardData(
                label: 'Acceptance Rate',
                value: '${metrics.bidAcceptanceRate.toStringAsFixed(1)}%',
                icon: Icons.check_circle_outline,
                iconColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Daily active users
          SectionHeader(
            title: 'Daily Active Users',
          ),
          const SizedBox(height: 12),
          ChartCard(
            title: 'Active Users',
            height: 250,
            isLoading: isLoading,
            chart: ActiveUsersChart(data: metrics.dailyActiveUsers),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Financial Metrics Tab
class _FinancialTab extends ConsumerWidget {
  const _FinancialTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoading = ref.watch(isLoadingFinancialProvider);
    final metrics = ref.watch(financialMetricsProvider);
    final summary = metrics.revenueSummary;

    return RefreshIndicator(
      onRefresh: () => ref.read(analyticsNotifierProvider.notifier).refreshFinancial(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Revenue summary
          SectionHeader(
            title: 'Revenue Summary',
          ),
          const SizedBox(height: 12),
          MetricCardsRow(
            isLoading: isLoading,
            metrics: [
              MetricCardData(
                label: 'Total Revenue',
                value: summary.formatAmount(summary.totalRevenue),
                icon: Icons.attach_money,
                iconColor: Colors.green,
              ),
              MetricCardData(
                label: 'Commission',
                value: summary.formatAmount(summary.totalCommission),
                icon: Icons.percent,
                iconColor: colorScheme.primary,
              ),
              MetricCardData(
                label: 'Transactions',
                value: summary.totalTransactions.toString(),
                icon: Icons.receipt_outlined,
                iconColor: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 8),
          MetricCardsRow(
            isLoading: isLoading,
            metrics: [
              MetricCardData(
                label: 'Today',
                value: summary.formatAmount(summary.todayRevenue),
                icon: Icons.today_outlined,
                iconColor: Colors.teal,
              ),
              MetricCardData(
                label: 'This Week',
                value: summary.formatAmount(summary.thisWeekRevenue),
                icon: Icons.date_range_outlined,
                iconColor: Colors.indigo,
              ),
              MetricCardData(
                label: 'Avg Transaction',
                value: summary.formatAmount(summary.averageTransactionValue),
                icon: Icons.trending_up,
                iconColor: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Revenue over time
          SectionHeader(
            title: 'Revenue Trend',
          ),
          const SizedBox(height: 12),
          ChartCard(
            title: 'Revenue Over Time',
            height: 220,
            isLoading: isLoading,
            chart: RevenueChart(
              data: metrics.dailyRevenue,
              showCommission: true,
            ),
          ),
          const SizedBox(height: 24),

          // Payments by status
          SectionHeader(
            title: 'Payments by Status',
          ),
          const SizedBox(height: 12),
          ChartCard(
            title: 'Payment Status',
            height: 200,
            isLoading: isLoading,
            chart: PaymentsPieChart(data: metrics.paymentsByStatus),
          ),
          const SizedBox(height: 8),
          MetricCardsRow(
            isLoading: isLoading,
            metrics: [
              MetricCardData(
                label: 'Success Rate',
                value: '${metrics.paymentSuccessRate.toStringAsFixed(1)}%',
                icon: Icons.check_circle_outline,
                iconColor: Colors.green,
              ),
              MetricCardData(
                label: 'Outstanding',
                value: summary.formatAmount(metrics.outstandingPayments),
                icon: Icons.pending_outlined,
                iconColor: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Top drivers
          if (metrics.topDrivers.isNotEmpty) ...[
            SectionHeader(
              title: 'Top Earning Drivers',
            ),
            const SizedBox(height: 12),
            _TopEarnersCard(
              earners: metrics.topDrivers,
              isLoading: isLoading,
              icon: Icons.local_shipping,
            ),
            const SizedBox(height: 24),
          ],

          // Top shippers
          if (metrics.topShippers.isNotEmpty) ...[
            SectionHeader(
              title: 'Top Spending Shippers',
            ),
            const SizedBox(height: 12),
            _TopEarnersCard(
              earners: metrics.topShippers,
              isLoading: isLoading,
              icon: Icons.business,
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Performance Metrics Tab
class _PerformanceTab extends ConsumerWidget {
  const _PerformanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoading = ref.watch(isLoadingPerformanceProvider);
    final metrics = ref.watch(performanceMetricsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(analyticsNotifierProvider.notifier).refreshPerformance(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Platform health
          SectionHeader(
            title: 'Platform Health',
          ),
          const SizedBox(height: 12),
          MetricCardsRow(
            isLoading: isLoading,
            metrics: [
              MetricCardData(
                label: 'Success Rate',
                value: '${metrics.platformHealth.overallSuccessRate.toStringAsFixed(1)}%',
                icon: Icons.verified_outlined,
                iconColor: Colors.green,
              ),
              MetricCardData(
                label: 'Satisfaction',
                value: '${metrics.platformHealth.customerSatisfactionScore.toStringAsFixed(0)}%',
                icon: Icons.sentiment_satisfied_outlined,
                iconColor: Colors.blue,
              ),
              MetricCardData(
                label: 'Active Disputes',
                value: metrics.platformHealth.activeDisputesCount.toString(),
                icon: Icons.report_problem_outlined,
                iconColor: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          MetricCardsRow(
            isLoading: isLoading,
            metrics: [
              MetricCardData(
                label: 'Cancellation Rate',
                value: '${metrics.platformHealth.cancellationRate.toStringAsFixed(1)}%',
                icon: Icons.cancel_outlined,
                iconColor: Colors.red,
              ),
              MetricCardData(
                label: 'Resolution Time',
                value: metrics.timeMetrics.formatHours(
                    metrics.platformHealth.issueResolutionTimeHours),
                icon: Icons.timer_outlined,
                iconColor: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Ratings distribution
          SectionHeader(
            title: 'Ratings Distribution',
          ),
          const SizedBox(height: 12),
          ChartCard(
            title: 'Rating Distribution',
            height: 200,
            isLoading: isLoading,
            chart: RatingsBarChart(data: metrics.ratingsDistribution),
          ),
          const SizedBox(height: 12),
          // Ratings summary
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: RatingsSummary(data: metrics.ratingsDistribution),
            ),
          ),
          const SizedBox(height: 24),

          // Time metrics
          SectionHeader(
            title: 'Time Metrics',
          ),
          const SizedBox(height: 12),
          MetricCardsRow(
            isLoading: isLoading,
            metrics: [
              MetricCardData(
                label: 'Avg Delivery Time',
                value: metrics.timeMetrics
                    .formatHours(metrics.timeMetrics.averageDeliveryTimeHours),
                icon: Icons.local_shipping_outlined,
                iconColor: colorScheme.primary,
              ),
              MetricCardData(
                label: 'Avg Pickup Time',
                value: metrics.timeMetrics
                    .formatHours(metrics.timeMetrics.averagePickupTimeHours),
                icon: Icons.inventory_2_outlined,
                iconColor: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 8),
          MetricCardsRow(
            isLoading: isLoading,
            metrics: [
              MetricCardData(
                label: 'Response Time',
                value: metrics.timeMetrics
                    .formatMinutes(metrics.timeMetrics.averageResponseTimeMinutes),
                icon: Icons.speed_outlined,
                iconColor: Colors.orange,
              ),
              MetricCardData(
                label: 'On-Time Rate',
                value: '${metrics.timeMetrics.onTimeDeliveryRate.toStringAsFixed(1)}%',
                icon: Icons.schedule_outlined,
                iconColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Driver performance
          SectionHeader(
            title: 'Driver Performance',
          ),
          const SizedBox(height: 12),
          MetricCardsRow(
            isLoading: isLoading,
            metrics: [
              MetricCardData(
                label: 'Avg Rating',
                value: metrics.driverPerformance.averageRating.toStringAsFixed(1),
                icon: Icons.star_outline,
                iconColor: Colors.amber,
              ),
              MetricCardData(
                label: 'Top Rated',
                value: metrics.driverPerformance.topRatedCount.toString(),
                icon: Icons.emoji_events_outlined,
                iconColor: Colors.green,
                subtitle: '4.5+ rating',
              ),
              MetricCardData(
                label: 'Low Rated',
                value: metrics.driverPerformance.lowRatedCount.toString(),
                icon: Icons.warning_amber_outlined,
                iconColor: Colors.red,
                subtitle: '< 3.0 rating',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Low rated users needing attention
          if (metrics.lowRatedDrivers.isNotEmpty) ...[
            SectionHeader(
              title: 'Drivers Needing Attention',
            ),
            const SizedBox(height: 12),
            _LowRatedUsersCard(
              users: metrics.lowRatedDrivers,
              isLoading: isLoading,
            ),
            const SizedBox(height: 24),
          ],

          if (metrics.lowRatedShippers.isNotEmpty) ...[
            SectionHeader(
              title: 'Shippers Needing Attention',
            ),
            const SizedBox(height: 12),
            _LowRatedUsersCard(
              users: metrics.lowRatedShippers,
              isLoading: isLoading,
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Card showing top earners
class _TopEarnersCard extends StatelessWidget {
  final List<dynamic> earners;
  final bool isLoading;
  final IconData icon;

  const _TopEarnersCard({
    required this.earners,
    required this.isLoading,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return Card(
        elevation: 0,
        child: Container(
          height: 150,
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: earners.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
        itemBuilder: (context, index) {
          final earner = earners[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            title: Text(
              earner.name as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Text(
              'R${earner.totalEarnings.toStringAsFixed(0)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Card showing low rated users
class _LowRatedUsersCard extends StatelessWidget {
  final List<dynamic> users;
  final bool isLoading;

  const _LowRatedUsersCard({
    required this.users,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return Card(
        elevation: 0,
        child: Container(
          height: 150,
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: users.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade50,
              child: Icon(
                Icons.warning_amber,
                color: Colors.red.shade700,
                size: 20,
              ),
            ),
            title: Text(
              user.name as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '${user.totalRatings} ratings',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  (user.averageRating as num).toStringAsFixed(1),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
