# LoadRunner App - Driver Management Specification

**Version:** 1.0
**Date:** February 17, 2026
**Scope:** How the LoadRunner mobile app (driver/shipper app) handles the full driver lifecycle — from registration through verification, active operation, and suspension.

---

## 1. Driver Lifecycle Overview

```
┌─────────────┐     ┌──────────────────┐     ┌────────────────────┐     ┌──────────────┐
│  Shipper /   │────>│  Registration    │────>│  Pending           │────>│  Verified    │
│  Guest User  │     │  Wizard (3 steps)│     │  (awaiting admin)  │     │  Driver      │
└─────────────┘     └──────────────────┘     └────────────────────┘     └──────────────┘
                                                       │                       │
                                                       v                       v
                                              ┌────────────────┐     ┌──────────────┐
                                              │  Rejected      │     │  Suspended   │
                                              │  (can re-apply)│     │  (by admin)  │
                                              └────────────────┘     └──────────────┘
```

| State | `role` | `driver_verification_status` | `driver_verified_at` | Can Bid? |
|---|---|---|---|---|
| Shipper / Guest | `Shipper` | n/a | `NULL` | No |
| Registered (pending) | `Driver` | `pending` | `NULL` | No |
| Under Review | `Driver` | `under_review` | `NULL` | No |
| Documents Requested | `Driver` | `documents_requested` | `NULL` | No |
| Rejected | `Driver` | `rejected` | `NULL` | No |
| Verified | `Driver` | `approved` | Timestamp | Yes |
| Suspended | `Driver` | `suspended` | Preserved | No |

---

## 2. Entry Points to Registration

A user can navigate to the driver registration wizard from multiple places in the app:

| Screen | Trigger | Context |
|---|---|---|
| Side Menu | "Register as Driver" menu item | Available when user role is Shipper |
| Profile Screen | "Register as Driver" button | Shipper viewing own profile |
| Find Loads / Bid screens | Prompt to register | Shipper tries to bid or access driver features |
| Notifications | Tap on driver-related notification | Redirects to driver profile |

All entry points navigate to `DriverProfileScreen` via:
```dart
Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverProfileScreen()));
```

The screen auto-detects registration mode: if `user.role != driver`, it enters registration mode. If the user is already a driver, it enters edit mode.

---

## 3. Registration Wizard — 3 Steps

### Step 0: Personal Information + Documents

**Personal Info Fields:**

| Field | Required | Validation |
|---|---|---|
| First Name | Yes | Non-empty |
| Last Name | Yes | Non-empty |
| Email | No | Valid email format if provided |
| Date of Birth | Yes | Must be 18+ years old |
| ID Number | No | SA ID format if provided |
| Address | Yes | Selected via Google Places autocomplete; must have lat/lng coordinates |
| Profile Photo | No | Camera or gallery pick, compressed to 1920x1080 @ 85% quality |

**Driver Documents Section** (embedded in this step):

