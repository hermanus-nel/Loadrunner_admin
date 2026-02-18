# Dashboard

Main admin dashboard displaying today's key metrics, weekly performance stats, trend indicators, and quick action shortcuts.

## Architecture

- **Layers**: domain (entities, repository interface) / data (repository impl, models) / presentation (providers, screens, widgets)
- **State Management**: `DashboardNotifier` (StateNotifier) with two-phase loading and auto-refresh timer
- **Loading Strategy**: Phase 1 loads today's stats (fast); Phase 2 loads full stats with trends in background. 5-minute auto-refresh for today's stats only.

## Entities

### TrendDataPoint
- Fields: `date` (DateTime), `value` (double)

### TrendIndicator
- Fields: `percentageChange`, `isPositive`, `sparklineData` (List<TrendDataPoint>)
- Helper: `formattedPercentage` (absolute value as string)
- Factory: `TrendIndicator.empty()` — 0%, true, empty list

### WeeklyStats
- Fields: `completedShipments`, `totalRevenue`, `averageDeliveryTimeHours`, `driverUtilizationRate`
- Helpers: `formattedRevenue` (R with K/M suffixes), `formattedDeliveryTime` (m/h/d), `formattedUtilization` (percentage)

### DashboardStats
- **Today's stats**: `activeShipments`, `pendingDriverApprovals`, `newRegistrationsToday`, `activeUsers24h`, `revenueToday`, `pendingDisputes`
- **Weekly**: `weeklyStats` (WeeklyStats)
- **Trends** (7 TrendIndicators): `activeShipmentsTrend`, `pendingApprovalsTrend`, `registrationsTrend`, `activeUsersTrend`, `revenueTrend`, `disputesTrend`, `completedShipmentsTrend`

## Repositories

### DashboardRepository (abstract)
- `fetchDashboardStats()` — full stats with trends
- `fetchTodayStats()` — quick refresh, no trends
- `fetchWeeklyStats()`, `fetchTrends()`
- Individual: `fetchActiveShipmentsCount()`, `fetchPendingDriverApprovalsCount()`, `fetchNewRegistrationsTodayCount()`, `fetchActiveUsers24hCount()`, `fetchRevenueTodayAmount()`, `fetchPendingDisputesCount()`
- Sparkline: `fetchSparklineData(metricType)` — 7 days of daily data
- Weekly: `fetchCompletedShipmentsCount(startDate, endDate)`, `fetchTotalRevenue(startDate, endDate)`, `fetchAverageDeliveryTime(startDate, endDate)`, `fetchDriverUtilizationRate()`

### DashboardRepositoryImpl
- **Tables**: `freight_posts`, `users`, `payments`, `disputes`, `bids`
- **Trend calculation**: Compares this week vs last week; `((current - previous) / previous) * 100`; if previous=0 and current>0 → 100%
- **Active shipments**: status in ['Bidding', 'Pickup', 'OnRoute']
- **Pending approvals**: `role='Driver'` AND `driver_verification_status='pending'`
- **Active disputes**: status in ['open', 'under_review']
- **Revenue**: Only `status='Completed'` payments
- **Driver utilization**: (drivers with accepted bids on active freight) / (total approved drivers)

## Providers

- `dashboardRepositoryProvider` — repository instance
- `dashboardNotifierProvider` — `StateNotifierProvider<DashboardNotifier, DashboardState>`
- **DashboardState**: `stats`, `isLoading`, `isLoadingTrends`, `error`, `lastRefresh`
- **Notifier methods**: `loadStats()` (two-phase), `quickRefresh()` (today only), `fullRefresh()`, `refreshTrends()`, `clearError()`
- **Auto-refresh**: 5-minute timer calling `quickRefresh()`, cancelled on dispose
- **Convenience providers**: `dashboardStatsProvider`, `isDashboardLoadingProvider`, `isTrendsLoadingProvider`, `weeklyStatsProvider`, individual stat and trend providers

## Screens & Widgets

- **DashboardScreen**: SliverAppBar with countdown to next refresh, time-based greeting, error banner, 3x2 stats grid, weekly performance card, quick actions section, last refresh info; pull-to-refresh
- **StatCard**: Metric card with icon, value, trend, optional sparkline (fl_chart); variants: `FeaturedStatCard`, `StatCardsGrid`
- **WeeklyStatsCard**: 2x2 grid showing completed shipments, revenue, avg delivery time, utilization
- **QuickActionsSection**: 4 action cards — Review Drivers (badge), View Analytics, Handle Disputes (badge), Send Message
- **TrendIndicatorWidget**: Arrow + percentage; green/red/gray; variants: `CompactTrendIndicator`, `TrendBadge`, `AnimatedTrendIndicator`

## Business Rules

- **Revenue formatting (ZAR)**: >= 1M → "R1.5M", >= 1K → "R250K", else "R500"
- **Delivery time**: < 1h → "30m", < 24h → "2.5h", >= 24h → "1.5d"
- **Trend neutral threshold**: < 0.1% change treated as neutral
- **Badge display**: Count > 0 shows badge; cap at "99+"
- **Auto-refresh interval**: 5 minutes (today's stats only)
- **Two-phase load**: Today's stats shown immediately; trends load in background
- **Countdown display**: MM:SS format, updates every 1 second
