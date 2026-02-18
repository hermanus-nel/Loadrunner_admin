# LoadRunner Admin Dashboard - Database Schema Documentation

## Overview

This document describes the database schema extensions for the LoadRunner Admin Dashboard. The admin dashboard shares the same Supabase backend as the main LoadRunner app.

## Key Design Decisions

### 1. No Separate Admin/Driver Tables
- **Admin accounts**: Use `users` table with `role='Admin'`
- **Driver accounts**: Use `users` table with `role='Driver'`
- **Shipper accounts**: Use `users` table with `role='Shipper'`
- The existing `user_role` enum already includes: `'Shipper'`, `'Driver'`, `'Admin'`, `'Guest'`

### 2. Existing Tables Used
| Table | Purpose |
|-------|---------|
| `users` | All user accounts (admins, drivers, shippers) |
| `driver_docs` | Driver documents with `doc_type` field |
| `vehicles` | Vehicle information |
| `driver_bank_accounts` | Bank account details (already has verification fields) |
| `freight_posts` | Shipments (NOT a separate "shipments" table) |
| `payments` | Payment transactions |

### 3. No shipper_bank_accounts
The schema only has `driver_bank_accounts`. Shippers don't have bank accounts in the system.

### 4. Shippers Are Auto-Approved
Unlike drivers who require verification, shippers are approved automatically upon sign-up.

---

## New ENUMs Created

### verification_status
Used for driver, document, and vehicle verification states.
```sql
CREATE TYPE verification_status AS ENUM (
    'pending',           -- Awaiting review
    'under_review',      -- Admin is reviewing
    'documents_requested', -- Additional documents needed
    'approved',          -- Verified and approved
    'rejected',          -- Rejected (can reapply)
    'suspended'          -- Temporarily suspended
);
```

### dispute_status
```sql
CREATE TYPE dispute_status AS ENUM (
    'open',              -- New dispute
    'under_review',      -- Admin reviewing
    'awaiting_response', -- Waiting for party response
    'resolved',          -- Resolved
    'closed',            -- Closed without resolution
    'escalated'          -- Escalated to higher authority
);
```

### dispute_priority
```sql
CREATE TYPE dispute_priority AS ENUM (
    'low', 'medium', 'high', 'urgent'
);
```

### dispute_type
```sql
CREATE TYPE dispute_type AS ENUM (
    'payment',           -- Payment-related dispute
    'delivery',          -- Delivery issues
    'damage',            -- Cargo damage
    'behavior',          -- Driver/Shipper behavior
    'cancellation',      -- Cancellation dispute
    'other'              -- Other issues
);
```

---

## Extended Tables

### users (extended)

New columns for **Admin users** (role='Admin'):
| Column | Type | Description |
|--------|------|-------------|
| `last_login_at` | TIMESTAMPTZ | Last successful login |
| `failed_login_attempts` | INTEGER | Count of failed logins |
| `locked_until` | TIMESTAMPTZ | Account lockout expiry |

*Note: Using custom auth same as main LoadRunner app (no 2FA)*

New columns for **Driver users** (role='Driver'):
| Column | Type | Description |
|--------|------|-------------|
| `driver_verification_status` | verification_status | Current verification state |
| `driver_verified_by` | UUID | Admin who verified |
| `verification_notes` | TEXT | Admin notes |

New columns for **All users**:
| Column | Type | Description |
|--------|------|-------------|
| `is_suspended` | BOOLEAN | Whether account is suspended |
| `suspended_at` | TIMESTAMPTZ | When suspended |
| `suspended_reason` | TEXT | Reason for suspension |
| `suspended_by` | UUID | Admin who suspended |
| `suspension_ends_at` | TIMESTAMPTZ | When suspension expires |

### driver_docs (extended)

Existing columns: `id`, `created_at`, `doc_type`, `doc_url`, `modified_at`, `driver_id`

**doc_type values**: `'id_document'`, `'proof_of_address'`, `'drivers_license'`, `'pdp'`

New columns:
| Column | Type | Description |
|--------|------|-------------|
| `verification_status` | verification_status | Document verification state |
| `verified_by` | UUID | Admin who verified |
| `verified_at` | TIMESTAMPTZ | When verified |
| `rejection_reason` | TEXT | Why rejected |
| `admin_notes` | TEXT | Internal notes |
| `expiry_date` | DATE | Document expiry date |

### vehicles (extended)

Existing columns: `id`, `driver_id`, `type`, `make`, `model`, `year`, `license_plate`, `capacity_tons`, `photo_url`, `created_at`, `color`

New columns:
| Column | Type | Description |
|--------|------|-------------|
| `verification_status` | verification_status | Vehicle verification state |
| `verified_by` | UUID | Admin who verified |
| `verified_at` | TIMESTAMPTZ | When verified |
| `registration_document_url` | TEXT | Registration document |
| `insurance_document_url` | TEXT | Insurance document |
| `roadworthy_certificate_url` | TEXT | Roadworthy certificate |
| `additional_photos` | JSONB | Array of additional photo URLs |
| `rejection_reason` | TEXT | Why rejected |
| `admin_notes` | TEXT | Internal notes |

### driver_bank_accounts (extended)

Existing columns already include: `is_verified`, `verified_at`, `verification_details`

New columns:
| Column | Type | Description |
|--------|------|-------------|
| `verified_by` | UUID | Admin who verified |
| `verification_method` | TEXT | 'api', 'manual', 'override' |
| `verification_notes` | TEXT | Admin notes |
| `rejected_at` | TIMESTAMPTZ | When rejected |
| `rejection_reason` | TEXT | Why rejected |