| Document | Required | `doc_type` in DB |
|---|---|---|
| ID Document | Yes | `ID Document` |
| Driver's License | Yes | `Driver's License` |
| Professional Driving Permit (PDP) | No | `Professional Driving Permit (PDP)` |
| Proof of Address | No | `Proof of Address` |

**Document Upload Behaviour:**
- Driver taps the upload icon on a document tile
- Chooses Camera or Gallery
- Image is picked and compressed (if > 1MB)
- Document is added as a draft to local state immediately
- Upload to Supabase Storage begins immediately (via Edge Function with 3x retry)
- Tile shows spinner during upload, then green tick + "Uploaded" on success
- Eye icon appears to view the uploaded document full-screen
- If upload fails: tile shows "Failed - tap to retry"
- All uploads are tracked via `DocumentUploadStatus` enum in provider state

**Step Validation to proceed:**
- First Name, Last Name, Address must be filled
- ID Document and Driver's License must be uploaded (green tick)

---

### Step 1: Banking Information + Bank Document

**Banking Fields:**

| Field | Required | Validation |
|---|---|---|
| Bank Name | Yes | Selected from Paystack bank list (dropdown) |
| Account Number | Yes | Minimum 8 digits, numeric only |
| Branch Code | Yes | Exactly 6 digits |

**Bank Document Section** (embedded in this step):

| Document | Required | `doc_type` in DB |
|---|---|---|
| Bank Confirmation Letter | No | `Bank Document` |

Same upload behaviour as personal documents.

**Step Validation to proceed:**
- All three banking fields must be valid

---

### Step 2: Vehicles + Vehicle Documents

**Vehicle Fields (per vehicle):**

| Field | Required | Validation |
|---|---|---|
| Vehicle Type | Yes | Selected from predefined list (Cargo Van, Pickup Truck, Box Truck, Flatbed Truck, Refrigerated Truck, Tanker, Semi Truck) |
| Make | Yes | Non-empty text |
| Model | Yes | Non-empty text |
| Year | Yes | 4-digit number, reasonable range |
| License Plate | Yes | Non-empty, unique |
| Capacity (Tons) | Yes | Positive number |
| Vehicle Photo | Yes | Camera or gallery, uploaded to `loadrunner-vehicles` bucket |
| Colour | No | Text |

**Vehicle Documents Section** (embedded per vehicle):

| Document | Required | Storage |
|---|---|---|
| Registration Document | No | `vehicles.registration_document_url` |
| Insurance Certificate | No | `vehicles.insurance_document_url` |
| Roadworthy Certificate | No | `vehicles.roadworthy_certificate_url` |

Vehicle documents upload immediately on pick (same behaviour as personal documents) and are stored directly on the `vehicles` row as URL fields (not in `driver_docs` table).

**Step Validation to proceed / submit:**
- At least 1 vehicle with all required fields filled
- Vehicle photo uploaded

**This is the final step.** The "Register" button is shown here instead of "Next".

---

## 4. Draft Saving

The wizard auto-saves progress to prevent data loss:

| Aspect | Detail |
|---|---|
| Storage | `SharedPreferences` key: `driverProfileDraft_{userId}` |
| Format | JSON containing user fields, documents list, completed steps |
| Trigger | 500ms debounce after any field change |
| TTL | 7 days (stale drafts auto-deleted) |
| Restore | On re-entering `DriverProfileScreen` in registration mode, draft is loaded and state restored |
| Clear | Draft is deleted after successful registration |

---

## 5. Registration Submission

When the driver taps "Register" on Step 2 (Vehicles), the following chain executes:

### 5.1 Validation Chain
1. **Personal Info**: `firstName` and `lastName` non-empty
2. **Banking**: `bankName` non-empty, `accountNumber` >= 8 chars, `branchCode` == 6 chars
3. **Documents**: `hasIdDocument` AND `hasDriverLicense` (matched by description containing "id"/"identity" or "driver"/"license")
4. **Vehicles**: At least one complete vehicle with `completedSteps[vehicles] == true`

If any validation fails, an error message is shown and the user stays on the current step.

### 5.2 Upload Chain
1. Upload any pending documents that have local file paths but no server URL
2. Each upload: compress if needed -> base64 encode -> POST to Edge Function `/storage-proxy` -> retry up to 3x with exponential backoff (1s, 2s, 4s)
3. On success: document URL updated in state
4. On failure: error shown, registration halted

### 5.3 Database Chain
1. **`updateUserInfo()`** — Calls RPC `update_user_with_geometry` to save personal info, banking details, and address (PostGIS POINT)
2. **`registerAsDriver()`** — Calls RPC `register_user_as_driver` which sets `role = 'Driver'` and stores address geometry
3. **Save documents** — Each `DocumentEntity` upserted to `driver_docs` table
4. **Save vehicles** — Each `VehicleEntity` upserted to `vehicles` table (with photo URLs)
5. **Clear draft** — Delete `driverProfileDraft_{userId}` from SharedPreferences
6. **Update state** — Set `isRegistrationMode = false`

### 5.4 Automatic Triggers Fired (Database-Side)

These PostgreSQL triggers fire automatically during registration:

| Trigger | Table | Event | Action |
|---|---|---|---|
| `trg_notify_driver_registered` | `users` | `AFTER INSERT` (role = Driver) | Calls `notify_all_admins('driver_pending_approval', ...)` — notifies all admins that a new driver registered |
| `trg_notify_document_uploaded` | `driver_docs` | `AFTER INSERT` | Calls `notify_all_admins('driver_document_uploaded', ...)` — notifies admins per document |
| `trg_notify_driver_status_changed` | `users` | `AFTER UPDATE` | Fires when `driver_verification_status` changes to `pending` or driver is suspended |

---

## 6. Post-Registration State

Immediately after successful registration:

| Property | Value |
|---|---|
| `user.role` | `Driver` |
| `user.driver_verification_status` | `pending` |
| `user.driver_verified_at` | `NULL` |
| `user.isVerified` (getter) | `false` |
| App home screen | Switches to Driver home (Find Loads) |
| Bidding | **Blocked** — `isVerified` returns `false` |
| Profile editing | Allowed — can update info, upload more documents |

The driver sees the app as a registered driver (driver navigation, find loads screen) but **cannot place bids** until an admin verifies them.

---

## 7. Verification Gate

### 7.1 Where Verification is Checked

The key getter in `UserEntity`:
```dart
bool get isVerified => driverVerifiedAt != null;
```

This is checked in the bid flow. Unverified drivers are blocked from submitting bids.

### 7.2 Shipper-Side Driver Verification View

When a shipper reviews a bid, they can view the bidding driver's documents via `DriverVerificationScreen`:
- Shows all documents uploaded by the driver
- Documents are read-only (shipper cannot modify)
- Privacy note: "Driver contact information hidden for privacy. Documents shown for verification only."
- Shipper can flag documents for concerns (writes to `flagged_documents` table)

### 7.3 What Verification Changes (Admin-Side)

When an admin approves a driver (via the Admin app), the RPC `update_driver_verification` executes:

```sql
UPDATE users
SET driver_verification_status = 'approved',
    driver_verified_by = {admin_id},
    driver_verified_at = NOW(),
    verification_notes = {optional_notes}
