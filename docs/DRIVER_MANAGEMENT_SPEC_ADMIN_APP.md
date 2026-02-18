# LoadRunner Admin — Driver, Vehicle & Document Management Specification

**Version:** 1.0
**Date:** February 17, 2026
**Scope:** How the LoadRunner Admin app manages the full driver lifecycle — from receiving registrations through document review, vehicle verification, approval/rejection, suspension, and reinstatement.

---

## 1. Admin Perspective Overview

```
┌──────────────────────┐     ┌─────────────────────┐     ┌──────────────────────┐
│  Driver Registers    │────>│  Admin Notification  │────>│  Admin Reviews       │
│  (via LoadRunner app)│     │  "New driver pending"│     │  Driver Profile      │
└──────────────────────┘     └─────────────────────┘     └──────────────────────┘
                                                                   │
                               ┌───────────────────────────────────┼───────────────────┐
                               │                                   │                   │
                               v                                   v                   v
                    ┌────────────────┐              ┌──────────────────┐    ┌──────────────────┐
                    │  Review Docs   │              │  Review Vehicles │    │  Review Banking  │
                    │  (per-document │              │  (per-vehicle    │    │  (display only)  │
                    │   queue)       │              │   detail screen) │    │                  │
                    └────────────────┘              └──────────────────┘    └──────────────────┘
                               │                            │
                               v                            v
                    ┌───────────────────────────────────────────────────┐
                    │  Driver-Level Decision                            │
                    │  Approve | Reject | Request Docs | Suspend       │
                    └───────────────────────────────────────────────────┘
```

### Verification Status Enum (shared across drivers, documents, vehicles)

```sql
CREATE TYPE verification_status AS ENUM (
    'pending',
    'under_review',
    'documents_requested',
    'approved',
    'rejected',
    'suspended'
);
```

---

## 2. Database Schema — Driver-Related Tables

### 2.1 `users` Table (Driver Columns)

```sql
-- Identity
id                          UUID PRIMARY KEY
phone_number                TEXT NOT NULL UNIQUE
first_name                  TEXT
last_name                   TEXT
email                       TEXT
dob                         DATE
id_no                       TEXT
profile_photo_url           TEXT
role                        user_role DEFAULT 'Shipper'  -- Shipper | Driver | Admin | Guest
address                     GEOMETRY(Point, 4326)        -- PostGIS
address_name                TEXT

-- Banking (legacy — stored on users row, not driver_bank_accounts)
bank_name                   TEXT
account_number              TEXT
branch_code                 TEXT

-- Driver Verification
driver_verification_status  verification_status DEFAULT 'pending'
driver_verified_at          TIMESTAMP           -- NULL = not verified
driver_verified_by          UUID FK → users.id  -- Admin who approved
verification_notes          TEXT

-- Suspension
is_suspended                BOOLEAN DEFAULT false
suspended_at                TIMESTAMP
suspended_reason            TEXT
suspended_by                UUID FK → users.id
suspension_ends_at          TIMESTAMP

-- Notifications
notification_radius_km      INTEGER DEFAULT 200  -- CHECK 10-500
fcm_token                   TEXT

-- Timestamps
created_at                  TIMESTAMP DEFAULT NOW()
updated_at                  TIMESTAMP DEFAULT NOW()
```

### 2.2 `driver_docs` Table

```sql
id                    UUID PRIMARY KEY DEFAULT gen_random_uuid()
driver_id             UUID FK → users.id ON DELETE CASCADE
doc_type              TEXT NOT NULL        -- free-text: "ID Document", "Driver's License", etc.
doc_url               TEXT NOT NULL        -- Supabase Storage URL
verification_status   verification_status DEFAULT 'pending'
verified_by           UUID FK → users.id
verified_at           TIMESTAMP
rejection_reason      TEXT
admin_notes           TEXT
expiry_date           DATE
created_at            TIMESTAMP NOT NULL
modified_at           TIMESTAMP NOT NULL
```

**Document types used in practice** (stored as `doc_type` text values):

| Admin Code | LoadRunner App Code | Display Label |
|---|---|---|
| `id_document` / `id_front` | `ID Document` | ID Document |
| `id_back` | — | ID (Back) |
| `license_front` | `Driver's License` | License (Front) |
| `license_back` | — | License (Back) |
| `proof_of_address` | `Proof of Address` | Proof of Address |
| `pdp` | `Professional Driving Permit (PDP)` | PDP |
| `profile_photo` | — | Profile Photo |
| `selfie` | — | Selfie |
| `Bank Document` | `Bank Document` | Bank Document |

**Note:** The LoadRunner app uses human-readable strings (`"ID Document"`, `"Driver's License"`) while the admin app's label getter maps both formats. There is a mismatch that needs resolving — see Section 14.

### 2.3 `vehicles` Table

