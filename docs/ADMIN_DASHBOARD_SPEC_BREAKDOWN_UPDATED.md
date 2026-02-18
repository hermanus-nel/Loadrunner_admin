# LoadRunner Admin Dashboard - Implementation Breakdown (UPDATED)

**Purpose:** Step-by-step guide to build a complete, functional LoadRunner Admin Dashboard app

**Last Updated:** January 28, 2026

**How to Use This Guide:**
1. Follow steps sequentially - each step builds on previous ones
2. Copy the Claude prompt for each step to get detailed implementation guidance
3. **IMPORTANT:** Each prompt specifies to return ONLY the Dart files (not full project zips) to save tokens
4. Verify success criteria before moving to next step
5. All file paths are relative to the admin dashboard project root

---

## PROGRESS SUMMARY

### ✅ COMPLETED PHASES

| Phase | Steps | Status |
|-------|-------|--------|
| Phase 1: Foundation | Steps 1-4 | ✅ COMPLETE |
| Phase 2: Authentication | Steps 5-7 | ✅ COMPLETE |
| Phase 3: App Shell & Navigation | Steps 8-9 | ✅ COMPLETE |

### 🔄 CURRENT STATE

**Project Location:** `loadrunner_admin/`

**Completed Components:**
- Clean Architecture folder structure
- Core services (SessionService, SupabaseProvider, JwtRecoveryHandler, BulkSmsService)
- Phone/OTP authentication (same as main LoadRunner app)
- Admin role verification after OTP
- GoRouter navigation with auth guards
- Material Design 3 theming
- Bottom navigation with 5 tabs
- Placeholder screens for all tabs

**Files Structure (33 Dart files):**
```
lib/
├── core/
│   ├── components/
│   │   └── main_scaffold.dart
│   ├── navigation/
│   │   └── app_router.dart
│   ├── services/
│   │   ├── bulksms_service.dart
│   │   ├── connectivity_service.dart
│   │   ├── core_providers.dart
│   │   ├── jwt_recovery_handler.dart
│   │   ├── logger_service.dart
│   │   ├── session_service.dart
│   │   ├── storage_service.dart
│   │   └── supabase_provider.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_dimensions.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   ├── utils/
│   │   └── app_config.dart
│   └── core.dart
├── features/
│   ├── auth/
│   │   ├── data/services/auth_service.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── auth_notifier.dart
│   │       │   ├── auth_provider.dart
│   │       │   └── auth_state.dart
│   │       └── screens/signup_screen.dart
│   ├── dashboard/
│   │   └── presentation/screens/dashboard_screen.dart
│   ├── users/
│   │   └── presentation/screens/users_screen.dart
│   ├── payments/
│   │   └── presentation/screens/payments_screen.dart
│   ├── messages/
│   │   └── presentation/screens/messages_screen.dart
│   └── more/
│       └── presentation/screens/more_screen.dart
└── main.dart
```

---

## 🔜 NEXT STEPS

### Phase 4: Dashboard & User Management (Steps 10-15)
### Phase 5: Statistics & Analytics (Steps 16-20)
### Phase 6: Payment Management (Steps 21-23)
### Phase 7: Bank Verification (Steps 24-25) - removed in main Loadrunner app
### Phase 8: Communication (Steps 26-28)
### Phase 9: Dispute Resolution (Steps 29-31)
### Phase 10: Additional Features (Steps 32-34)
### Phase 11: Polish & Testing (Steps 35-38)

---

# PHASE 4: DASHBOARD & USER MANAGEMENT

## Step 10: Dashboard Home Screen with Real Data

### Objective
Replace the placeholder dashboard with real statistics from Supabase.

### Prerequisites
- Completed Steps 1-9
- Existing `loadrunner_admin` project with auth working

