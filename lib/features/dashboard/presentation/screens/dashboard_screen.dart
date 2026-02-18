// lib/features/dashboard/presentation/screens/dashboard_screen.dart

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/dashboard_stats.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_actions_section.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../../../../core/navigation/app_router.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(dashboardNotifierProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      notifier.resumeAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      notifier.pauseAutoRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardNotifierProvider.notifier).fullRefresh();
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              centerTitle: true,
              leading: dashboardState.lastRefresh != null
                  ? _RefreshCountdown(
                      lastRefresh: dashboardState.lastRefresh!,
                      interval: dashboardState.refreshInterval,
                    )
                  : null,
              leadingWidth: 72,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer.withOpacity(0.5),
                        colorScheme.surface,
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                // Notification bell with unread badge
                NotificationBadge(
                  onTap: () => context.push(AppRoutes.notifications),
                ),
                // Refresh button: tap to refresh, long-press for interval settings
                GestureDetector(
                  onLongPress: () => _showRefreshIntervalSheet(
                    context,
                    dashboardState.refreshInterval,
                  ),
                  child: IconButton(
                    icon: dashboardState.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    onPressed: dashboardState.isLoading
                        ? null
                        : () {
                            ref
                                .read(dashboardNotifierProvider.notifier)
                                .fullRefresh();
                          },
                  ),
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    _buildWelcomeHeader(context, dashboardState),
                    const SizedBox(height: 24),

                    // Error Message (if any)
                    if (dashboardState.hasError) ...[
                      _buildErrorBanner(context, ref, dashboardState.error!),
                      const SizedBox(height: 16),
                    ],

                    _buildTodayStatsGrid(context, dashboardState),
                    const SizedBox(height: 24),

                    // Weekly Stats Card
                    Text(
                      'Weekly Performance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    WeeklyStatsCard(
                      stats: dashboardState.stats.weeklyStats,
                      revenueTrend: dashboardState.stats.revenueTrend,
                      shipmentsTrend:
                          dashboardState.stats.completedShipmentsTrend,
                      isLoading: dashboardState.isLoadingTrends,
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    QuickActionsSection(
                      pendingDrivers: dashboardState.stats.pendingDriverApprovals,
                      pendingDisputes: dashboardState.stats.pendingDisputes,
                      onReviewDrivers: () => context.go('/users'),
                      onViewShipments: () => context.go('/analytics'),
                      onHandleDisputes: () => context.go('/disputes'),
                      onSendMessage: () => context.go('/messages'),
                    ),
                    const SizedBox(height: 24),

                    // Last refresh info
                    if (dashboardState.lastRefresh != null)
                      _LastRefreshInfo(
                        lastRefresh: dashboardState.lastRefresh!,
                        interval: dashboardState.refreshInterval,
                      ),
                    const SizedBox(height: 80), // Bottom padding for nav bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, DashboardState state) {
    final theme = Theme.of(context);
    final greeting = _getGreeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's what's happening today",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildErrorBanner(BuildContext context, WidgetRef ref, String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: colorScheme.onErrorContainer,
            ),
            onPressed: () {
              ref.read(dashboardNotifierProvider.notifier).clearError();
            },
          ),
        ],
      ),
    );
  }

  void _showRefreshIntervalSheet(BuildContext context, Duration current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _RefreshIntervalPicker(
        currentInterval: current,
        onChanged: (duration) {
          ref.read(dashboardNotifierProvider.notifier).setRefreshInterval(duration);
        },
      ),
    );
  }

  // ============================================================
  // PERIOD CYCLING HELPERS
  // ============================================================

  /// Display value for a cycling stat card.
  /// For day period, uses the existing stats value.
  /// For other periods, uses the fetched period value.
  String _periodDisplayValue(
    DashboardState state,
    StatMetric metric,
  ) {
    final pd = state.periodDataFor(metric);
    final dayValue = _dayValueFor(state, metric);
    final amount = pd.period == StatPeriod.day
        ? dayValue
        : (pd.value ?? 0);

    String formatted;
    if (metric == StatMetric.revenue) {
      formatted = _formatRevenue(amount);
    } else {
      formatted = amount.toInt().toString();
    }

    final suffix = pd.period.suffix;
    return suffix.isEmpty ? formatted : '$formatted $suffix';
  }

  double _dayValueFor(DashboardState state, StatMetric metric) {
    switch (metric) {
      case StatMetric.revenue:
        return state.stats.revenueToday;
      case StatMetric.shipments:
        return state.stats.activeShipments.toDouble();
      case StatMetric.registrations:
        return state.stats.newRegistrationsToday.toDouble();
      case StatMetric.activeUsers:
        return state.stats.activeUsers24h.toDouble();
    }
  }

  String _formatRevenue(double amount) {
    if (amount >= 1000000) {
      return 'R${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'R${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'R${amount.toStringAsFixed(0)}';
  }

  /// Returns sparkline data for the selected period.
  /// Day period uses the existing 7-day trend sparkline.
  List<TrendDataPoint> _sparklineFor(
    DashboardState state,
    StatMetric metric,
  ) {
    final pd = state.periodDataFor(metric);
    if (pd.period != StatPeriod.day) return pd.sparkline;

    // Day period: use existing trend sparkline
    switch (metric) {
      case StatMetric.revenue:
        return state.stats.revenueTrend.sparklineData;
      case StatMetric.shipments:
        return state.stats.activeShipmentsTrend.sparklineData;
      case StatMetric.registrations:
        return state.stats.registrationsTrend.sparklineData;
      case StatMetric.activeUsers:
        return state.stats.activeUsersTrend.sparklineData;
    }
  }

  /// Wraps sparkline data in a TrendIndicator (no percentage).
  TrendIndicator? _trendForPeriod(
    DashboardState state,
    StatMetric metric,
  ) {
    final sparkline = _sparklineFor(state, metric);
    if (sparkline.isEmpty) return null;
    return TrendIndicator(
      percentageChange: 0,
      isPositive: true,
      sparklineData: sparkline,
    );
  }

  Widget _buildTodayStatsGrid(BuildContext context, DashboardState state) {
    final stats = state.stats;
    final isLoading = state.isLoading;
    final notifier = ref.read(dashboardNotifierProvider.notifier);

    return Column(
      children: [
        // Row 1: Revenue | Shipments
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Revenue',
                value: _periodDisplayValue(state, StatMetric.revenue),
                icon: Icons.attach_money,
                color: Colors.green,
                trend: _trendForPeriod(state, StatMetric.revenue),
                showSparkline:
                    _sparklineFor(state, StatMetric.revenue).isNotEmpty,
                isLoading: isLoading ||
                    state.revenuePeriodData.isLoading,
                onTap: () => notifier.cyclePeriod(StatMetric.revenue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Shipments',
                value: _periodDisplayValue(state, StatMetric.shipments),
                icon: Icons.local_shipping_outlined,
                color: Colors.blue,
                trend: _trendForPeriod(state, StatMetric.shipments),
                showSparkline:
                    _sparklineFor(state, StatMetric.shipments).isNotEmpty,
                isLoading: isLoading ||
                    state.shipmentsPeriodData.isLoading,
                onTap: () => notifier.cyclePeriod(StatMetric.shipments),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Registrations | Active Users
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Registrations',
                value: _periodDisplayValue(state, StatMetric.registrations),
                icon: Icons.people_outline,
                color: Colors.purple,
                trend: _trendForPeriod(state, StatMetric.registrations),
                showSparkline:
                    _sparklineFor(state, StatMetric.registrations).isNotEmpty,
                isLoading: isLoading ||
                    state.registrationsPeriodData.isLoading,
                onTap: () => notifier.cyclePeriod(StatMetric.registrations),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Active Users',
                value: _periodDisplayValue(state, StatMetric.activeUsers),
                icon: Icons.trending_up,
                color: Colors.teal,
                trend: _trendForPeriod(state, StatMetric.activeUsers),
                showSparkline:
                    _sparklineFor(state, StatMetric.activeUsers).isNotEmpty,
                isLoading: isLoading ||
                    state.activeUsersPeriodData.isLoading,
                onTap: () => notifier.cyclePeriod(StatMetric.activeUsers),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: Pending Approvals | Pending Disputes
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Pending Approvals',
                value: stats.pendingDriverApprovals.toString(),
                icon: Icons.person_add_outlined,
                color: Colors.orange,
                trend: stats.pendingApprovalsTrend,
                isLoading: isLoading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Pending Disputes',
                value: stats.pendingDisputes.toString(),
                icon: Icons.warning_amber_outlined,
                color: Colors.red,
                trend: stats.disputesTrend,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

}

/// Isolated countdown widget that rebuilds only itself every second.
class _RefreshCountdown extends StatefulWidget {
  final DateTime lastRefresh;
  final Duration interval;

  const _RefreshCountdown({
    required this.lastRefresh,
    required this.interval,
  });

  @override
  State<_RefreshCountdown> createState() => _RefreshCountdownState();
}

class _RefreshCountdownState extends State<_RefreshCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown() {
    final elapsed = DateTime.now().difference(widget.lastRefresh).inSeconds;
    final total = widget.interval.inSeconds;
    final remaining = (total - elapsed).clamp(0, total);
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _formatCountdown(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Isolated last-refresh info widget that rebuilds only itself every second.
class _LastRefreshInfo extends StatefulWidget {
  final DateTime lastRefresh;
  final Duration interval;

  const _LastRefreshInfo({
    required this.lastRefresh,
    required this.interval,
  });

  @override
  State<_LastRefreshInfo> createState() => _LastRefreshInfoState();
}

class _LastRefreshInfoState extends State<_LastRefreshInfo> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeDiff = DateTime.now().difference(widget.lastRefresh);

    String timeAgo;
    if (timeDiff.inSeconds < 60) {
      timeAgo = 'Just now';
    } else if (timeDiff.inMinutes < 60) {
      timeAgo = '${timeDiff.inMinutes}m ago';
    } else {
      timeAgo = '${timeDiff.inHours}h ago';
    }

    final total = widget.interval.inSeconds;
    final remaining = (total - timeDiff.inSeconds).clamp(0, total);
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    final countdown = '${minutes}:${seconds.toString().padLeft(2, '0')}';

    return Center(
      child: Text(
        'Last updated: $timeAgo  \u2022  Next refresh: $countdown',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
      ),
    );
  }
}

/// Bottom sheet with a slider to configure auto-refresh interval (10s – 60min).
class _RefreshIntervalPicker extends StatefulWidget {
  final Duration currentInterval;
  final ValueChanged<Duration> onChanged;

  const _RefreshIntervalPicker({
    required this.currentInterval,
    required this.onChanged,
  });

  @override
  State<_RefreshIntervalPicker> createState() => _RefreshIntervalPickerState();
}

class _RefreshIntervalPickerState extends State<_RefreshIntervalPicker> {
  // Slider works in seconds: 10 – 3600
  static const _minSeconds = 10.0;
  static const _maxSeconds = 3600.0;
  late double _currentSeconds;

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.currentInterval.inSeconds
        .toDouble()
        .clamp(_minSeconds, _maxSeconds);
  }

  String _formatLabel(double seconds) {
    final s = seconds.round();
    if (s < 60) return '${s}s';
    if (s < 3600) {
      final min = s ~/ 60;
      final sec = s % 60;
      return sec == 0 ? '${min}m' : '${min}m ${sec}s';
    }
    return '1h';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.timer_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Auto-Refresh Interval',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Auto-refresh only runs on WiFi',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          // Current value display
          Text(
            _formatLabel(_currentSeconds),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          // Slider
          Row(
            children: [
              Text(
                '10s',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _currentSeconds,
                  min: _minSeconds,
                  max: _maxSeconds,
                  divisions: 359, // (3600 - 10) / 10 ≈ 359 steps of ~10s
                  onChanged: (value) {
                    setState(() {
                      // Snap to clean values
                      _currentSeconds = _snapToCleanValue(value);
                    });
                  },
                  onChangeEnd: (value) {
                    final snapped = _snapToCleanValue(value);
                    widget.onChanged(Duration(seconds: snapped.round()));
                  },
                ),
              ),
              Text(
                '1h',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick-pick chips
          Wrap(
            spacing: 8,
            children: [
              _buildChip(context, '10s', 10),
              _buildChip(context, '30s', 30),
              _buildChip(context, '1m', 60),
              _buildChip(context, '5m', 300),
              _buildChip(context, '15m', 900),
              _buildChip(context, '1h', 3600),
            ],
          ),
        ],
      ),
    );
  }

  double _snapToCleanValue(double raw) {
    if (raw < 60) {
      return (raw / 10).round() * 10.0; // snap to 10s steps
    } else if (raw < 600) {
      return (raw / 30).round() * 30.0; // snap to 30s steps
    } else {
      return (raw / 60).round() * 60.0; // snap to 1m steps
    }
  }

  Widget _buildChip(BuildContext context, String label, int seconds) {
    final isSelected = _currentSeconds.round() == seconds;
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      onPressed: () {
        setState(() => _currentSeconds = seconds.toDouble());
        widget.onChanged(Duration(seconds: seconds));
      },
    );
  }
}