```sql
id                          UUID PRIMARY KEY DEFAULT gen_random_uuid()
driver_id                   UUID FK → users.id NOT NULL
type                        TEXT NOT NULL      -- CHECK: Cargo Van | Pickup Truck | Box Truck | Flatbed Truck | Refrigerated Truck | Tanker | Semi-Truck
make                        TEXT NOT NULL
model                       TEXT NOT NULL
year                        INTEGER
license_plate               TEXT NOT NULL UNIQUE
capacity_tons               NUMERIC            -- CHECK > 0
photo_url                   TEXT NOT NULL
color                       TEXT DEFAULT 'White'
verification_status         verification_status DEFAULT 'pending'
verified_by                 UUID FK → users.id
verified_at                 TIMESTAMP
registration_document_url   TEXT               -- URL field (not in driver_docs)
insurance_document_url      TEXT               -- URL field (not in driver_docs)
roadworthy_certificate_url  TEXT               -- URL field (not in driver_docs)
additional_photos           JSONB DEFAULT '[]'
rejection_reason            TEXT
admin_notes                 TEXT
created_at                  TIMESTAMP DEFAULT NOW()
```

### 2.4 `driver_bank_accounts` Table

```sql
id                      UUID PRIMARY KEY DEFAULT gen_random_uuid()
driver_id               UUID FK → users.id
bank_code               TEXT NOT NULL
bank_name               TEXT NOT NULL
account_number          TEXT NOT NULL
account_name            TEXT NOT NULL
paystack_recipient_code TEXT               -- Paystack transfer recipient (RCP_xxx)
paystack_recipient_id   TEXT
is_verified             BOOLEAN DEFAULT false
verified_at             TIMESTAMP
verification_details    JSONB DEFAULT '{}'
is_primary              BOOLEAN DEFAULT true
is_active               BOOLEAN DEFAULT true
currency                TEXT DEFAULT 'ZAR'
verified_by             UUID FK
verification_method     TEXT DEFAULT 'api' -- 'api' (Paystack), 'manual', 'override'
verification_notes      TEXT
rejected_at             TIMESTAMP
rejection_reason        TEXT
created_at              TIMESTAMP DEFAULT NOW()
updated_at              TIMESTAMP DEFAULT NOW()
```

### 2.5 `driver_approval_history` Table

```sql
id                  UUID PRIMARY KEY DEFAULT gen_random_uuid()
driver_id           UUID FK → users.id NOT NULL
admin_id            UUID FK → users.id NOT NULL
previous_status     verification_status
new_status          verification_status NOT NULL
reason              TEXT
notes               TEXT
documents_reviewed  JSONB DEFAULT '[]'
created_at          TIMESTAMP DEFAULT NOW()
```

### 2.6 `flagged_documents` Table

```sql
id                    UUID PRIMARY KEY DEFAULT gen_random_uuid()
document_id           UUID FK → driver_docs.id ON DELETE CASCADE
driver_id             UUID FK → users.id ON DELETE CASCADE
flagged_by_user_id    UUID FK → users.id ON DELETE CASCADE  -- Shipper or Admin
shipment_id           UUID FK → freight_posts.id            -- Context (optional)
reason                TEXT NOT NULL
notes                 TEXT
status                TEXT DEFAULT 'pending'
admin_notes           TEXT
reviewed_by_admin_id  UUID FK → users.id
reviewed_at           TIMESTAMP
created_at            TIMESTAMP DEFAULT NOW()
updated_at            TIMESTAMP DEFAULT NOW()
```

### 2.7 `admin_audit_logs` Table

```sql
id          UUID PRIMARY KEY DEFAULT gen_random_uuid()
admin_id    UUID FK → users.id NOT NULL
action      TEXT NOT NULL
target_type TEXT NOT NULL    -- 'user', 'vehicle', etc.
target_id   UUID NOT NULL
details     JSONB DEFAULT '{}'
created_at  TIMESTAMP DEFAULT NOW()
```

### 2.8 `notifications` Table

```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id         UUID FK → users.id NOT NULL
message         TEXT NOT NULL
is_read         BOOLEAN DEFAULT false
type            notification_type
related_id      UUID
delivery_method TEXT    -- CHECK: 'push' | 'sms' | 'both'
sent_at         TIMESTAMP
created_at      TIMESTAMP DEFAULT NOW()
```

---

## 3. RPC Functions

### 3.1 `update_driver_verification(p_driver_id, p_admin_id, p_new_status, p_reason, p_notes)`

The primary function for driver-level status changes. Called by admin app for approve/reject/request-docs.

```sql
-- Updates users.driver_verification_status
-- Sets driver_verified_by and driver_verified_at when status = 'approved'
-- Inserts into driver_approval_history
-- Calls log_admin_action for audit trail
-- Returns boolean
```

### 3.2 `register_user_as_driver(p_user_id, p_address_lat, p_address_lng, p_address_name)`

