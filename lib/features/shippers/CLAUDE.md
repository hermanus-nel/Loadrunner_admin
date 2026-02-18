# Shippers

Shipper user management with profiles, suspension workflows, stats, filtering, and recent shipment history.

## Architecture

- **Layers**: domain (entities, repository interface) / data (repository impl) / presentation (providers, screens, widgets)
- **State Management**: `ShippersListNotifier` (list + filters + sort + pagination + overview stats) and `ShipperDetailNotifier` (single shipper + actions)
- **Loading Strategy**: List enriches each shipper with computed stats from related tables; detail loads profile + recent shipments

## Entities

### ShipperEntity
- Fields: `id`, `phoneNumber`, `firstName?`, `lastName?`, `email?`, `profilePhotoUrl?`, `createdAt`, `updatedAt?`, `lastLoginAt?`, `isSuspended`, `suspendedAt?`, `suspendedReason?`, `suspendedBy?`, `suspensionEndsAt?` (null = permanent), `addressName?`, `stats?` (ShipperStats)
- Helpers: `fullName`, `displayName`, `initials`, `isCurrentlySuspended` (checks suspensionEndsAt), `statusString`, `isRecentlyActive` (7 days), `daysSinceRegistration`

### ShipperStats
- Fields: `totalShipments`, `activeShipments`, `completedShipments`, `cancelledShipments`, `totalSpent`, `averageRating`, `ratingsCount`, `disputesCount`, `openDisputesCount`
- Computed: `completionRate`, `cancellationRate`

### ShipperStatus (enum)
- `active` — not suspended
- `suspended` — is_suspended = true
- `inactive` — not suspended, no login in 30+ days

### ShipperSortBy (enum)
- `createdAt`, `lastLoginAt`, `name`, `totalShipments`, `totalSpent`

### ShipperFilters
- Fields: `status?`, `registeredAfter?`, `registeredBefore?`, `lastActiveAfter?`, `searchQuery?`, `sortBy`, `sortAscending`
- Search targets: firstName, lastName, email, phone_number (OR, case-insensitive ilike)

### ShippersPagination, ShippersOverviewStats, ShipperRecentShipment

## Repositories

### ShippersRepository (abstract)
- `fetchShippers(filters?, pagination?)` → `ShippersResult`
- `fetchShipperDetail(shipperId)` → `ShipperDetailResult` (shipper + recentShipments)
- `suspendShipper(shipperId, reason, endsAt?)` → `ShipperActionResult`
- `unsuspendShipper(shipperId)` → `ShipperActionResult`
- `updateShipperProfile(shipperId, firstName?, lastName?, email?)` → `ShipperActionResult`
- `getOverviewStats()` → `ShippersStatsResult`
- `searchShippers(query)`, `getRecentlyActiveShippers(limit?)`, `getNewShippers(days?, limit?)`, `getSuspendedShippers()`

### ShippersRepositoryImpl
- **Tables**: `users` (role='Shipper'), `freight_posts`, `payments`, `ratings`, `disputes`, `admin_audit_logs`
- **Stats enrichment**: `_fetchShipperStats()` queries freight_posts (by shipper_id), payments (amount sum), ratings (average), disputes (raised_by OR raised_against)
- **Status filter mapping**: active = `is_suspended=false`; suspended = `is_suspended=true`; inactive = `is_suspended=false AND last_login_at < 30 days ago`
- **Active shipments**: status in ['Posted', 'Bidding', 'Accepted', 'In Transit']
- **Open disputes**: status in ['open', 'investigating', 'awaiting_evidence']
- **Audit**: Actions `shipper_suspended`, `shipper_unsuspended`, `shipper_profile_updated` logged

## Providers

- `shippersRepositoryProvider` — repository instance
- `shippersListNotifierProvider` — `StateNotifier<ShippersListState>` (shippers, pagination, filters, overviewStats, isLoading, isLoadingMore)
- `shipperDetailNotifierProvider` — `StateNotifier<ShipperDetailState>` (shipper, recentShipments, isLoading, isUpdating)
- FutureProviders: `shippersOverviewStatsProvider`, `recentlyActiveShippersProvider`, `newShippersProvider`, `suspendedShippersProvider`, `shipperSearchProvider` (family)

### Notifier Methods
- **List**: `fetchShippers`, `loadMore`, `updateFilters`, `clearFilters`, `filterByStatus`, `search`, `filterByDateRange`, `sortBy`, `fetchOverviewStats`
- **Detail**: `fetchShipperDetail`, `suspendShipper`, `unsuspendShipper`, `updateProfile`, `clear`

## Screens & Widgets

- **ShippersListScreen**: Stats bar (Total, Active, Suspended, New/Week), search bar with 500ms debounce, collapsible filter panel (status chips, sort choice chips, date range pickers), quick filter chips (Active, Suspended, Inactive 30d+, sort direction), infinite scroll list
- **ShipperDetailScreen**: Profile header with avatar and status badge, status card (green=active, red=suspended with reason/dates), stats grid (8 stat tiles), contact info (phone/email with copy), recent shipments (10 latest with pickup→delivery, status, amount), account info (registered, last login, user ID); bottom action bar with Message and Suspend/Unsuspend buttons
- **Suspend dialog**: Reason field (required), temporary suspension toggle with date picker
- **ShipperTile**: Avatar with online indicator (green dot if recently active), name + status badge, phone/email, stats chips (shipments, spent, rating)
- **ShipperStatusBadge**: Active=green, Suspended=red; compact variant = small dot
- **ShipperActivityIndicator**: "Active today" (green), "Active Xd ago" (green/orange), "Inactive Xd" (red), "Never logged in" (gray)

## Business Rules

- **Suspension types**: Permanent (suspensionEndsAt = null) and Temporary (suspensionEndsAt = future date)
- **Activity thresholds**: Recently active = last 7 days; Inactive = no login 30+ days; Active (stats) = logged in within 30 days
- **Completion rate**: `(completed / total) * 100`
- **Cancellation rate**: `(cancelled / total) * 100`
- **Search**: OR logic across firstName, lastName, email, phone_number (case-insensitive ilike)
- **Sort**: Toggles direction if same field selected again
- **Default pagination**: 20 per page
- **Currency display**: ZAR with K/M compact formatting
- **Auto-unsuspend**: Not implemented — manual action required even after suspensionEndsAt passes
- **Audit**: All suspension/unsuspension/profile changes logged to `admin_audit_logs`
