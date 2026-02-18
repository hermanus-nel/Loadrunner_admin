# SMS Usage

SMS billing log tracking and usage analytics with daily volume charts, cost breakdown, and filtering.

## Architecture

- **Layers**: domain (repository interface with entities) / data (repository impl) / presentation (providers, screens, widgets)
- **State Management**: Single `SmsUsageNotifier` (StateNotifier) managing logs, stats, daily usage, filters, and pagination
- **Loading Strategy**: `initialize()` loads logs, stats, and daily usage in parallel; filter changes refresh all three

## Entities

### SmsLogEntity
- Fields: `id`, `phoneNumber`, `messageBody?`, `smsType` (SmsType), `status` (SmsStatus), `cost?`, `bulksmsMessageId?`, `errorMessage?`, `createdById?`, `metadata?`, `createdAt`, `deliveredAt?`
- Helpers: `maskedPhoneNumber` (last 4 digits visible), `messagePreview` (60-char truncation)

### SmsType (enum)
- `otp`, `notification`, `broadcast`, `custom`

### SmsStatus (enum)
- `pending`, `sent`, `delivered`, `failed`

### SmsUsageStats
- Fields: `totalSent`, `totalDelivered`, `totalFailed`, `totalCost`, `deliveryRate`, `byType` (Map<String, int>), `costByType` (Map<String, double>)

### DailyUsage
- Fields: `date`, `count`, `delivered`, `failed`, `cost`

### SmsLogFilters
- Fields: `type?`, `status?`, `dateFrom?`, `dateTo?`, `searchQuery?`
- Helper: `hasActiveFilters`

### SmsLogsPagination
- Default: page=1, pageSize=50

## Repositories

### SmsUsageRepository (abstract)
- `fetchSmsLogs(filters?, pagination?)` → `SmsUsageResult`
- `getSmsStats(startDate?, endDate?)` → `SmsStatsResult`
- `getDailyUsage(startDate?, endDate?)` → `DailyUsageResult`

### SmsUsageRepositoryImpl
- **Table**: `sms_billing`
- **Columns**: `id`, `phone_number`, `message_content`, `cost_cents`, `created_at`, `sent_at`, `is_paid`
- **Cost conversion**: `cost_cents / 100` → ZAR
- **Hardcoded mappings**: All billing entries mapped as `status: 'delivered'`, `sms_type: 'notification'`
- **Date filtering**: `gte('created_at', dateFrom)`, `lte('created_at', endOfDay)` (dateTo extended to 23:59:59)
- **Search**: `ilike('phone_number', '%query%')`
- **Daily grouping**: Groups by ISO 8601 date string (YYYY-MM-DD); default range: last 30 days
- All queries wrapped in JWT recovery handler

## Providers

- `smsUsageRepositoryProvider` — repository instance
- `smsUsageNotifierProvider` — `StateNotifier<SmsUsageState>` (logs, pagination, filters, stats, dailyUsage, isLoading, isLoadingMore, error)
- `smsUsageStatsProvider` — `FutureProvider<SmsUsageStats?>` (direct stats access)

### SmsUsageNotifier Methods
- `initialize()` — parallel load of logs, stats, daily usage
- `fetchLogs(refresh?)`, `loadMore()` — paginated log fetching
- `fetchStats()`, `fetchDailyUsage()` — aggregate data
- `updateFilters(filters)` — refreshes all data
- `clearFilters()`, `filterByType(type?)`, `filterByStatus(status?)`, `filterByDateRange(from?, to?)`, `filterBySearch(query?)`
- Quick filters: `filterToday()`, `filterThisWeek()` (from Monday), `filterThisMonth()` (from 1st)

## Screens & Widgets

- **SmsUsageScreen**: AppBar with filter badge and popup menu (Today, This Week, This Month, Refresh); stats overview cards, collapsible filter panel (status chips, type chips, date range, phone search), type filter bar, SMS usage chart, cost breakdown card, log list with infinite scroll
- **Detail bottom sheet**: Draggable (30%-80%), shows full log details — type badge, timestamp, status, phone number (unmasked), message body, cost, BulkSMS ID, error, delivery timestamp, log ID
- **SmsLogTile**: Type badge, masked phone number (monospace), status badge, message preview (60 chars, 2 lines), cost, error, relative time
- **SmsStatusBadge**: pending=orange, sent=blue, delivered=green, failed=red
- **SmsTypeBadge**: otp=purple/lock, notification=blue/notifications, broadcast=orange/campaign, custom=teal/sms
- **SmsUsageChart**: Stacked bar chart (delivered=green, failed=red, other=orange); dynamic bar widths; Y-axis with max/mid/0; tooltip on hover
- **CostBreakdownCard**: Cost per type with color, amount, and percentage
- **UsageOverviewCards**: 4-column stats — Total Sent (blue), Delivered (green), Failed (red), Total Cost (orange, formatted as R)

## Business Rules

- **Cost storage**: Stored in cents (`cost_cents`), displayed in ZAR (`/ 100`)
- **Delivery rate**: `(totalDelivered / totalSent) * 100` — currently always 100% since all billing entries assumed delivered
- **Phone masking**: All but last 4 digits replaced with asterisks in lists; full number in detail view
- **Message preview**: 60-char truncation with ellipsis; "No message body" if null
- **Date range defaults**: Stats = all data; daily usage = last 30 days
- **Quick filters**: Today = midnight to now; This Week = Monday to now; This Month = 1st to now
- **Pagination**: Default 50 per page; scroll trigger 200px from bottom
- **Filter combination**: All filters AND-ed together
- **Time formatting**: "Just now" (<1m), "Xm ago" (<1h), "Xh ago" (<24h), "Xd ago" (<7d), "MMM d" (>=7d)