Called by LoadRunner app during registration. Sets `role = 'Driver'` and stores PostGIS address.

### 3.3 `notify_all_admins(p_notification_type, p_message, p_related_id)`

Sends notification to all users with `role = 'Admin'`. Uses `send_notification_with_preferences` which respects per-user notification preferences.

### 3.4 `send_notification_with_preferences(p_user_id, p_notification_type, p_message, p_related_id)`

Checks `notification_type_preferences` table. Determines delivery method (push/sms/both/none). Inserts into `notifications` table if enabled.

---

## 4. Database Triggers

| Trigger | Table | Fires On | Action |
|---|---|---|---|
| `trg_notify_driver_registered` | `users` | `AFTER INSERT` where `role = 'Driver'` | `notify_all_admins('driver_pending_approval', 'New driver registered: {name}', driver_id)` |
| `trg_notify_document_uploaded` | `driver_docs` | `AFTER INSERT` | `notify_all_admins('driver_document_uploaded', 'New document uploaded by {name}: {doc_type}', driver_id)` |
| `trg_notify_driver_status_changed` | `users` | `AFTER UPDATE` | Fires when `is_suspended` changes to true OR `driver_verification_status` changes to 'pending'. Notifies all admins. |

---

## 5. Admin Screens & Navigation

### 5.1 Navigation Structure

```
/                           → Dashboard
/users                      → Users (Drivers tab / Shippers tab)
/users/driver/:id           → Driver Profile Screen
/users/vehicle/:id          → Vehicle Detail Screen
/users/shipper/:id          → Shipper Profile Screen
/document-queue             → Document Review Queue
/document-review/:id        → Document Review Screen (full-screen)
/notifications              → Admin Notifications
```

### 5.2 Driver List Screen (`/users` → Drivers tab)

- **Search**: ilike on first_name, last_name, phone_number, email (OR logic)
- **Filter chips**: All | Pending | Approved | Rejected (with counts)
- **List tiles**: Avatar, full name, phone, verification badge, vehicle count
- **Pagination**: Range-based, 20 per page, page controls at bottom
- **Tap**: Navigates to Driver Profile Screen

### 5.3 Driver Profile Screen (`/users/driver/:id`)

Loads all data in parallel via `Future.wait()`:
1. Driver profile (`users` table)
2. Vehicles (`vehicles` table)
3. Documents (`driver_docs` table)
4. Approval history (`driver_approval_history` joined with admin names)
5. Bank account (`driver_bank_accounts` where `is_primary=true` AND `is_active=true`)

**Sections displayed:**
- **Profile Header**: Avatar, name, phone, verification status badge
- **Personal Information**: Phone, email, DOB, masked ID number, registration date
- **Documents**: Grid of document thumbnails with status badges. Tapping a reviewable doc opens Document Review Screen. Tapping a non-reviewable doc opens plain image viewer.
- **Vehicles**: Cards showing make/model/year, plates, status. Tap → Vehicle Detail Screen.
- **Bank Account**: Bank name, masked account number, verification status (Verified/Rejected/Pending), currency. Shows rejection reason if rejected.
- **Approval History**: Timeline of all status changes with admin names, dates, reasons, notes.
- **Verification Notes**: Admin notes from previous reviews.

**Action Bar** (shown when status is NOT approved/suspended):
- "Approve All Documents" (green outlined, shown when driver has pending docs)
- "Request Docs" (orange outlined) → RequestDocumentsDialog
- "Reject" (red outlined) → RejectDialog
- "Approve" (green filled) → ApproveConfirmDialog

### 5.4 Vehicle Detail Screen (`/users/vehicle/:id`)

Fetches vehicle details with joined driver info (name, phone).

**Sections displayed:**
- Vehicle photo and additional photos
- Vehicle info: make, model, year, color, license plate, type, capacity
- Document URLs: Registration, insurance, roadworthy (viewed inline)
- Verification status badge
- Vehicle approval history timeline (from `admin_audit_logs`)

**Actions available:**
- Approve → sets `verification_status = 'approved'`, `verified_by`, `verified_at`
- Reject (with reason) → sets `verification_status = 'rejected'`, `rejection_reason`
- Request Documents (with types + message) → sets `verification_status = 'documents_requested'`
- Mark Under Review → sets `verification_status = 'under_review'`
- Suspend (with reason) → sets `verification_status = 'suspended'`
- Reinstate → sets `verification_status = 'approved'`, clears rejection

All vehicle actions: log to `admin_audit_logs`, send push+SMS notification to driver.

### 5.5 Document Queue Screen (`/document-queue`)

- Lists all documents with `verification_status IN ('pending', 'under_review')` across all drivers
- Joined with `users` table for driver info (name, phone, photo, verification status, registration date)
- Ordered **oldest-first** (longest-waiting reviewed first)
- Pull-to-refresh
- Pagination (infinite scroll)
- Each tile shows: document thumbnail, driver name, doc type label, upload date, status badge
- Tap → Document Review Screen