WHERE id = {driver_id};
```

The driver app detects this change on next data fetch and unlocks bidding.

---

## 8. Driver Profile Editing (Post-Registration)

Once registered, a driver can return to `DriverProfileScreen` in **edit mode** (not registration mode). All the same forms are available:

| What | Editable? | Notes |
|---|---|---|
| Personal Info | Yes | Saves directly to DB via `updateUserInfo` RPC |
| Documents | Yes | Can upload new, replace, or delete documents. Uploads go to DB immediately. |
| Banking | Yes | Saves directly to DB |
| Vehicles | Yes | Can add, edit, or delete vehicles. Vehicle photos and documents upload immediately. |
| Profile Photo | Yes | Upload + compress + save |

**Key difference from registration mode:**
- No draft saving (changes go to DB immediately)
- No "Register" button (just "Save" per step)
- No completion chain — each step saves independently

---

## 9. Document Management Detail

### 9.1 Document Entity Fields

| Field | DB Column | Description |
|---|---|---|
| `id` | `id` | UUID, auto-generated by DB |
| `userId` | `driver_id` | FK to `users.id` |
| `description` | `doc_type` | "ID Document", "Driver's License", etc. |
| `docUrl` | `doc_url` | Supabase Storage URL |
| `createdAt` | `created_at` | Timestamp |
| `modifiedAt` | `modified_at` | Timestamp |

### 9.2 DB Columns Not Yet Used by App

The `driver_docs` table has these columns that exist in the schema but are **not currently read or written by the LoadRunner app**:

| Column | Type | Purpose |
|---|---|---|
| `verification_status` | `verification_status` enum | Admin sets: pending/under_review/approved/rejected/documents_requested |
| `verified_by` | UUID FK | Admin who verified |
| `verified_at` | Timestamp | When verified |
| `rejection_reason` | Text | Why rejected |
| `admin_notes` | Text | Internal admin notes |

These columns are ready for the Admin app to use.

### 9.3 Document Upload Flow

```
Driver picks image
       │
       v
ImagePicker (camera/gallery, quality: 80%)
       │
       v
addDraftDocument() — adds to state with local file path
       │
       v
uploadSingleDocument() — begins upload
       │
       ├── Compress if > 1MB (1920x1080, 85%)
       ├── Base64 encode
       ├── POST to Edge Function /storage-proxy
       ├── Retry up to 3x (1s, 2s, 4s backoff + jitter)
       │
       v
