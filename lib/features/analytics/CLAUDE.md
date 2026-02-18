# Analytics

Platform-wide analytics dashboard with activity, financial, and performance metrics across configurable date ranges.

## Architecture

- **Layers**: domain (entities, repository interface) / data (repository impl) / presentation (providers, screens, widgets)
- **State Management**: Single `AnalyticsNotifier` (StateNotifier) with parallel loading of 3 metric categories
- **Loading Strategy**: All metrics load in parallel via `Future.wait()`; individual tabs can refresh independently

## Entities

### DateRange / DateRangePreset
- `DateRangePreset` enum: `today`, `yesterday`, `last7Days`, `last30Days`, `thisMonth`, `lastMonth`, `thisQuarter`, `thisYear`, `custom`
- `DateRange` fields: `startDate`, `endDate`, `preset`
- Helpers: `dayCount`, `isSingleDay`, `displayText`; factories `last7Days()`, `last30Days()`, `thisMonth()`

### ActivityMetrics
- `ShipmentsByStatus`: `bidding`, `pickup`, `onRoute`, `delivered`, `cancelled` (int); computed `total`, `active`; `toChartData()` for pie chart
- `DailyShipments`: `date`, `count`, `completed`, `cancelled`
- `DailyActiveUsers`: `date`, `totalUsers`, `drivers`, `shippers`
- `UserStats`: `totalUsers`, `totalDrivers`, `totalShippers`, `verifiedDrivers`, `activeUsersToday`, `newUsersThisWeek`
- Aggregate: `totalBids`, `avgBidsPerShipment`, `bidAcceptanceRate`

### FinancialMetrics
- `PaymentsByStatus`: `pending`, `completed`, `failed`, `refunded` (double); `toPieChartData()`
- `DailyRevenue`: `date`, `revenue`, `commission`, `transactionCount`
- `RevenueSummary`: `totalRevenue`, `totalCommission`, `averageTransactionValue`, `totalTransactions`, `revenueGrowth`, `todayRevenue`, `thisWeekRevenue`, `thisMonthRevenue`; `formatAmount()` for ZAR display
- `TopEarner`: `id`, `name`, `type` ('driver'/'shipper'), `totalEarnings`, `completedShipments`, `averageRating`

### PerformanceMetrics
- `RatingsDistribution`: `oneStar`..`fiveStar`; computed `totalRatings`, `averageRating`; `toChartData()`
- `TimeMetrics`: `averageDeliveryTimeHours`, `averagePickupTimeHours`, `averageResponseTimeMinutes`, `onTimeDeliveryRate`; `formatHours()`, `formatMinutes()`
- `DriverPerformance`: `averageRating`, `topRatedCount` (>=4.5), `lowRatedCount` (<3.0), `deliverySuccessRate`, `complaintRate`
- `PlatformHealth`: `overallSuccessRate`, `customerSatisfactionScore` (0-100), `issueResolutionTimeHours`, `cancellationRate`, `activeDisputesCount`
- `LowRatedUser`: `id`, `name`, `type`, `averageRating`, `totalRatings`, `complaintCount`

## Repositories

### AnalyticsRepository (abstract)
- `fetchActivityMetrics(DateRange)`, `fetchFinancialMetrics(DateRange)`, `fetchPerformanceMetrics(DateRange)`
- Individual methods: `fetchShipmentsByStatus`, `fetchDailyShipments`, `fetchDailyActiveUsers`, `fetchUserStats`, `fetchBidStats`
- Financial: `fetchRevenueSummary`, `fetchPaymentsByStatus`, `fetchDailyRevenue`, `fetchTopDrivers`, `fetchTopShippers`
- Performance: `fetchRatingsDistribution`, `fetchTimeMetrics`, `fetchDriverPerformance`, `fetchPlatformHealth`, `fetchLowRatedDrivers/Shippers`

### AnalyticsRepositoryImpl
- **Tables**: `freight_posts`, `users`, `drivers`, `payments`, `bids`, `ratings`, `disputes`, `driver_payouts`
- **Query patterns**: Date filtering via `.gte()/.lte()` on `created_at`; day-by-day iteration for daily aggregates; in-memory aggregation for top N queries
- All queries wrapped in `JwtRecoveryHandler.executeWithRecovery()`

## Providers

- `analyticsRepositoryProvider` — repository instance
- `analyticsNotifierProvider` — `StateNotifierProvider<AnalyticsNotifier, AnalyticsState>`
- **AnalyticsState**: `dateRange`, 3 metric objects, 3 loading booleans, `error`, `lastRefresh`
- **Convenience providers**: `analyticsDateRangeProvider`, `activityMetricsProvider`, `financialMetricsProvider`, `performanceMetricsProvider`, individual loading providers
- **Derived chart data**: `shipmentsChartDataProvider`, `revenueChartDataProvider`, `ratingsChartDataProvider`, `paymentsChartDataProvider`

## Screens & Widgets

- **AnalyticsScreen**: 3-tab (Activity, Financial, Performance) with `TabController`; pull-to-refresh per tab; date range selector in AppBar
- **DateRangeSelector**: Bottom sheet with preset chips and custom date pickers; compact variant as `PopupMenuButton`
- **MetricCard / MetricCardsRow / ChartCard**: KPI display cards with loading skeletons
- **RevenueChart**: fl_chart line chart (revenue green, commission blue dashed); `PaymentsPieChart` for status breakdown
- **ShipmentsBarChart**: Grouped bar chart (total blue, completed green); `ShipmentsByStatusChart` pie; `ActiveUsersChart` multi-line
- **RatingsBarChart**: Horizontal bar by star level; `RatingsSummary` compact display; `StarRating` reusable widget

## Business Rules

- **Shipment statuses**: Bidding, Pickup, OnRoute, Delivered, Cancelled
- **Payment statuses for revenue**: Only 'completed' payments count toward revenue
- **Bid acceptance rate**: `(acceptedBids / totalBids) * 100`
- **Customer satisfaction**: `(avgRating / 5) * 100`
- **Driver thresholds**: Top-rated >= 4.5, Low-rated < 3.0
- **Currency formatting (ZAR)**: >= 1M → "R1.2M", >= 1K → "R100K", else "R1234"
- **Time formatting**: < 1h → "45m", < 24h → "4.5h", >= 24h → "1.2d"
- **Auto-load**: Constructor calls `loadAllMetrics()`; date range change reloads all