### 5.6 Document Review Screen (`/document-review/:id`)

Full-screen image viewer (PhotoView) with overlaid controls:

**Top overlay**: Close button, doc type label, driver name, info toggle
**Collapsible panel**: Driver name, phone, verification status, registration date
**Bottom action bar** (4 buttons):
- **Flag** (amber icon) → DocumentFlagDialog → inserts `flagged_documents`, sets doc status to `documents_requested`, sends neutral notification
- **Reject** (red outlined) → DocumentRejectDialog → sets doc status to `rejected`, sends rejection notification with reason
- **Re-upload** (orange outlined) → DocumentReuploadDialog → sets doc status to `documents_requested`, sends re-upload notification
- **Approve** (green filled) → sets doc status to `approved`, sends approval notification, checks if all required docs approved → auto-verifies driver

---

## 6. Driver-Level Actions (Detail)

### 6.1 Approve Driver

**Repository**: `DriversProfileRepository.approveDriver()` and `DriversRepositoryImpl.approveDriver()`

**Flow:**
1. Get current driver status
2. Update `users` row: `driver_verification_status = 'approved'`, `driver_verified_at = NOW()`, `driver_verified_by = {adminId}`
3. Log to `driver_approval_history`
4. Send notification to driver via `notifications` table (`delivery_method: 'both'`)

**Notification message:**
```
Congratulations! Your driver application has been approved!

You can now:
- Browse and bid on available shipments
- Accept delivery jobs
- Start earning

Welcome to LoadRunner! Safe travels!
```

### 6.2 Reject Driver

**Flow:**
1. Get current driver status
2. Update `users` row: `driver_verification_status = 'rejected'`, `driver_verified_at = NOW()`, `driver_verified_by = {adminId}`, `verification_notes`
3. Log to `driver_approval_history`
4. Send rejection notification (`delivery_method: 'both'`)

**Notification message:**
```
We regret to inform you that your driver application has been rejected.

Reason: {reason}

If you believe this was a mistake or have additional documentation to provide, please contact support.

You may re-apply after addressing the issues mentioned above.
```

### 6.3 Request Documents

**Flow:**
1. Update `users` row: `driver_verification_status = 'documents_requested'`, `verification_notes = {message}`
2. Log to `driver_approval_history` with `documents_reviewed` JSONB containing requested types
3. Send notification listing required documents (`delivery_method: 'both'`)

**RequestDocumentsDialog** offers 12 document types as checkboxes:
- license_front, license_back, id_document, proof_of_address
- vehicle_registration, vehicle_insurance
- vehicle_photo_front, vehicle_photo_back, vehicle_photo_side, vehicle_photo_cargo
- profile_photo, other

### 6.4 Suspend Driver

**Flow:**
1. Update `users` row: `is_suspended = true`, `suspended_at = NOW()`, `suspended_reason`, `suspended_by`, `suspension_ends_at` (optional), `driver_verification_status = 'suspended'`
2. Log to `driver_approval_history`
3. Database trigger `trg_notify_driver_status_changed` auto-notifies all admins

### 6.5 Reinstate Driver

**Flow:**
1. Update `users` row: `is_suspended = false`, clear all suspension fields, `driver_verification_status = 'approved'`, `verification_notes`
2. Log to `driver_approval_history`

---

## 7. Per-Document Actions (Detail)

### 7.1 Approve Document

**Repository**: `DocumentReviewRepository.approveDocument()`

**Flow:**
1. UPDATE `driver_docs` SET `verification_status = 'approved'`, `verified_by`, `verified_at`, `admin_notes`
2. Send notification: `"Your {docLabel} has been approved. Thank you for submitting valid documentation."`
3. Log to `driver_approval_history` (action: `document_approved`)
4. **Auto-verify check**: Fetch all driver docs. If both ID Document AND License (Front) are approved, and driver is not already approved → call `update_driver_verification` RPC to approve driver + send "Account Verified" notification

**Auto-verify notification:**
```
Congratulations! All your documents have been reviewed and approved. Your driver account is now fully verified and you can start bidding on available loads.
```

### 7.2 Reject Document

**Flow:**
1. UPDATE `driver_docs` SET `verification_status = 'rejected'`, `rejection_reason`, `admin_notes`
2. Send notification: `"Your {docLabel} could not be approved. Reason: {reason}. Please upload a new {docLabel} from your driver profile."`
3. Log to `driver_approval_history` (action: `document_rejected`)

**Rejection reasons** (enum with 8 options):

