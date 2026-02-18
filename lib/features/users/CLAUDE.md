# Users

Most complex feature — manages drivers, vehicles, documents, bank accounts, and shipper profiles with verification workflows, approval history, and suspension management.

## Architecture

- **Layers**: domain (entities, repository interfaces) / data (models, repository impls) / presentation (providers, screens, widgets)
- **State Management**: `DriversNotifier` (driver list), `DriverProfileNotifier` (detail + actions), `VehicleNotifier` (vehicle detail + approval)
- **Loading Strategy**: Driver profile loads all related data in parallel (driver, vehicles, documents, approval history, bank account) via `Future.wait()`

## Entities

### DriverEntity
- Fields: `id`, `visibleId`, `firstName`, `lastName`, `phoneNumber?`, `email?`, `profilePhotoUrl?`, `verificationStatus` (DriverVerificationStatus), `isVerified`, `verifiedAt?`, `driverLicenseNumber?`, `driverLicenseExpiry?`, `vehicleCount`, `createdAt`, `updatedAt?`
- Helpers: `fullName`, `initials`, `hasProfilePhoto`, `isLicenseExpired`, `isLicenseExpiringSoon` (30-day threshold)

### DriverVerificationStatus (enum)
- `pending`, `approved`, `rejected`

### DriverStatusCounts
- Fields: `total`, `pending`, `approved`, `rejected`

### DriverProfile (composite entity)
- Fields: `id`, `visibleId`, `firstName`, `lastName`, `phoneNumber?`, `email?`, `profilePhotoUrl?`, `verificationStatus`, `verificationNotes?`, `verifiedAt?`, `verifiedBy?`, `driverLicenseNumber?`, `driverLicenseExpiry?`, `addressName?`, `isSuspended`, `suspendedAt?`, `suspendedReason?`, `suspendedBy?`, `suspensionEndsAt?`, `createdAt`, `updatedAt?`, `lastLoginAt?`
- Related: `vehicles` (List<VehicleEntity>), `documents` (List<DriverDocument>), `approvalHistory` (List<ApprovalHistoryItem>), `bankAccount?` (DriverBankAccount)
- Helpers: `fullName`, `initials`, `isLicenseExpired`, `isLicenseExpiringSoon`, `isCurrentlySuspended`, `hasProfilePhoto`, `primaryVehicle` (first in list)

### VehicleEntity
- Fields: `id`, `driverId`, `make`, `model`, `year?`, `color?`, `licensePlateNumber`, `registrationNumber?`, `vehicleType?`, `isApproved`, `approvedAt?`, `approvedBy?`, `rejectedAt?`, `rejectionReason?`, `isActive`, `createdAt`, `updatedAt?`
- Helpers: `displayName` ("make model"), `fullDescription` ("year make model (color)"), `statusString`

### DriverDocument
- Fields: `id`, `driverId`, `documentType`, `documentUrl?`, `status`, `uploadedAt`, `verifiedAt?`, `verifiedBy?`, `rejectionReason?`, `expiresAt?`, `metadata?`
- Helpers: `isExpired`, `isExpiringSoon` (30 days), `isImage` (jpg/jpeg/png/gif/webp)

### DriverBankAccount
- Fields: `id`, `driverId`, `bankCode`, `bankName`, `accountNumber`, `accountName`, `isVerified`, `verifiedAt?`, `verificationMethod?`, `verificationNotes?`, `isPrimary`, `isActive`, `currency` (default 'ZAR'), `rejectedAt?`, `rejectionReason?`, `createdAt`, `updatedAt`

### ApprovalHistoryItem
- Fields: `id`, `driverId`, `adminId`, `adminName?`, `previousStatus?`, `newStatus`, `reason?`, `notes?`, `documentsReviewed?` (List<String>), `createdAt`

## Repositories

### DriversRepository (abstract — list operations)
- `fetchDrivers(page?, pageSize?, searchQuery?, statusFilter?)` → `(List<DriverEntity>, int totalCount)`
- `getDriverStatusCounts()` → `DriverStatusCounts`

### DriversRepositoryImpl
- **Table**: `users` (role='Driver')
- **Joins**: `vehicles(count)` for vehicle count
- **Search**: ilike on first_name, last_name, phone_number, email (OR)
- **Status filter**: `driver_verification_status` eq filter
- **Pagination**: range-based with count query

### DriversProfileRepository (detail + actions)
- `fetchDriverProfile(driverId)` — parallel: driver data + vehicles + documents + approval history + bank account
- `approveDriver(driverId, adminId, notes?)` — sets `driver_verification_status='approved'`, `driver_verified_at`, `driver_verified_by`
- `rejectDriver(driverId, adminId, reason, notes?)` — sets status='rejected'
- `requestDocuments(driverId, adminId, documentTypes, message?)` — sets status='documents_requested'
- `suspendDriver(driverId, adminId, reason, suspensionEndsAt?)` — sets `is_suspended=true`, status='suspended'
- `reinstateDriver(driverId, adminId, notes?)` — clears suspension, restores status='approved'
- All actions log to `driver_approval_history` table

### VehiclesRepository (abstract)
- `fetchVehicleDetail(vehicleId)` → VehicleEntity
- `approveVehicle(vehicleId, adminId)`, `rejectVehicle(vehicleId, adminId, reason)`

### VehiclesRepositoryImpl
- **Table**: `vehicles`
- Approval sets `is_approved=true`, `approved_at`, `approved_by`
- Rejection sets `is_approved=false`, `rejected_at`, `rejection_reason`
- Logs to `admin_audit_logs`