On success:
  ├── Update document URL in state (local path → server URL)
  ├── If edit mode: save to DB (upsert to driver_docs)
  ├── If registration mode: save draft locally
  └── Tile shows green tick + "Uploaded"

On failure:
  ├── Tile shows "Failed - tap to retry"
  └── Error snackbar shown
```

### 9.4 Document Upload Status Tracking

```dart
enum DocumentUploadStatus {
  missing,         // No document picked
  pendingUpload,   // Local file exists, not yet uploaded
  uploading,       // Upload in progress
  uploaded,        // Server URL confirmed
  failed,          // Upload failed
}
```

Status is tracked per document in `DriverProfileState.documentUploadStatus` map (keyed by document ID or description for drafts).

---

## 10. Vehicle Management Detail

### 10.1 Vehicle Entity Fields

| Field | DB Column | Required | Description |
|---|---|---|---|
| `id` | `id` | Auto | UUID |
| `driverId` | `driver_id` | Auto | FK to users.id |
| `type` | `type` | Yes | Cargo Van, Pickup Truck, Box Truck, Flatbed Truck, Refrigerated Truck, Tanker, Semi Truck |
| `make` | `make` | Yes | e.g. Toyota |
| `model` | `model` | Yes | e.g. Hilux |
| `year` | `year` | Yes | e.g. 2020 |
| `licensePlate` | `license_plate` | Yes | Unique |
| `capacityTons` | `capacity_tons` | Yes | Numeric |
| `photoUrl` | `photo_url` | Yes | Supabase Storage URL |
| `colour` | `color` | No | Text |
| `registrationDocumentUrl` | `registration_document_url` | No | URL |
| `insuranceDocumentUrl` | `insurance_document_url` | No | URL |
| `roadworthyCertificateUrl` | `roadworthy_certificate_url` | No | URL |

### 10.2 DB Columns Not Yet Used by App

| Column | Type | Purpose |
|---|---|---|
| `verification_status` | `verification_status` enum | Admin sets: pending/approved/rejected |
| `verified_by` | UUID FK | Admin who verified |
| `verified_at` | Timestamp | When verified |
| `additional_photos` | JSONB | Array of extra photo URLs |

### 10.3 Vehicle Document Storage

Vehicle documents are stored directly as URL fields on the `vehicles` row (not in `driver_docs`). They upload to the `loadrunner-documents` Supabase Storage bucket.

---

## 11. Database Schema Summary

### 11.1 `users` Table — Driver-Relevant Columns

```sql
-- Identity
role                         user_role DEFAULT 'Shipper'  -- Shipper|Driver|Admin|Guest
first_name                   TEXT
last_name                    TEXT
email                        TEXT
phone_number                 TEXT NOT NULL UNIQUE
profile_photo_url            TEXT
dob                          DATE
id_no                        TEXT

-- Address (PostGIS)
address                      GEOMETRY(Point, 4326)
address_name                 TEXT

-- Banking
bank_name                    TEXT
account_number               TEXT
branch_code                  TEXT

-- Driver Verification
driver_verification_status   verification_status DEFAULT 'pending'
driver_verified_at           TIMESTAMP            -- NULL = not verified
driver_verified_by           UUID FK              -- Admin who approved
verification_notes           TEXT

-- Suspension
is_suspended                 BOOLEAN DEFAULT false
suspended_at                 TIMESTAMP
suspended_reason             TEXT
suspended_by                 UUID FK
suspension_ends_at           TIMESTAMP