| Code | Display Text | Notification Fragment |
|---|---|---|
| `expired` | Expired Document | The document has expired. |
| `blurry` | Blurry / Unreadable | The document image is blurry or unreadable. |
| `wrong_doc` | Wrong Document Type | The uploaded document does not match the required type. |
| `incomplete` | Incomplete / Partially Visible | The document is not fully visible or is partially cut off. |
| `mismatch` | Name / Details Mismatch | The details on the document do not match your profile information. |
| `damaged` | Damaged Document | The document appears to be physically damaged. |
| `not_certified` | Not Certified / Stamped | The document is missing required certification or stamps. |
| `other` | Other (specify) | {custom reason text} |

### 7.3 Request Re-upload

**Flow:**
1. UPDATE `driver_docs` SET `verification_status = 'documents_requested'`, `admin_notes`
2. Send notification: `"We need you to re-upload your {docLabel}. {reason} Please open your driver profile and upload a new copy."`
3. Log to `driver_approval_history` (action: `document_reupload_requested`)

**Re-upload reasons** (enum with 6 options):

| Code | Display Text | Notification Fragment |
|---|---|---|
| `better_quality` | Better Quality Needed | We need a clearer, higher-quality image. |
| `newer_version` | Newer Version Required | We need the most recent version of this document. |
| `both_sides` | Both Sides Required | We need images of both sides of the document. |
| `colour_copy` | Colour Copy Required | We need a full-colour copy (not black and white). |
| `additional_info` | Additional Information Needed | Additional information is required on the document. |
| `other` | Other (specify) | {custom reason text} |

### 7.4 Flag Document

**Flow:**
1. INSERT into `flagged_documents` (document_id, driver_id, flagged_by = adminId, reason, notes)
2. UPDATE `driver_docs` SET `verification_status = 'documents_requested'`, `admin_notes`
3. Send **neutral** notification (no mention of fraud): `"We were unable to verify your {docLabel}. Please upload a new copy from your driver profile."`
4. Log to `driver_approval_history` (action: `document_flagged`)

### 7.5 Approve All Documents (Bulk)

**Flow:**
1. Fetch all `driver_docs` for driver WHERE `verification_status IN ('pending', 'under_review', 'documents_requested')`
2. For each document: approve individually (update status, send notification, log to history)
3. After all approved: run auto-verify check (same as single approve)

---

## 8. Vehicle Actions (Detail)

### 8.1 Approve Vehicle

**Flow:**
1. UPDATE `vehicles` SET `verification_status = 'approved'`, `verified_by`, `verified_at`, clear `rejection_reason`
2. Log to `admin_audit_logs` (action: `approve_vehicle`, target_type: `vehicle`)
3. Send notification (`delivery_method: 'both'`): `"Great news! Your vehicle "{displayName}" has been verified and approved. You can now use this vehicle for deliveries."`

### 8.2 Reject Vehicle

**Flow:**
1. UPDATE `vehicles` SET `verification_status = 'rejected'`, `rejection_reason`, `admin_notes`
2. Log to `admin_audit_logs`
3. Send notification: `"We were unable to approve your vehicle "{displayName}". Reason: {reason}"`

### 8.3 Request Vehicle Documents

**Flow:**
1. UPDATE `vehicles` SET `verification_status = 'documents_requested'`, `admin_notes`
2. Log to `admin_audit_logs`
3. Send notification listing required documents

### 8.4 Mark Vehicle Under Review

**Flow:**
1. UPDATE `vehicles` SET `verification_status = 'under_review'`, `admin_notes`
2. Log to `admin_audit_logs`
3. Send notification: `"Your vehicle "{displayName}" is currently being reviewed."`

### 8.5 Suspend Vehicle

**Flow:**
1. UPDATE `vehicles` SET `verification_status = 'suspended'`, `rejection_reason = {reason}`, `admin_notes`
2. Log to `admin_audit_logs`
3. Send notification: `"Your vehicle "{displayName}" has been suspended. Reason: {reason}"`

### 8.6 Reinstate Vehicle

**Flow:**
1. UPDATE `vehicles` SET `verification_status = 'approved'`, `verified_by`, `verified_at`, clear `rejection_reason`
2. Log to `admin_audit_logs`
3. Send notification: `"Your vehicle "{displayName}" has been reinstated and approved."`

### 8.7 Vehicle Pre-Approval Check

`canApproveVehicle()` checks: photo_url is set + registration_document_url is set + insurance_document_url is set.

---

## 9. Notification System

### 9.1 Admin-Bound Notifications (from DB triggers)

| Type | Trigger | Message Template |
|---|---|---|
| `driver_pending_approval` | Driver registers or status changes to pending | "New driver registered: {name}" |
| `driver_document_uploaded` | Document inserted into driver_docs | "New document uploaded by {name}: {doc_type}" |
| `driver_suspended` | Driver suspended (is_suspended changed to true) | "Driver suspended: {name}" |

### 9.2 Driver-Bound Notifications (from Admin actions)