### Claude Prompt
```
I need to implement the Dashboard home screen for the LoadRunner Admin Dashboard with real statistics from Supabase.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files or recreate the entire project structure. I will manually add/update these files in my existing project.

**Existing Project Context:**
- Project uses Clean Architecture with Riverpod
- Auth is working with phone/OTP (BulkSMS)
- SupabaseProvider is available via `supabaseProviderInstance` provider
- JwtRecoveryHandler is available for wrapped queries
- Theme components exist in `lib/core/theme/`

**Requirements:**

1. **DashboardRepository** (domain + data layers):
   - Fetch counts: active shipments, pending driver approvals, new registrations (today), active users (24h), pending disputes
   - Fetch today's revenue from payments table
   - Use JwtRecoveryHandler for all Supabase queries

2. **DashboardStats Entity:**
   - activeShipments (int)
   - pendingDriverApprovals (int)
   - newRegistrationsToday (int)
   - activeUsers24h (int)
   - revenueToday (double)
   - pendingDisputes (int)

3. **DashboardController** (StateNotifier):
   - Load stats on init
   - Handle refresh
   - Loading/error states

4. **DashboardScreen** (update existing placeholder):
   - Welcome header with "Admin Dashboard"
   - 6 StatCards in a grid layout (2 columns)
   - Quick action buttons: "Review Drivers", "View Shipments", "Handle Disputes", "Send Message"
   - Pull-to-refresh

**Files to create/update:**
```
lib/features/dashboard/
├── data/
│   ├── repositories/
│   │   └── dashboard_repository_impl.dart
│   └── models/
│       └── dashboard_stats_model.dart
├── domain/
│   ├── entities/
│   │   └── dashboard_stats.dart
│   └── repositories/
│       └── dashboard_repository.dart
└── presentation/
    ├── screens/
    │   └── dashboard_screen.dart (UPDATE)
    ├── providers/
    │   └── dashboard_providers.dart
    └── widgets/
        ├── stat_card.dart
        └── quick_actions_section.dart
```

Reference the existing Supabase schema for table names (users, shipments, payments, etc.).
```

### Files to Create/Update
```
lib/features/dashboard/domain/entities/dashboard_stats.dart
lib/features/dashboard/domain/repositories/dashboard_repository.dart
lib/features/dashboard/data/models/dashboard_stats_model.dart
lib/features/dashboard/data/repositories/dashboard_repository_impl.dart
lib/features/dashboard/presentation/providers/dashboard_providers.dart
lib/features/dashboard/presentation/widgets/stat_card.dart
lib/features/dashboard/presentation/widgets/quick_actions_section.dart
lib/features/dashboard/presentation/screens/dashboard_screen.dart (UPDATE)
```

### Success Criteria
- [ ] Dashboard displays 6 stat cards with real data
- [ ] Stats load from Supabase on init
- [ ] Pull-to-refresh works
- [ ] Loading state shows while fetching
- [ ] Error state displays if query fails
- [ ] Quick action buttons navigate to correct screens

---

## Step 11: Driver List & Filtering

### Objective
Create the driver list screen with filtering, searching, and status badges.

### Prerequisites
- Completed Step 10

### Claude Prompt
```
I need to create the driver list screen for the LoadRunner Admin Dashboard with filtering, searching, and pagination.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files or recreate the entire project structure.

**Existing Project Context:**
- Using Clean Architecture with Riverpod
- JwtRecoveryHandler available for Supabase queries
- GoRouter for navigation (AppRoutes class exists)
- Theme components in `lib/core/theme/`

**Requirements:**

1. **DriversRepository** (domain + data layers):
   - Fetch drivers with filters: status (pending/approved/rejected), search query
   - Pagination support (limit/offset)
   - Get driver counts by status for tab badges
   - Join with users table for phone/email

2. **Driver Entity:**
   - id, firstName, lastName, phoneNumber, email
   - verificationStatus (pending/approved/rejected)
   - createdAt, updatedAt
   - vehicleCount
   - profilePhotoUrl

3. **DriversListController** (StateNotifier):
   - State: drivers list, loading, error, currentTab, searchQuery, hasMore
   - Load drivers with filters
   - Handle search debounce
   - Handle pagination (load more)
   - Handle tab switching

4. **DriversListScreen** (update UsersScreen or create new):
   - TabBar: Pending (with count), Approved, Rejected, All
   - Search bar at top
   - ListView of driver cards
   - Each card shows: photo, name, phone, status badge, registration date
   - Tap card → navigate to driver detail (placeholder for now)
   - Pull-to-refresh
   - Infinite scroll pagination

5. **Widgets:**
   - DriverListTile: Avatar, name, phone, status badge
   - StatusBadge: Colored badge for pending/approved/rejected
   - SearchHeader: Search input with filter icon

**Files to create:**
```
lib/features/users/
├── data/
│   ├── repositories/
│   │   └── drivers_repository_impl.dart
│   └── models/
│       └── driver_model.dart
├── domain/
│   ├── entities/
│   │   └── driver_entity.dart
│   └── repositories/
│       └── drivers_repository.dart
└── presentation/
    ├── screens/
    │   └── drivers_list_screen.dart
    ├── providers/
    │   └── drivers_providers.dart
    └── widgets/
        ├── driver_list_tile.dart
        ├── status_badge.dart
        └── search_header.dart