---

## New Tables

### admin_audit_logs
Tracks all administrative actions for compliance and debugging.

```sql
CREATE TABLE admin_audit_logs (
    id UUID PRIMARY KEY,
    admin_id UUID NOT NULL REFERENCES users(id),
    action TEXT NOT NULL,
    target_type TEXT NOT NULL,  -- 'user', 'driver', 'vehicle', 'payment', 'dispute'
    target_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### driver_approval_history
Tracks the history of driver verification decisions.

```sql
CREATE TABLE driver_approval_history (
    id UUID PRIMARY KEY,
    driver_id UUID NOT NULL REFERENCES users(id),
    admin_id UUID NOT NULL REFERENCES users(id),
    previous_status verification_status,
    new_status verification_status NOT NULL,
    reason TEXT,
    notes TEXT,
    documents_reviewed JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### disputes
Main disputes table for tracking issues between shippers and drivers.

```sql
CREATE TABLE disputes (
    id UUID PRIMARY KEY,
    freight_post_id UUID NOT NULL REFERENCES freight_posts(id),
    raised_by UUID NOT NULL REFERENCES users(id),
    raised_against UUID NOT NULL REFERENCES users(id),
    dispute_type dispute_type NOT NULL,
    priority dispute_priority DEFAULT 'medium',
    status dispute_status DEFAULT 'open',
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    admin_assigned UUID REFERENCES users(id),
    resolution TEXT,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMPTZ,
    refund_amount NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### dispute_evidence
Stores evidence files and notes for disputes.

```sql
CREATE TABLE dispute_evidence (
    id UUID PRIMARY KEY,
    dispute_id UUID NOT NULL REFERENCES disputes(id) ON DELETE CASCADE,
    submitted_by UUID NOT NULL REFERENCES users(id),
    evidence_type TEXT NOT NULL,  -- 'image', 'document', 'gps_data', 'message', 'note'
    file_url TEXT,
    description TEXT,
    metadata JSONB DEFAULT '{}',  -- GPS coordinates, timestamps, etc.
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### admin_messages
For admin-to-user messaging.

```sql
CREATE TABLE admin_messages (
    id UUID PRIMARY KEY,
    sent_by UUID NOT NULL REFERENCES users(id),
    recipient_id UUID REFERENCES users(id),
    message_type TEXT DEFAULT 'direct',  -- 'direct', 'broadcast', 'system'
    recipient_role user_role,  -- For broadcasts: 'Driver', 'Shipper', or NULL for all
    subject TEXT,
    body TEXT NOT NULL,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ,
    push_notification_sent BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'
);
```

---

## Helper Functions

### log_admin_action
Logs an admin action to the audit log.
```sql
SELECT log_admin_action(
    admin_id,
    'action_name',
    'target_type',
    target_id,
    old_values_jsonb,
    new_values_jsonb
);
```

### update_driver_verification
Updates a driver's verification status with full audit trail.
```sql
SELECT update_driver_verification(
    driver_id,
    admin_id,
    'approved'::verification_status,
    'All documents verified',
    'Optional notes'
);
```

### set_user_suspension
Suspends or unsuspends a user.
```sql
SELECT set_user_suspension(
    user_id,
    admin_id,
    TRUE,  -- is_suspended
    'Policy violation',
    '2026-02-01 00:00:00'::timestamptz  -- optional end date
);
```

---

## Row Level Security

All new tables have RLS enabled with the following policies:

| Table | Admins | Users |
|-------|--------|-------|
| admin_audit_logs | View all | No access |
| driver_approval_history | View all | View own only |
| disputes | Full access | View/create own |
| dispute_evidence | Full access | View/add to own disputes |
| admin_messages | Full access | View own messages |

---

## Query Examples

### Get pending driver approvals
```sql
SELECT u.id, u.first_name, u.last_name, u.phone_number,
       u.driver_verification_status, u.created_at
FROM users u
WHERE u.role = 'Driver'
  AND u.driver_verification_status = 'pending'
ORDER BY u.created_at ASC;
```

### Get driver with all documents
```sql
SELECT u.*, 
       json_agg(dd.*) as documents
FROM users u
LEFT JOIN driver_docs dd ON dd.driver_id = u.id
WHERE u.id = 'driver-uuid-here'
  AND u.role = 'Driver'
GROUP BY u.id;
```

### Get open disputes
```sql
SELECT d.*, 
       fp.description as shipment_description,
       raised.first_name as raised_by_name,
       against.first_name as raised_against_name
FROM disputes d
JOIN freight_posts fp ON fp.id = d.freight_post_id
JOIN users raised ON raised.id = d.raised_by
JOIN users against ON against.id = d.raised_against
WHERE d.status IN ('open', 'under_review')
ORDER BY d.priority DESC, d.created_at ASC;
```

---

## Migration Instructions

1. Connect to your Supabase project's SQL editor
2. Run the migration file: `supabase/migrations/20260127_admin_dashboard_schema_v2.sql`
3. The migration is idempotent - safe to run multiple times
4. Verify by checking for the new tables and columns

```sql
-- Verify new tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('admin_audit_logs', 'driver_approval_history', 
                     'disputes', 'dispute_evidence', 'admin_messages');

-- Verify new enums exist
SELECT typname FROM pg_type 
WHERE typname IN ('verification_status', 'dispute_status', 
                  'dispute_priority', 'dispute_type');
```