| Action | `notification_type` | `delivery_method` | Source |
|---|---|---|---|
| Driver approved | `general` | `both` (push+SMS) | DriversRepositoryImpl |
| Driver rejected | `general` | `both` | DriversRepositoryImpl |
| Documents requested | `general` | `both` | DriversRepositoryImpl |
| Document approved | `document_approved` | `push` | DocumentReviewRepository |
| Document rejected | `document_rejected` | `push` | DocumentReviewRepository |
| Document reupload | `document_reupload_requested` | `push` | DocumentReviewRepository |
| Account verified (all docs) | `account_verified` | `push` | DocumentReviewRepository |
| Vehicle approved | `general` | `both` | VehiclesRepositoryImpl |
| Vehicle rejected | `general` | `both` | VehiclesRepositoryImpl |
| Vehicle docs requested | `general` | `both` | VehiclesRepositoryImpl |
| Vehicle under review | `general` | `both` | VehiclesRepositoryImpl |
| Vehicle suspended | `general` | `both` | VehiclesRepositoryImpl |
| Vehicle reinstated | `general` | `both` | VehiclesRepositoryImpl |

**Note:** Per-document notifications use dedicated types (`document_approved`, `document_rejected`, etc.) with `push` only. Driver-level and vehicle-level notifications use `general` type with `both` (push + SMS). This inconsistency should be unified.

### 9.3 Notification Type Enum (in DB)

```sql
CREATE TYPE notification_type AS ENUM (
    'bid_accepted', 'bid_rejected', 'outbid',
    'delivery_started', 'delivery_completed',
    'payment_received', 'rated',
    'new_bid', 'driver_registered', 'new_shipment',
    'profile_updated', 'vehicle_added',
    'upcoming_job', 'pickup_confirmed',
    'shipment_cancelled', 'bid_cancelled', 'bid_expired', 'bid_updated',
    'general',
    'dispute_filed', 'dispute_escalated', 'dispute_resolved',
    'driver_pending_approval', 'driver_document_uploaded', 'driver_suspended',
    'payment_failed', 'payment_refund_requested',
    'admin_system_alert'
);
```

**Missing types** that are used in code but not in DB enum: `document_approved`, `document_rejected`, `document_reupload_requested`, `account_verified`. These are inserted as text but the column type is the enum — this needs an ALTER TYPE migration.

---

## 10. Audit Trail

### 10.1 Driver Actions → `driver_approval_history`

Every driver-level status change is logged with:
- `driver_id`, `admin_id` (joined with admin first_name/last_name for display)
- `previous_status`, `new_status`
- `reason`, `notes`
- `documents_reviewed` (JSONB array)

Also used for per-document actions (with action type stored in `previous_status`/`new_status` fields).

### 10.2 Vehicle Actions → `admin_audit_logs`

Vehicle approval/rejection/suspension logged with:
- `admin_id` (joined with admin first_name/last_name)
- `action` (approve_vehicle, reject_vehicle, request_vehicle_documents, review_vehicle, suspend_vehicle, reinstate_vehicle)
- `target_type` = 'vehicle', `target_id` = vehicle UUID
- `details` JSONB (previous_status, new_status, reason, notes)

### 10.3 Driver Status Changes → `update_driver_verification` RPC

The RPC itself calls `log_admin_action()` which inserts into `admin_audit_logs` with `target_type = 'user'`.

---

## 11. Auto-Verification Logic

When any document is approved, the system checks whether the driver should be auto-verified:

```
For driver {driverId}:
  1. Check current driver_verification_status
  2. If already 'approved' → skip (idempotent)
  3. Fetch ALL driver_docs for this driver
  4. Check: has approved doc where doc_type IN ('id_document', 'id_front')
  5. Check: has approved doc where doc_type = 'license_front'
  6. If BOTH → call update_driver_verification('approved')
              + send "Account Verified" notification
```

**Required docs for auto-verify**: ID Document + Driver's License (Front)

---

## 12. State Management Architecture

### 12.1 Providers

| Provider | Type | Scope | Purpose |
|---|---|---|---|
| `driversRepositoryProvider` | Provider | App-wide | DriversRepositoryImpl instance |
| `driversProfileRepositoryProvider` | Provider | App-wide | DriversProfileRepository instance |
| `vehiclesRepositoryProvider` | Provider | App-wide | VehiclesRepositoryImpl instance |
| `documentReviewRepositoryProvider` | Provider | App-wide | DocumentReviewRepository instance |
| `driversNotifierProvider` | StateNotifierProvider | Drivers list screen | Manages list, pagination, search, filter, status counts |
| `driverProfileControllerProvider` | StateNotifierProvider.family | Per driver profile | Manages profile data, approval actions |
| `vehicleDetailControllerProvider` | StateNotifierProvider.family | Per vehicle detail | Manages vehicle data, approval actions |
| `documentQueueNotifierProvider` | StateNotifierProvider | Document queue screen | Manages queue list, pagination, filtering |
| `documentReviewNotifierProvider` | StateNotifierProvider | Document review | Manages per-document action state |
| `documentQueueCountProvider` | FutureProvider | Badge count | Returns count of pending documents |