```

Update app_router.dart to add route for drivers list if needed.
```

### Files to Create
```
lib/features/users/domain/entities/driver_entity.dart
lib/features/users/domain/repositories/drivers_repository.dart
lib/features/users/data/models/driver_model.dart
lib/features/users/data/repositories/drivers_repository_impl.dart
lib/features/users/presentation/providers/drivers_providers.dart
lib/features/users/presentation/widgets/driver_list_tile.dart
lib/features/users/presentation/widgets/status_badge.dart
lib/features/users/presentation/widgets/search_header.dart
lib/features/users/presentation/screens/drivers_list_screen.dart
```

### Success Criteria
- [ ] Driver list displays with real data
- [ ] Tabs show accurate counts
- [ ] Search filters results (debounced)
- [ ] Tab switching filters by status
- [ ] Pagination loads more on scroll
- [ ] Pull-to-refresh works
- [ ] Tapping driver card navigates (to placeholder)
- [ ] Status badges show correct colors

---

## Step 12: Driver Profile View

### Objective
Create the driver profile detail screen showing all information and documents.

### Prerequisites
- Completed Step 11

### Claude Prompt
```
I need to create the driver profile detail screen for the LoadRunner Admin Dashboard.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files.

**Existing Project Context:**
- Clean Architecture with Riverpod
- Driver entity already exists from Step 11
- GoRouter for navigation
- JwtRecoveryHandler for Supabase queries

**Requirements:**

1. **Extend DriversRepository:**
   - fetchDriverProfile(driverId): Get full driver details
   - fetchDriverVehicles(driverId): Get driver's vehicles
   - fetchDriverDocuments(driverId): Get uploaded documents
   - fetchApprovalHistory(driverId): Get approval audit trail

2. **Extended Entities:**
   - DriverProfile: Full driver data including documents
   - Vehicle: id, make, model, year, plateNumber, verificationStatus
   - DriverDocument: id, type (license_front, license_back, id_document, etc.), url, uploadedAt
   - ApprovalHistoryItem: id, action, adminId, adminName, reason, createdAt

3. **DriverProfileController** (StateNotifier):
   - Load complete profile data
   - Handle refresh
   - Loading/error states for each section

4. **DriverProfileScreen:**
   - Profile header: Photo, name, status badge, registration date
   - Personal Info section: Phone, email, DOB, license number
   - Documents section: Grid of document thumbnails (tap to view full)
   - Vehicles section: List of vehicle cards (expandable)
   - Bank Account section: Bank name, masked account number, verification status
   - Approval History section: Timeline of actions
   - Floating action buttons: Approve, Reject, Request Docs

5. **Widgets:**
   - ProfileHeader: Avatar, name, status
   - InfoSection: Key-value pairs in a card
   - DocumentThumbnail: Small image preview with label
   - VehicleCard: Expandable card with vehicle details
   - ApprovalTimeline: Chronological list of actions

**Files to create:**
```
lib/features/users/
├── domain/entities/
│   ├── driver_profile.dart
│   ├── vehicle_entity.dart
│   ├── driver_document.dart
│   └── approval_history_item.dart
├── data/models/
│   ├── driver_profile_model.dart
│   ├── vehicle_model.dart
│   ├── driver_document_model.dart
│   └── approval_history_model.dart
├── data/repositories/
│   └── drivers_repository_impl.dart (UPDATE)
└── presentation/
    ├── screens/
    │   └── driver_profile_screen.dart
    ├── providers/
    │   └── driver_profile_providers.dart
    └── widgets/
        ├── profile_header.dart
        ├── info_section.dart
        ├── document_thumbnail.dart
        ├── vehicle_card.dart
        └── approval_timeline.dart
```

Add route to app_router.dart: `/users/driver/:id`
```

### Files to Create
```
lib/features/users/domain/entities/driver_profile.dart
lib/features/users/domain/entities/vehicle_entity.dart
lib/features/users/domain/entities/driver_document.dart
lib/features/users/domain/entities/approval_history_item.dart
lib/features/users/data/models/driver_profile_model.dart
lib/features/users/data/models/vehicle_model.dart
lib/features/users/data/models/driver_document_model.dart
lib/features/users/data/models/approval_history_model.dart
lib/features/users/presentation/providers/driver_profile_providers.dart
lib/features/users/presentation/screens/driver_profile_screen.dart
lib/features/users/presentation/widgets/profile_header.dart
lib/features/users/presentation/widgets/info_section.dart
lib/features/users/presentation/widgets/document_thumbnail.dart
lib/features/users/presentation/widgets/vehicle_card.dart
lib/features/users/presentation/widgets/approval_timeline.dart
```