-- Notifications
notification_radius_km       INTEGER DEFAULT 200  -- CHECK 10-500
fcm_token                    TEXT
```

### 11.2 `driver_docs` Table

```sql
id                    UUID PRIMARY KEY
driver_id             UUID FK → users.id ON DELETE CASCADE
doc_type              TEXT NOT NULL        -- "ID Document", "Driver's License", etc.
doc_url               TEXT NOT NULL        -- Supabase Storage URL
verification_status   verification_status DEFAULT 'pending'
verified_by           UUID FK → users.id
verified_at           TIMESTAMP
rejection_reason      TEXT
admin_notes           TEXT
created_at            TIMESTAMP
modified_at           TIMESTAMP
```

Indexes: `idx_driver_docs_driver_id`, `idx_driver_docs_verification_status`

### 11.3 `vehicles` Table

```sql
id                        UUID PRIMARY KEY
driver_id                 UUID FK → users.id
type                      TEXT NOT NULL
make                      TEXT NOT NULL
model                     TEXT NOT NULL
year                      INTEGER
license_plate             TEXT NOT NULL UNIQUE
capacity_tons             NUMERIC
photo_url                 TEXT NOT NULL
color                     TEXT DEFAULT 'White'
insurance_document_url    TEXT
registration_document_url TEXT
roadworthy_certificate_url TEXT
additional_photos         JSONB DEFAULT '[]'
verification_status       verification_status DEFAULT 'pending'
verified_by               UUID FK → users.id
verified_at               TIMESTAMP
created_at                TIMESTAMP
```

Index: `idx_vehicles_verification_status`

### 11.4 `driver_approval_history` Table

```sql
id                  UUID PRIMARY KEY
driver_id           UUID FK → users.id
admin_id            UUID FK → users.id
previous_status     verification_status
new_status          verification_status NOT NULL
reason              TEXT
notes               TEXT
documents_reviewed  JSONB DEFAULT '[]'
created_at          TIMESTAMP DEFAULT NOW()
```

### 11.5 `flagged_documents` Table

```sql
id                    UUID PRIMARY KEY
document_id           UUID FK → driver_docs.id ON DELETE CASCADE
driver_id             UUID FK → users.id ON DELETE CASCADE
flagged_by_user_id    UUID FK → users.id ON DELETE CASCADE  -- Shipper or Admin
shipment_id           UUID FK → freight_posts.id            -- Context
reason                TEXT NOT NULL
notes                 TEXT
status                TEXT DEFAULT 'pending'
admin_notes           TEXT
reviewed_by_admin_id  UUID FK → users.id
reviewed_at           TIMESTAMP
created_at            TIMESTAMP DEFAULT NOW()
updated_at            TIMESTAMP DEFAULT NOW()
```

### 11.6 `driver_bank_accounts` Table

```sql
id                      UUID PRIMARY KEY
driver_id               UUID FK → users.id
bank_name               TEXT NOT NULL
account_number          TEXT NOT NULL
branch_code             TEXT
account_type            TEXT DEFAULT 'savings'
paystack_recipient_code TEXT
paystack_recipient_id   TEXT
is_verified             BOOLEAN DEFAULT false
verified_at             TIMESTAMP
verification_details    JSONB DEFAULT '{}'
is_primary              BOOLEAN DEFAULT true
is_active               BOOLEAN DEFAULT true
created_at              TIMESTAMP DEFAULT NOW()
updated_at              TIMESTAMP DEFAULT NOW()
currency                TEXT DEFAULT 'ZAR'
verified_by             UUID FK
verification_method     TEXT DEFAULT 'api'  -- 'api' (Paystack), 'manual', 'override'
verification_notes      TEXT
rejected_at             TIMESTAMP
rejection_reason        TEXT
```

### 11.7 `verification_status` Enum

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

## 12. RPC Functions

### 12.1 `register_user_as_driver(p_user_id, p_address_lat, p_address_lng, p_address_name)`
- Sets `role = 'Driver'`
- Stores address as PostGIS POINT geometry
- Called at end of registration wizard

### 12.2 `update_user_with_geometry(p_user_id, p_first_name, p_last_name, p_email, p_dob, p_profile_photo_url, p_id_no, p_bank_name, p_account_number, p_branch_code, p_address_lat, p_address_lng, p_address_name)`
- Updates all user profile fields including PostGIS address
- Called when saving personal info or banking info

### 12.3 `update_driver_verification(p_driver_id, p_admin_id, p_new_status, p_reason, p_notes)`
- Admin-only function to change verification status
- Sets `driver_verified_at` and `driver_verified_by` when status = `approved`
- Logs to `driver_approval_history`

### 12.4 `get_driver_by_id(p_driver_id)`
- Returns driver with aggregated statistics (rating, completed deliveries)

### 12.5 `get_completed_deliveries(p_driver_id)`
- Count of shipments with status = `delivered` and `driver_id` matching

---

## 13. Automatic Database Triggers

| Trigger | Fires On | Action |
|---|---|---|
| `trg_notify_driver_registered` | `INSERT` on `users` where `role = 'Driver'` | Notifies all admins: "New driver registered: {name}" |
| `trg_notify_document_uploaded` | `INSERT` on `driver_docs` | Notifies all admins: "New document uploaded by {name}: {doc_type}" |
| `trg_notify_driver_status_changed` | `UPDATE` on `users` | Notifies admins when `driver_verification_status` changes to `pending` or driver is suspended |

---

## 14. Notification Types Used

| `notification_type` | When | Recipient |
|---|---|---|
| `driver_pending_approval` | Driver registers or re-submits docs | All admins |
| `driver_document_uploaded` | Driver uploads a document | All admins |
| `driver_suspended` | Driver is suspended | All admins |

Currently, the LoadRunner app does **not** receive or display admin-to-driver verification notifications (approved, rejected, re-upload requested). This is a gap to be addressed in the unified spec.

---

## 15. Current Gaps and Limitations

These are areas where the current LoadRunner app implementation is incomplete or could be improved for a more automated, robust driver registration process:

### 15.1 No Verification Status Display
- The app does not read or display `driver_docs.verification_status` to the driver
- Documents always show as "Uploaded" regardless of whether admin approved or rejected them
- The driver has no visibility into whether their documents are approved, rejected, or need re-upload

### 15.2 No Rejection / Re-upload Flow
- If admin rejects a document, the driver has no in-app notification or prompt to re-upload
- No mechanism to show rejection reasons from `driver_docs.rejection_reason`
- No "re-upload requested" state in the document upload tile

### 15.3 No Verification Progress Indicator
- After registration, the driver has no dashboard or status bar showing "Verification in progress" / "2 of 4 documents approved"
- No ETA or progress indication

### 15.4 No Vehicle Verification Display
- `vehicles.verification_status` exists in DB but is not read by the app
- Vehicles always show as valid regardless of admin review

### 15.5 No Push Notifications from Admin to Driver
- Existing `notification_type` enum has `driver_pending_approval` and `driver_document_uploaded` for admin-bound notifications
- No dedicated types for driver-bound verification notifications (approved, rejected, re-upload)
- Currently uses `general` type for any admin-to-driver message

### 15.6 No Bank Account Verification Integration
- `driver_bank_accounts` table has Paystack verification fields (`is_verified`, `verification_method`, `paystack_recipient_code`)
- Banking info is saved to `users` table fields, not to `driver_bank_accounts`
- No automated bank account verification via Paystack API during registration

### 15.7 No Document Expiry Tracking
- No expiry date field on documents
- No reminder system for expiring documents (e.g. driver's license renewal)

### 15.8 Bid Gating is Simple
- Only checks `driverVerifiedAt != null`
- Does not check `is_suspended`, `driver_verification_status`, or individual document statuses
- A suspended driver with a past `driverVerifiedAt` would currently pass the check

---

## 16. File Reference

| Component | File Path |
|---|---|
| Driver Profile Screen | `lib/features/user/presentation/screens/driver_profile_screen.dart` |
| Driver Profile Provider | `lib/features/user/presentation/providers/driver_profile_provider.dart` |
| Driver Profile State | `lib/features/user/presentation/state/driver_profile_state.dart` |
| Document Upload Tile | `lib/features/user/presentation/widgets/document_upload_tile.dart` |
| Personal Info Form | `lib/features/user/presentation/widgets/personal_info_form.dart` |
| Banking Info Form | `lib/features/user/presentation/widgets/banking_info_form.dart` |
| Vehicle Form | `lib/features/user/presentation/widgets/vehicle_form.dart` |
| User Entity | `lib/features/user/domain/entities/user_entity.dart` |
| Document Entity | `lib/features/user/domain/entities/document_entity.dart` |
| Vehicle Entity | `lib/features/vehicle/domain/entities/vehicle_entity.dart` |
| User Repository (interface) | `lib/features/user/domain/repositories/user_repository.dart` |
| User Repository (impl) | `lib/features/user/data/repositories/user_repository_impl.dart` |
| Side Menu | `lib/core/components/app_side_menu.dart` |
| Driver Verification Screen | `lib/features/bid/presentation/screens/driver_verification_screen.dart` |
| Document List Widget (shipper view) | `lib/features/bid/presentation/widgets/document_list_widget.dart` |
| Database Schema | `schema.txt` |