### 12.2 State Shapes

**DriversState**: `drivers`, `totalCount`, `statusCounts`, `isLoading`, `error`, `searchQuery`, `statusFilter`, `currentPage`

**DriverProfileData**: `profile` (DriverProfile), `documents` (List<DriverDocument>), `vehicles` (List<VehicleEntity>), `approvalHistory` (List<ApprovalHistoryItem>)

**VehicleDetailState**: `vehicle`, `history`, `isLoading`, `error`, `isProcessing`

**DocumentQueueState**: `documents`, `totalCount`, `isLoading`, `error`, `docTypeFilter`, `currentPage`, `hasMore`

**DocumentReviewState**: `isActionLoading`, `actionError`, `actionSuccess`

---

## 13. Complete Admin Workflow (End-to-End)

### 13.1 New Driver Registration Flow (Admin's view)

```
1. Driver registers via LoadRunner app (3-step wizard)
   ↓
2. DB trigger: trg_notify_driver_registered
   → notify_all_admins('driver_pending_approval', 'New driver registered: John Doe')
   ↓
3. DB trigger: trg_notify_document_uploaded (fires per document)
   → notify_all_admins('driver_document_uploaded', 'New document uploaded by John Doe: ID Document')
   → notify_all_admins('driver_document_uploaded', 'New document uploaded by John Doe: Driver's License')
   ↓
4. Admin sees notifications in Notifications screen
   ↓
5. Admin navigates: Notifications → Driver Profile OR Document Queue
   ↓
6a. VIA DOCUMENT QUEUE:
    → Tap document → Document Review Screen
    → Review image full-screen
    → Approve / Reject / Request Reupload / Flag
    → If approve: auto-verify check runs
    → Move to next document
   ↓
6b. VIA DRIVER PROFILE:
    → Review all documents (grid thumbnails)
    → Tap individual doc → Document Review Screen
    → OR use "Approve All Documents" button
    → Review vehicles (tap → Vehicle Detail)
    → Review banking info (display only)
    → Use action bar: Approve / Reject / Request Docs
```

### 13.2 Document Rejection & Re-submission Flow

```
1. Admin rejects document (Reject or Request Reupload)
   ↓
2. driver_docs.verification_status = 'rejected' or 'documents_requested'
   ↓
3. Notification sent to driver with reason
   ↓
4. Driver re-uploads document in LoadRunner app (edit mode)
   ↓
5. New row inserted into driver_docs (or existing row updated with new URL)
   ↓
6. DB trigger: trg_notify_document_uploaded
   → Admin notified of new upload
   ↓
7. Admin reviews new document (repeat cycle)
```

### 13.3 Vehicle Verification Flow

```
1. Vehicle data + photos visible on Driver Profile → Vehicle section
   ↓
2. Admin taps vehicle card → Vehicle Detail Screen
   ↓
3. Review: photo, details, registration/insurance/roadworthy documents
   ↓
4. Actions: Approve / Reject / Request Docs / Mark Under Review / Suspend
   ↓
5. Notification sent to driver
   ↓
6. Logged to admin_audit_logs
```

---

## 14. Current Gaps & Inconsistencies

### 14.1 Doc Type Mismatch Between Apps

The LoadRunner app stores doc_type as human-readable strings (`"ID Document"`, `"Driver's License"`, `"Professional Driving Permit (PDP)"`, `"Proof of Address"`, `"Bank Document"`).

The admin app's auto-verify logic checks for `id_document`, `id_front`, `license_front` — these are snake_case codes that **will never match** the LoadRunner app's values.

**Impact**: Auto-verify after approving all docs will never trigger because the doc_type strings don't match.

**Fix needed**: Either normalize doc_types in the database OR update the auto-verify check to match both formats.

### 14.2 Missing Notification Types in DB Enum

The DocumentReviewRepository uses notification types (`document_approved`, `document_rejected`, `document_reupload_requested`, `account_verified`) that are **not in the `notification_type` enum**. These inserts will fail at the database level.

**Fix needed**: ALTER TYPE notification_type ADD VALUE for each new type, OR use `general` type with structured message content.

### 14.3 Inconsistent Delivery Methods

- Driver-level actions send notifications with `delivery_method: 'both'` (push + SMS)
- Per-document actions send with `delivery_method: 'push'` only
- Vehicle actions send with `delivery_method: 'both'`

**Recommendation**: Standardize to a single approach, likely `push` for individual document actions (high frequency) and `both` for major status changes (approved/rejected).

### 14.4 Banking Info Not Verified

- Banking details are stored in **two places**: `users` table (legacy: bank_name, account_number, branch_code) AND `driver_bank_accounts` table (proper: with Paystack verification fields)
- The LoadRunner app saves banking to `users` table during registration
- The admin app reads from `driver_bank_accounts` table
- No automated Paystack bank verification during registration
- Admin can only VIEW bank info, cannot approve/reject/verify it