### Success Criteria
- [ ] Profile screen displays all driver information
- [ ] Documents show as thumbnails
- [ ] Vehicles listed with details
- [ ] Bank account section visible
- [ ] Approval history shows timeline
- [ ] Action buttons visible at bottom
- [ ] Loading states for each section
- [ ] Back navigation works

---

## Step 13: Document Viewer Component

### Objective
Create a full-screen document viewer with zoom and navigation.

### Prerequisites
- Completed Step 12

### Claude Prompt
```
I need to create a full-screen document viewer for the LoadRunner Admin Dashboard.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files.

**Dependencies needed in pubspec.yaml:**
- photo_view: ^0.15.0 (already added)
- cached_network_image: ^3.4.1 (already added)

**Requirements:**

1. **DocumentViewerScreen:**
   - Full-screen image viewer using PhotoView
   - AppBar with document name and close button
   - Swipe left/right to navigate between documents
   - Page indicator: "1 / 5"
   - Pinch to zoom, double-tap to zoom
   - Loading indicator while image loads
   - Error state with retry button

2. **DocumentViewerController** (StateNotifier):
   - currentIndex
   - documents list (URLs)
   - Handle page changes
   - Handle download (optional)

3. **Navigation:**
   - Accept list of document URLs and initial index
   - Use GoRouter extra parameter to pass data

**Files to create:**
```
lib/core/components/
├── document_viewer_screen.dart
└── document_viewer_controller.dart
```

Add route to app_router.dart for document viewer.
```

### Files to Create
```
lib/core/components/document_viewer_screen.dart
lib/core/components/document_viewer_controller.dart
```

### Success Criteria
- [ ] Document opens full screen
- [ ] Pinch zoom works smoothly
- [ ] Swipe navigates between documents
- [ ] Page indicator accurate
- [ ] Loading state while fetching
- [ ] Error state with retry
- [ ] Close button returns to previous screen

---

## Step 14: Driver Approval Workflow

### Objective
Implement approve/reject functionality with reasons and audit logging.

### Prerequisites
- Completed Step 13

### Claude Prompt
```
I need to implement the driver approval workflow for the LoadRunner Admin Dashboard.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files.

**Requirements:**

1. **DriversRepository additions:**
   - approveDriver(driverId, adminId): Update status to approved
   - rejectDriver(driverId, adminId, reason): Update status to rejected
   - requestDocuments(driverId, adminId, documentTypes, message): Send request
   - logApprovalAction(): Insert into driver_approval_history table

2. **ApprovalDialogs:**
   - ApproveConfirmDialog: Simple confirmation
   - RejectDialog: Reason input (required), predefined reasons dropdown + custom
   - RequestDocumentsDialog: Checkboxes for document types, message field

3. **Update DriverProfileScreen:**
   - Connect action buttons to dialogs
   - After action: refresh profile, show snackbar, update state

4. **Approval Actions:**
   - Approve: Set verification_status = 'approved', driver_verified_at = now()
   - Reject: Set verification_status = 'rejected', add rejection reason
   - Request Docs: Send notification to driver (create notification record)

5. **Audit Trail:**
   - Insert into driver_approval_history: driver_id, admin_id, action, reason, created_at

**Files to create/update:**
```
lib/features/users/
├── data/repositories/
│   └── drivers_repository_impl.dart (UPDATE)
├── presentation/
│   ├── screens/
│   │   └── driver_profile_screen.dart (UPDATE)
│   └── widgets/
│       ├── approve_confirm_dialog.dart
│       ├── reject_dialog.dart
│       └── request_documents_dialog.dart
```
```

### Files to Create/Update
```
lib/features/users/presentation/widgets/approve_confirm_dialog.dart
lib/features/users/presentation/widgets/reject_dialog.dart
lib/features/users/presentation/widgets/request_documents_dialog.dart
lib/features/users/data/repositories/drivers_repository_impl.dart (UPDATE)
lib/features/users/presentation/screens/driver_profile_screen.dart (UPDATE)
```

