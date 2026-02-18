# Audit Logs

Read-only audit trail of all admin actions across the platform, with filtering, pagination, date grouping, and CSV export.

## Architecture

- **Layers**: domain (entities, repository interface) / data (repository impl) / presentation (providers, screens, widgets)
- **State Management**: Two StateNotifiers — `AuditLogsListNotifier` (list + filters + pagination) and `AuditLogDetailNotifier` (single log detail)
- **Loading Strategy**: `initialize()` loads logs, stats, admins, and actions in parallel

## Entities

### AuditLogEntity
- Fields: `id`, `adminId`, `action`, `targetType`, `targetId?`, `oldValues?`, `newValues?`, `ipAddress?`, `userAgent?`, `createdAt`, `admin?` (AuditLogAdmin)
- Helpers: `actionDescription`, `actionCategory`, `actionIcon`, `hasChanges`, `changesSummary` (3-field summary, 50-char truncation), `targetTypeDisplay`

### AuditLogAdmin
- Fields: `id`, `firstName?`, `lastName?`, `email?`, `profilePhotoUrl?`
- Helpers: `fullName` (fallback "Unknown Admin"), `initials`

### AuditAction (enum, 31 values)
- **Driver** (5): `driver_approved`, `driver_rejected`, `driver_suspended`, `driver_unsuspended`, `driver_documents_requested`
- **Shipper** (3): `shipper_suspended`, `shipper_unsuspended`, `shipper_profile_updated`
- **User** (3): `user_suspended`, `user_unsuspended`, `user_profile_updated`
- **Payment** (2): `payment_refunded`, `payout_processed`
- **Dispute** (7): `dispute_assigned`, `dispute_resolved`, `dispute_escalated`, `dispute_status_updated`, `dispute_priority_updated`, `dispute_note_added`, `dispute_evidence_requested`
- **Message** (2): `message_sent`, `broadcast_sent`
- **Vehicle** (2): `vehicle_approved`, `vehicle_rejected`
- **Auth** (2): `admin_login`, `admin_logout`
- **Default**: `unknown`
- Each has `value`, `displayName`, `category`, `icon`

### AuditActionCategory (enum, 9 values)
- `driver`, `shipper`, `user`, `payment`, `dispute`, `message`, `vehicle`, `auth`, `other`

### AuditTargetType (enum, 10 values)
- `user`, `driver`, `shipper`, `vehicle`, `payment`, `dispute`, `message`, `shipment`, `freightPost`, `other`

### AuditLogFilters
- Fields: `adminId?`, `action?`, `category?`, `targetType?`, `targetId?`, `dateFrom?`, `dateTo?`, `searchQuery?`
- Helper: `hasActiveFilters`

### AuditLogsPagination
- Fields: `page` (default 1), `pageSize` (default 50), `totalCount`, `hasMore`
- Computed: `offset` = `(page - 1) * pageSize`

### AuditLogsStats
- Fields: `totalLogs`, `logsToday`, `logsThisWeek`, `actionCounts` (Map), `adminCounts` (Map)

## Repositories

### AuditLogsRepository (abstract)
- `fetchAuditLogs(filters?, pagination?)` → `AuditLogsResult`
- `fetchAuditLogById(logId)` → `AuditLogEntity?`
- `fetchLogsForTarget(targetType, targetId, pagination?)` → `AuditLogsResult`
- `fetchLogsByAdmin(adminId, filters?, pagination?)` → `AuditLogsResult`
- `getStats(from?, to?)` → `AuditLogsStatsResult`
- `getActiveAdmins()` → `AdminsListResult`
- `getDistinctActions()` → `List<String>`
- `exportLogs(filters?, from?, to?)` → `String?` (CSV)

### AuditLogsRepositoryImpl
- **Table**: `admin_audit_logs` joined with `users` (via `admin_id` FK)
- **Join**: `admin:admin_id(id, first_name, last_name, email, profile_photo_url)`
- **Filters**: `eq()` for admin/action/target; `inFilter()` for category (converts to action list); `gte/lte` for dates (end date extended to 23:59:59)
- **Export**: CSV with 10,000 row limit; RFC 4180 quote escaping
- All queries wrapped in JWT recovery handler

## Providers

- `auditLogsRepositoryProvider` — repository instance
- `auditLogsListNotifierProvider` — `StateNotifier<AuditLogsListState>` (logs, pagination, filters, stats, availableAdmins, availableActions, isLoading, isLoadingMore, error)
- `auditLogDetailNotifierProvider` — `StateNotifier<AuditLogDetailState>` (log, isLoading, error)
- FutureProviders: `logsForTargetProvider` (family), `auditLogsStatsProvider`, `availableAdminsProvider`, `availableActionsProvider`, `exportLogsProvider` (family)

## Screens & Widgets

- **AuditLogsScreen**: Stats bar, collapsible filter panel (admin dropdown, action dropdown, target type chips, date range), category chips row, date-grouped log list with infinite scroll, detail bottom sheet, CSV export via popup menu
- **_LogDetailSheet**: Draggable bottom sheet (0.3-0.9) showing action, admin, target, changes (old/new values), context (IP/user agent), log ID
- **AuditLogTile**: Action badge with category color, admin avatar, target chip (monospace ID), changes summary, IP address; relative time display
- **AuditLogTileCompact**: Simplified ListTile variant
- **AuditCategoryBadge**: FilterChip with category color dot
- **AuditLogStats**: 3-column stats bar (Total, Today, This Week)

## Business Rules

- **Immutability**: Audit logs are read-only from the dashboard (no delete/update)
- **Date grouping**: Logs grouped as "Today", "Yesterday", weekday name (<7 days), or formatted date
- **Category colors**: driver=Blue, shipper=Purple, user=Teal, payment=Green, dispute=Orange, message=Indigo, vehicle=Cyan, auth=Red, other=Grey
- **Changes display**: Shows up to 3 fields as "key: old → new" with 50-char truncation
- **Stats calculation**: Today = from midnight; This Week = from Monday midnight
- **Filter logic**: Multiple filters AND-ed together; category filter converts to `inFilter()` on action values
- **Navigation from logs**: target types route to detail screens (driver → `/users/driver/{id}`, dispute → `/disputes/{id}`, payment → `/payments/transaction/{id}`)
- **Pagination**: Default 50 per page; newest first (`created_at DESC`)