### 14.5 No Vehicle Document Review Workflow

Vehicle documents (registration, insurance, roadworthy) are stored as URL fields on the `vehicles` row — NOT in `driver_docs`. This means:
- They don't appear in the Document Queue
- They can't be individually approved/rejected/flagged
- They can only be viewed within the Vehicle Detail Screen

### 14.6 LoadRunner App Doesn't Display Document Status

The LoadRunner app does not:
- Read `driver_docs.verification_status`
- Show rejection reasons to drivers
- Display per-document approved/rejected badges
- Show a verification progress indicator
- Handle push notifications for document actions

### 14.7 No Bid Gating on Suspension

The LoadRunner app checks `driverVerifiedAt != null` for bid access. It does NOT check `is_suspended` or `driver_verification_status`. A suspended driver with a past `driverVerifiedAt` could still bid.

---

## 15. File Reference (Admin App)

### Domain Layer
| File | Description |
|---|---|
| `lib/features/users/domain/entities/driver_profile.dart` | Full driver profile composite entity |
| `lib/features/users/domain/entities/driver_document.dart` | Document entity with status helpers |
| `lib/features/users/domain/entities/vehicle_entity.dart` | Vehicle entity with status helpers |
| `lib/features/users/domain/entities/driver_bank_account.dart` | Bank account entity |
| `lib/features/users/domain/entities/approval_history_item.dart` | Approval history entry |
| `lib/features/users/domain/entities/document_queue_item.dart` | Queue item (doc + driver context) |
| `lib/features/users/domain/entities/document_rejection_reason.dart` | 8 rejection reason enum |
| `lib/features/users/domain/entities/document_reupload_reason.dart` | 6 reupload reason enum |
| `lib/features/users/domain/entities/driver_entity.dart` | Light driver entity for list |
| `lib/features/users/domain/repositories/drivers_repository.dart` | Abstract driver repo interface |
| `lib/features/users/domain/repositories/vehicles_repository.dart` | Abstract vehicle repo interface |

### Data Layer
| File | Description |
|---|---|
| `lib/features/users/data/repositories/drivers_repository_impl.dart` | Driver list + profile + approval actions |
| `lib/features/users/data/repositories/drivers_profile_repository.dart` | Profile fetch + approval actions (parallel loading) |
| `lib/features/users/data/repositories/vehicles_repository_impl.dart` | Vehicle CRUD + approval + notifications |
| `lib/features/users/data/repositories/document_review_repository.dart` | Document queue + per-doc actions + auto-verify |
| `lib/features/users/data/models/driver_model.dart` | Driver list model |
| `lib/features/users/data/models/driver_profile_model.dart` | Full profile model |
| `lib/features/users/data/models/vehicle_model.dart` | Vehicle model |
| `lib/features/users/data/models/driver_document_model.dart` | Document model |
| `lib/features/users/data/models/driver_bank_account_model.dart` | Bank account model |
| `lib/features/users/data/models/approval_history_model.dart` | Approval history model |
| `lib/features/users/data/models/document_queue_item_model.dart` | Queue item model |

### Presentation Layer
| File | Description |
|---|---|
| `lib/features/users/presentation/screens/driver_profile_screen.dart` | Main driver review screen |
| `lib/features/users/presentation/screens/vehicle_detail_screen.dart` | Vehicle review screen |
| `lib/features/users/presentation/screens/document_queue_screen.dart` | Document queue list |
| `lib/features/users/presentation/screens/document_review_screen.dart` | Full-screen document review |
| `lib/features/users/presentation/providers/drivers_providers.dart` | Driver list state |
| `lib/features/users/presentation/providers/driver_profile_providers.dart` | Profile controller |
| `lib/features/users/presentation/providers/vehicle_providers.dart` | Vehicle detail controller |
| `lib/features/users/presentation/providers/document_queue_providers.dart` | Queue state + count |
| `lib/features/users/presentation/providers/document_review_providers.dart` | Per-doc action state |
| `lib/features/users/presentation/widgets/document_reject_dialog.dart` | Rejection dialog |
| `lib/features/users/presentation/widgets/document_reupload_dialog.dart` | Reupload dialog |
| `lib/features/users/presentation/widgets/document_flag_dialog.dart` | Flag dialog |
| `lib/features/users/presentation/widgets/document_queue_tile.dart` | Queue list tile |
| `lib/features/users/presentation/widgets/approve_confirm_dialog.dart` | Approval confirmation |
| `lib/features/users/presentation/widgets/reject_dialog.dart` | Driver rejection dialog |
| `lib/features/users/presentation/widgets/request_documents_dialog.dart` | Request docs dialog |

### Navigation
| File | Description |
|---|---|
| `lib/core/navigation/app_router.dart` | All routes + TypeSafeNavigation extensions |