### Success Criteria
- [ ] Approve button shows confirmation dialog
- [ ] Approve updates driver status in database
- [ ] Reject button shows reason dialog
- [ ] Reject requires reason input
- [ ] Request Docs shows document type selection
- [ ] All actions logged in approval history
- [ ] Profile refreshes after action
- [ ] Success/error snackbars shown

---

## Step 15: Vehicle Management

### Objective
Add vehicle viewing, verification, and management within driver profiles.

### Prerequisites
- Completed Step 14

### Claude Prompt
```
I need to add vehicle management capabilities to the LoadRunner Admin Dashboard.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files.

**Requirements:**

1. **VehiclesRepository:**
   - fetchVehicleDetails(vehicleId): Get full vehicle with documents
   - approveVehicle(vehicleId, adminId)
   - rejectVehicle(vehicleId, adminId, reason)
   - fetchVehicleDocuments(vehicleId): Registration, insurance, photos

2. **VehicleDetailScreen:**
   - Vehicle photo gallery (swipeable)
   - Vehicle info: Make, model, year, color, plate number
   - Documents section: Registration, insurance
   - Verification status and history
   - Action buttons: Approve, Reject

3. **Update VehicleCard widget:**
   - Expandable with full details
   - Tap to navigate to VehicleDetailScreen
   - Show document count and verification status

4. **Vehicle Approval:**
   - Same pattern as driver approval
   - Log to audit trail

**Files to create:**
```
lib/features/users/
├── domain/repositories/
│   └── vehicles_repository.dart
├── data/repositories/
│   └── vehicles_repository_impl.dart
├── presentation/
│   ├── screens/
│   │   └── vehicle_detail_screen.dart
│   ├── providers/
│   │   └── vehicle_providers.dart
│   └── widgets/
│       └── vehicle_card.dart (UPDATE)
```

Add route: `/users/vehicle/:id`
```

### Files to Create
```
lib/features/users/domain/repositories/vehicles_repository.dart
lib/features/users/data/repositories/vehicles_repository_impl.dart
lib/features/users/presentation/providers/vehicle_providers.dart
lib/features/users/presentation/screens/vehicle_detail_screen.dart
lib/features/users/presentation/widgets/vehicle_card.dart (UPDATE)
```

### Success Criteria
- [ ] Vehicle details display correctly
- [ ] Vehicle photos viewable in gallery
- [ ] Vehicle documents accessible
- [ ] Approve/reject vehicles works
- [ ] Audit trail logged
- [ ] Navigation from driver profile works

---

# PHASE 5: STATISTICS & ANALYTICS

## Step 16: Enhanced Dashboard Statistics

### Objective
Add more comprehensive statistics to the dashboard with trends.

### Claude Prompt
```
I need to enhance the dashboard with more detailed statistics and trends.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files.

**Requirements:**

1. **Extended Statistics:**
   - Week-over-week comparison (↑12% or ↓5%)
   - Completed shipments this week
   - Total revenue this week
   - Average delivery time
   - Driver utilization rate

2. **Mini Charts:**
   - 7-day trend sparklines on stat cards
   - Use fl_chart for mini line charts

3. **DashboardRepository additions:**
   - fetchWeeklyStats(): Aggregated data for 7 days
   - fetchTrends(): Comparison with previous period

4. **Update StatCard widget:**
   - Add trend indicator (up/down arrow with percentage)
   - Add optional sparkline chart

**Files to update:**
```
lib/features/dashboard/
├── domain/entities/
│   └── dashboard_stats.dart (UPDATE)
├── data/repositories/
│   └── dashboard_repository_impl.dart (UPDATE)
└── presentation/
    └── widgets/
        ├── stat_card.dart (UPDATE)
        └── trend_indicator.dart (NEW)
```
```

### Success Criteria
- [ ] Trend indicators show percentage change
- [ ] Sparkline charts render correctly
- [ ] Weekly stats accurate
- [ ] Loading states work

---

## Step 17-20: Activity, Financial, Performance Metrics & Charts