## Data Models

- **DriverProfileModel**: `fromJson()` maps `users` table columns (first_name, last_name, driver_verification_status, etc.); `toEntity()` composes `DriverProfile` with related data
- **VehicleModel**: `fromJson()` / `toEntity()` mapping for `vehicles` table
- **DriverDocumentModel**: `fromJson()` / `toEntity()` for `driver_docs` table
- **ApprovalHistoryModel**: `fromJson()` handles nested admin join (first_name, last_name); maps `driver_approval_history` table
- **DriverBankAccountModel**: `fromJson()` / `toEntity()` for `driver_bank_accounts` table (filters: `is_primary=true`, `is_active=true`)

## Supabase Tables

- `users` — driver data (role='Driver'), verification status, suspension fields
- `vehicles` — driver vehicles with approval workflow
- `driver_docs` — uploaded documents with expiry tracking
- `driver_approval_history` — audit trail of status changes (joined with admin names)
- `driver_bank_accounts` — bank account info (primary + active filter)
- `admin_audit_logs` — vehicle approval/rejection logging

## Providers

- `driversRepositoryProvider`, `driversProfileRepositoryProvider`, `vehiclesRepositoryProvider`
- `driversNotifierProvider` — `StateNotifier<DriversState>` (drivers list, totalCount, statusCounts, isLoading, searchQuery, statusFilter, currentPage)
- `driverProfileNotifierProvider` — `StateNotifier<DriverProfileState>` (profile, isLoading, isActionLoading, error, actionSuccess)
- `vehicleNotifierProvider` — `StateNotifier<VehicleState>` (vehicle, isLoading, isActionLoading, error, actionSuccess)

### DriversNotifier Methods
- `fetchDrivers()`, `loadNextPage()`, `loadPreviousPage()`, `search(query)`, `filterByStatus(status?)`, `refreshStatusCounts()`

### DriverProfileNotifier Methods
- `loadDriverProfile(driverId)`, `approveDriver(notes?)`, `rejectDriver(reason, notes?)`, `requestDocuments(documentTypes, message?)`, `suspendDriver(reason, suspensionEndsAt?)`, `reinstateDriver(notes?)`, `clearActionState()`

### VehicleNotifier Methods
- `loadVehicle(vehicleId)`, `approveVehicle()`, `rejectVehicle(reason)`, `clearActionState()`

## Screens & Widgets

### Screens
- **UsersScreen**: Tab-based (Drivers, Shippers); Drivers tab delegates to DriversListScreen
- **DriversListScreen**: Search header, status filter chips with counts (All, Pending, Approved, Rejected), paginated driver list, page navigation controls
- **DriverProfileScreen**: Profile header, verification status card (pending=orange, approved=green, rejected=red), suspension card (if suspended), documents section with thumbnails, vehicles section with cards, bank account section, approval history timeline; action buttons (Approve/Reject/Request Docs/Suspend/Reinstate)
- **VehicleDetailScreen**: Vehicle info (make, model, year, color, plates), approval status, approval timeline, action buttons (Approve/Reject)
- **VehiclesListScreen**: List of vehicles (unused standalone)
- **ShipperProfileScreen**: Reuses shippers feature's `ShipperDetailScreen` pattern

### Widgets
- **SearchHeader**: Search field with filter icon badge
- **ProfileHeader**: Large avatar (48px), name, phone, email, verification badge
- **InfoSection**: Titled card section with key-value rows
- **DocumentThumbnail**: Image preview (if image URL) or document type icon; shows expiry warning, status badge
- **ApprovalTimeline**: Vertical timeline of approval history events with admin names, status changes, reasons
- **VehicleApprovalTimeline**: Similar timeline for vehicle approval events
- **VehicleCard**: Card showing vehicle make/model/year, plates, approval status; tap to navigate to detail
- **StatusBadge**: Color-coded verification status (pending=orange, approved=green, rejected=red); also supports vehicle statuses
- **DriverListTile**: Avatar, name, phone, verification badge, license expiry warning, vehicle count chip
- **ApproveConfirmDialog**: Confirmation with optional notes field
- **RejectDialog**: Reason field (required), optional notes
- **RequestDocumentsDialog**: Checkboxes for 12 document types (license front/back, ID, proof of address, vehicle registration/insurance, vehicle photos front/back/side/cargo, profile photo, other); optional message field

## Business Rules

- **Verification workflow**: pending → approved / rejected / documents_requested / suspended; suspended → approved (reinstate)
- **License expiry alert**: 30-day threshold (`isLicenseExpiringSoon`); expired = red warning
- **Document types** (12): license_front, license_back, id_document, proof_of_address, vehicle_registration, vehicle_insurance, vehicle_photo_front/back/side/cargo, profile_photo, other
- **Document expiry**: 30-day warning threshold; expired documents flagged
- **Suspension**: Temporary (with `suspensionEndsAt`) or permanent (null); reinstate clears all suspension fields and restores 'approved' status
- **Vehicle approval**: Separate workflow from driver approval; `is_approved` boolean with `approved_at`/`rejected_at` tracking
- **Bank account**: Filtered by `is_primary=true` AND `is_active=true`; currency defaults to ZAR
- **Approval history**: Every status change logged with admin name, previous/new status, reason, notes, documents reviewed
- **Parallel profile loading**: Driver data, vehicles, documents, history, and bank account all loaded simultaneously
- **Search**: ilike on first_name, last_name, phone_number, email (OR logic, case-insensitive)
- **Default pagination**: Page-based with page size parameter; status counts fetched separately