### Claude Prompt (Combined for efficiency)
```
I need to add comprehensive analytics screens to the LoadRunner Admin Dashboard.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files.

**Requirements:**

1. **AnalyticsScreen** (new tab or section in More):
   - Activity Metrics tab: Shipments by status, daily active users
   - Financial Metrics tab: Revenue breakdown, payments by status
   - Performance tab: Average times, ratings distribution
   - Date range selector for all metrics

2. **Charts (using fl_chart):**
   - Line chart: Revenue over time
   - Bar chart: Shipments by day
   - Pie chart: Payments by status
   - Bar chart: Ratings distribution

3. **AnalyticsRepository:**
   - fetchActivityMetrics(dateRange)
   - fetchFinancialMetrics(dateRange)
   - fetchPerformanceMetrics(dateRange)

4. **Widgets:**
   - DateRangeSelector: Preset ranges + custom
   - MetricCard: Single metric with label
   - ChartCard: Container for charts with title

**Files to create:**
```
lib/features/analytics/
├── domain/
│   ├── entities/
│   │   ├── activity_metrics.dart
│   │   ├── financial_metrics.dart
│   │   └── performance_metrics.dart
│   └── repositories/
│       └── analytics_repository.dart
├── data/
│   └── repositories/
│       └── analytics_repository_impl.dart
└── presentation/
    ├── screens/
    │   └── analytics_screen.dart
    ├── providers/
    │   └── analytics_providers.dart
    └── widgets/
        ├── date_range_selector.dart
        ├── metric_card.dart
        ├── revenue_chart.dart
        ├── shipments_chart.dart
        └── ratings_chart.dart
```

Add route and navigation for analytics.
```

---

# PHASE 6: PAYMENT MANAGEMENT

## Step 21-23: Transactions, Details & Failed Payments

### Claude Prompt
```
I need to implement payment management for the LoadRunner Admin Dashboard.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files.

**Requirements:**

1. **PaymentsRepository:**
   - fetchTransactions(filters, pagination): List payments with search
   - fetchTransactionDetail(id): Full payment details
   - processRefund(paymentId, reason): Trigger refund
   - retryPayment(paymentId): Retry failed payment

2. **Payment Entity:**
   - id, amount, status (completed, pending, failed, refunded)
   - paymentMethod, createdAt
   - shipmentId, payerId, payeeId
   - failureReason (for failed payments)

3. **TransactionsListScreen:**
   - Filter by status, date range, amount range
   - Search by transaction ID, user name
   - List showing: amount, status badge, date, parties
   - Tap to view details

4. **TransactionDetailScreen:**
   - Full payment information
   - Related shipment info
   - Payer/payee details
   - Action buttons: Refund (for completed), Retry (for failed)

5. **Dialogs:**
   - RefundConfirmDialog: Amount, reason
   - RetryConfirmDialog: Confirmation

**Files to create:**
```
lib/features/payments/
├── domain/
│   ├── entities/
│   │   └── payment_entity.dart
│   └── repositories/
│       └── payments_repository.dart
├── data/
│   ├── models/
│   │   └── payment_model.dart
│   └── repositories/
│       └── payments_repository_impl.dart
└── presentation/
    ├── screens/
    │   ├── transactions_list_screen.dart
    │   └── transaction_detail_screen.dart
    ├── providers/
    │   └── payments_providers.dart
    └── widgets/
        ├── payment_list_tile.dart
        ├── payment_status_badge.dart
        ├── refund_dialog.dart
        └── retry_dialog.dart
```

Update PaymentsScreen placeholder and add routes.
```

---

# PHASE 7: BANK VERIFICATION

Removed done in main Loadrunner app

---

# PHASE 8: COMMUNICATION

## Step 26-28: Messaging, Push Notifications & Templates

### Claude Prompt
```
I need to implement the messaging system for the LoadRunner Admin Dashboard.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files.

**Requirements:**

1. **MessagesRepository:**
   - fetchConversations(): List of admin message threads
   - fetchMessages(conversationId): Messages in thread
   - sendMessage(userId, content): Send to specific user
   - sendBroadcast(userIds, content): Send to multiple users
   - createTemplate(name, content): Save message template

2. **Message Entity:**
   - id, senderId, recipientId, content, createdAt, readAt
   - messageType (direct, broadcast, system)

3. **MessagesScreen:**
   - Tabs: Inbox, Broadcasts, Templates
   - Inbox: List of conversations with users
   - Broadcasts: History of sent broadcasts
   - Templates: Saved message templates

4. **ConversationScreen:**
   - Chat UI with message bubbles
   - Input field with send button
   - Show user info in header

5. **ComposeMessageScreen:**
   - Recipient selector (search users)
   - Message input with template insertion
   - Send button

6. **BroadcastScreen:**
   - Target audience selector (all users, drivers, shippers, etc.)
   - Message composition
   - Preview before sending

**Files to create:**
```
lib/features/messages/
├── domain/
│   ├── entities/
│   │   ├── message_entity.dart
│   │   ├── conversation_entity.dart
│   │   └── message_template_entity.dart
│   └── repositories/
│       └── messages_repository.dart
├── data/
│   └── repositories/
│       └── messages_repository_impl.dart
└── presentation/
    ├── screens/
    │   ├── messages_screen.dart (UPDATE)
    │   ├── conversation_screen.dart
    │   ├── compose_message_screen.dart
    │   └── broadcast_screen.dart
    ├── providers/
    │   └── messages_providers.dart
    └── widgets/
        ├── conversation_tile.dart
        ├── message_bubble.dart
        ├── user_selector.dart
        └── template_selector.dart
```
```

---

# PHASE 9: DISPUTE RESOLUTION

## Step 29-31: Disputes List, Details & Evidence

### Claude Prompt
```
I need to implement dispute resolution for the LoadRunner Admin Dashboard.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files.

**Requirements:**

1. **DisputesRepository:**
   - fetchDisputes(filters): List disputes with status filter
   - fetchDisputeDetail(id): Full dispute with evidence
   - resolveDispute(id, resolution, notes): Mark resolved
   - escalateDispute(id, reason): Escalate to higher level
   - addEvidence(disputeId, file, description): Upload evidence

2. **Dispute Entity:**
   - id, shipmentId, raisedBy, raisedAgainst
   - type (damage, non_delivery, payment, other)
   - status (open, investigating, resolved, escalated)
   - description, createdAt, resolvedAt, resolution

3. **DisputesListScreen:**
   - Filter by status, type, date
   - List showing: dispute ID, type, status, created date
   - Priority indicator for urgent disputes

4. **DisputeDetailScreen:**
   - Dispute information
   - Parties involved (driver, shipper)
   - Related shipment details
   - Evidence gallery (photos, documents)
   - Timeline of actions
   - Resolution actions: Resolve, Escalate, Request Evidence

5. **EvidenceViewer:**
   - Gallery of uploaded evidence
   - Ability to add admin notes to evidence
   - Upload new evidence

**Files to create:**
```
lib/features/disputes/
├── domain/
│   ├── entities/
│   │   ├── dispute_entity.dart
│   │   └── evidence_entity.dart
│   └── repositories/
│       └── disputes_repository.dart
├── data/
│   └── repositories/
│       └── disputes_repository_impl.dart
└── presentation/
    ├── screens/
    │   ├── disputes_list_screen.dart
    │   └── dispute_detail_screen.dart
    ├── providers/
    │   └── disputes_providers.dart
    └── widgets/
        ├── dispute_tile.dart
        ├── dispute_status_badge.dart
        ├── evidence_gallery.dart
        ├── resolution_dialog.dart
        └── dispute_timeline.dart
```

Add route to More tab or navigation.
```

---

# PHASE 10: ADDITIONAL FEATURES

## Step 32: SMS Usage Tracking

### Claude Prompt
```
I need to add SMS usage tracking to the LoadRunner Admin Dashboard.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files.

**Requirements:**

1. **SmsUsageRepository:**
   - fetchSmsUsage(dateRange): SMS counts and costs
   - fetchSmsHistory(): Recent SMS log

2. **SmsUsageScreen:**
   - Total SMS sent this period
   - Cost breakdown
   - Usage chart over time
   - Recent SMS log with details

**Files to create:**
```
lib/features/sms_usage/
├── domain/
│   └── repositories/sms_usage_repository.dart
├── data/
│   └── repositories/sms_usage_repository_impl.dart
└── presentation/
    ├── screens/sms_usage_screen.dart
    ├── providers/sms_usage_providers.dart
    └── widgets/
        ├── sms_usage_chart.dart
        └── sms_log_tile.dart
```

Add to More screen.
```

---

## Step 33: Shipper Management

### Claude Prompt
```
I need to add shipper management to the LoadRunner Admin Dashboard.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files.

**Requirements:**

1. **ShippersRepository:**
   - fetchShippers(filters): List shippers
   - fetchShipperDetail(id): Full shipper profile
   - updateShipperStatus(id, status): Activate/deactivate

2. **ShippersListScreen:**
   - Similar to drivers list but for shippers
   - Filter by status, registration date
   - Search by name, email, phone

3. **ShipperDetailScreen:**
   - Profile information
   - Shipment history stats
   - Payment history
   - Status toggle

**Files to create:**
```
lib/features/shippers/
├── domain/
│   ├── entities/shipper_entity.dart
│   └── repositories/shippers_repository.dart
├── data/
│   └── repositories/shippers_repository_impl.dart
└── presentation/
    ├── screens/
    │   ├── shippers_list_screen.dart
    │   └── shipper_detail_screen.dart
    ├── providers/shippers_providers.dart
    └── widgets/shipper_tile.dart
```
```

---

## Step 34: Audit Logs Viewer

### Claude Prompt
```
I need to add an audit logs viewer to the LoadRunner Admin Dashboard.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files.

**Requirements:**

1. **AuditLogsRepository:**
   - fetchAuditLogs(filters, pagination): Admin activity logs
   - Filter by admin, action type, date range

2. **AuditLogsScreen:**
   - Chronological list of admin actions
   - Filter by admin user, action type
   - Each entry: admin name, action, target, timestamp, details

**Files to create:**
```
lib/features/audit_logs/
├── domain/
│   └── repositories/audit_logs_repository.dart
├── data/
│   └── repositories/audit_logs_repository_impl.dart
└── presentation/
    ├── screens/audit_logs_screen.dart
    ├── providers/audit_logs_providers.dart
    └── widgets/audit_log_tile.dart
```

Add to More screen.
```

---

# PHASE 11: POLISH & TESTING

## Step 35: Error Handling & Edge Cases

### Claude Prompt
```
I need to add comprehensive error handling to the LoadRunner Admin Dashboard.

**IMPORTANT:** Return ONLY the Dart file contents. Do NOT create zip files.

**Requirements:**

1. **Global Error Handler:**
   - Catch unhandled exceptions
   - Show user-friendly error messages
   - Log errors for debugging

2. **Network Error Handling:**
   - Offline mode indicator
   - Retry buttons on failed requests
   - Queue actions for when back online

3. **Empty States:**
   - Custom empty state widgets for each list
   - Helpful messages and actions

4. **Error Boundary Widget:**
   - Wrap screens to catch render errors
   - Show fallback UI on error

**Files to create:**
```
lib/core/
├── error/
│   ├── error_handler.dart
│   ├── error_boundary.dart
│   └── network_error_widget.dart
└── components/
    └── empty_state.dart (UPDATE)
```
```

---

## Step 36-38: Performance, Testing & Deployment

For these final steps, use standard Flutter best practices:

**Step 36: Performance Optimization**
- Implement list virtualization
- Add image caching
- Optimize Supabase queries
- Add loading skeletons

**Step 37: Integration Testing**
- Write integration tests for critical flows
- Test auth flow, driver approval, payments

**Step 38: Production Build**
- Configure release signing
- Build APK/AAB for Android
- Build IPA for iOS
- Prepare app store assets

---

# COMPLETION CHECKLIST

## ✅ Completed
- [x] Step 1: Project Setup & Architecture
- [x] Step 2: Database Schema Migration
- [x] Step 3: Environment & Dependencies
- [x] Step 4: Core Services Setup
- [x] Step 5: Admin Authentication System (Phone/OTP)
- [x] Step 6: Login Screen (SignupScreen with OTP)
- [x] Step 7: Session Management
- [x] Step 8: Main Navigation Structure
- [x] Step 9: Theme & Design System

## 🔄 In Progress
- [ ] Step 10: Dashboard Home Screen with Real Data

## ⏳ Pending
- [ ] Steps 11-38

---

# APPENDIX

## Key Reminders for Claude Prompts

1. **Always include:** "Return ONLY the Dart file contents. Do NOT create zip files or recreate the entire project structure."

2. **Reference existing code:** The project already has working auth, navigation, and theme. Build on top of it.

3. **Provider pattern:** Use Riverpod with StateNotifier for complex state, Provider for simple dependencies.

4. **Repository pattern:** Domain layer has abstract repository, data layer has implementation.

5. **JwtRecoveryHandler:** All Supabase queries should use `jwtRecoveryHandler.executeWithRecovery()` for auto-retry on auth errors.

6. **Navigation:** Use GoRouter. Routes are defined in `app_router.dart`.

7. **Theme:** Use `AppColors`, `AppDimensions`, `AppTextStyles` from `lib/core/theme/`.

## Environment Variables Required

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
BULKSMS_USERNAME=your-bulksms-username
BULKSMS_PASSWORD=your-bulksms-password
```

---

**Continue from Step 10 to complete the LoadRunner Admin Dashboard! 🚀**

