-- ============================================================================
-- LOADRUNNER ADMIN DASHBOARD SCHEMA MIGRATION v2.0
-- ============================================================================
-- Version: 2.0
-- Date: January 27, 2026
-- Description: Adds admin dashboard functionality to existing LoadRunner database
-- 
-- IMPORTANT: This migration is designed to be IDEMPOTENT - safe to run multiple times
--
-- KEY DATABASE FACTS (based on actual schema.txt):
-- - Admin accounts use: users table with role='Admin' (no separate admin_users table)
-- - Driver accounts use: users table with role='Driver' (no separate drivers table)
-- - Shipper accounts use: users table with role='Shipper' (auto-approved)
-- - Driver documents: driver_docs table with doc_type field
-- - Shipments: freight_posts table (not a separate shipments table)
-- - Bank accounts: driver_bank_accounts only (no shipper_bank_accounts in schema)
-- - Existing user_role ENUM: 'Shipper', 'Driver', 'Admin', 'Guest'
-- ============================================================================

-- ============================================================================
-- SECTION 1: CREATE NEW ENUMS FOR TYPE SAFETY
-- ============================================================================

-- 1.1 Driver/Vehicle verification status enum
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'verification_status') THEN
        CREATE TYPE public.verification_status AS ENUM (
            'pending',           -- Awaiting review
            'under_review',      -- Admin is reviewing
            'documents_requested', -- Additional documents needed
            'approved',          -- Verified and approved
            'rejected',          -- Rejected (can reapply)
            'suspended'          -- Temporarily suspended
        );
        RAISE NOTICE 'Created verification_status enum';
    ELSE
        RAISE NOTICE 'verification_status enum already exists';
    END IF;
END $$;

-- 1.2 Dispute status enum
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'dispute_status') THEN
        CREATE TYPE public.dispute_status AS ENUM (
            'open',              -- New dispute
            'under_review',      -- Admin reviewing
            'awaiting_response', -- Waiting for party response
            'resolved',          -- Resolved
            'closed',            -- Closed without resolution
            'escalated'          -- Escalated to higher authority
        );
        RAISE NOTICE 'Created dispute_status enum';
    ELSE
        RAISE NOTICE 'dispute_status enum already exists';
    END IF;
END $$;

-- 1.3 Dispute priority enum
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'dispute_priority') THEN
        CREATE TYPE public.dispute_priority AS ENUM (
            'low',
            'medium',
            'high',
            'urgent'
        );
        RAISE NOTICE 'Created dispute_priority enum';
    ELSE
        RAISE NOTICE 'dispute_priority enum already exists';
    END IF;
END $$;

-- 1.4 Dispute type enum
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'dispute_type') THEN
        CREATE TYPE public.dispute_type AS ENUM (
            'payment',           -- Payment-related dispute
            'delivery',          -- Delivery issues
            'damage',            -- Cargo damage
            'behavior',          -- Driver/Shipper behavior
            'cancellation',      -- Cancellation dispute
            'other'              -- Other issues
        );
        RAISE NOTICE 'Created dispute_type enum';
    ELSE
        RAISE NOTICE 'dispute_type enum already exists';
    END IF;
END $$;

-- ============================================================================
-- SECTION 2: EXTEND USERS TABLE
-- ============================================================================
-- The users table stores ALL user types (Admin, Driver, Shipper, Guest)
-- We add fields for admin functionality and driver verification tracking

-- 2.1 Admin-specific fields (for users with role='Admin')
-- Note: Using custom auth same as main LoadRunner app (no 2FA)
DO $$
BEGIN
    -- Last login timestamp
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'users' 
                   AND column_name = 'last_login_at') THEN
        ALTER TABLE public.users ADD COLUMN last_login_at TIMESTAMPTZ;
        RAISE NOTICE 'Added last_login_at to users table';
    END IF;

    -- Failed login attempts counter
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'users' 
                   AND column_name = 'failed_login_attempts') THEN
        ALTER TABLE public.users ADD COLUMN failed_login_attempts INTEGER DEFAULT 0;
        RAISE NOTICE 'Added failed_login_attempts to users table';
    END IF;

    -- Account lockout timestamp
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'users' 
                   AND column_name = 'locked_until') THEN
        ALTER TABLE public.users ADD COLUMN locked_until TIMESTAMPTZ;
        RAISE NOTICE 'Added locked_until to users table';
    END IF;
END $$;

-- 2.2 Driver verification status (for users with role='Driver')
DO $$
BEGIN
    -- Driver verification status using new enum
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'users' 
                   AND column_name = 'driver_verification_status') THEN
        ALTER TABLE public.users ADD COLUMN driver_verification_status public.verification_status DEFAULT 'pending';
        RAISE NOTICE 'Added driver_verification_status to users table';
    END IF;

    -- Who verified this driver (references another user with role='Admin')
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'users' 
                   AND column_name = 'driver_verified_by') THEN
        ALTER TABLE public.users ADD COLUMN driver_verified_by UUID REFERENCES public.users(id);
        RAISE NOTICE 'Added driver_verified_by to users table';
    END IF;

    -- Verification notes (admin comments)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'users' 
                   AND column_name = 'verification_notes') THEN
        ALTER TABLE public.users ADD COLUMN verification_notes TEXT;
        RAISE NOTICE 'Added verification_notes to users table';
    END IF;
END $$;

-- 2.3 Suspension fields (for any user type)
DO $$
BEGIN
    -- Is user suspended
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'users' 
                   AND column_name = 'is_suspended') THEN
        ALTER TABLE public.users ADD COLUMN is_suspended BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Added is_suspended to users table';
    END IF;

    -- When was user suspended
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'users' 
                   AND column_name = 'suspended_at') THEN
        ALTER TABLE public.users ADD COLUMN suspended_at TIMESTAMPTZ;
        RAISE NOTICE 'Added suspended_at to users table';
    END IF;

    -- Reason for suspension
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'users' 
                   AND column_name = 'suspended_reason') THEN
        ALTER TABLE public.users ADD COLUMN suspended_reason TEXT;
        RAISE NOTICE 'Added suspended_reason to users table';
    END IF;

    -- Who suspended this user (admin user id)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'users' 
                   AND column_name = 'suspended_by') THEN
        ALTER TABLE public.users ADD COLUMN suspended_by UUID REFERENCES public.users(id);
        RAISE NOTICE 'Added suspended_by to users table';
    END IF;

    -- Suspension end date (for temporary suspensions)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'users' 
                   AND column_name = 'suspension_ends_at') THEN
        ALTER TABLE public.users ADD COLUMN suspension_ends_at TIMESTAMPTZ;
        RAISE NOTICE 'Added suspension_ends_at to users table';
    END IF;
END $$;

-- Add index for admin queries on users
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_driver_verification_status ON public.users(driver_verification_status) WHERE role = 'Driver';
CREATE INDEX IF NOT EXISTS idx_users_is_suspended ON public.users(is_suspended) WHERE is_suspended = TRUE;

-- ============================================================================
-- SECTION 3: EXTEND DRIVER_DOCS TABLE
-- ============================================================================
-- Existing columns: id, created_at, doc_type, doc_url, modified_at, driver_id
-- doc_type values: 'id_document', 'proof_of_address', 'drivers_license', 'pdp'

DO $$
BEGIN
    -- Document verification status
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'driver_docs' 
                   AND column_name = 'verification_status') THEN
        ALTER TABLE public.driver_docs ADD COLUMN verification_status public.verification_status DEFAULT 'pending';
        RAISE NOTICE 'Added verification_status to driver_docs table';
    END IF;

    -- Who verified this document
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'driver_docs' 
                   AND column_name = 'verified_by') THEN
        ALTER TABLE public.driver_docs ADD COLUMN verified_by UUID REFERENCES public.users(id);
        RAISE NOTICE 'Added verified_by to driver_docs table';
    END IF;

    -- When was document verified
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'driver_docs' 
                   AND column_name = 'verified_at') THEN
        ALTER TABLE public.driver_docs ADD COLUMN verified_at TIMESTAMPTZ;
        RAISE NOTICE 'Added verified_at to driver_docs table';
    END IF;

    -- Rejection reason (if rejected)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'driver_docs' 
                   AND column_name = 'rejection_reason') THEN
        ALTER TABLE public.driver_docs ADD COLUMN rejection_reason TEXT;
        RAISE NOTICE 'Added rejection_reason to driver_docs table';
    END IF;

    -- Admin notes
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'driver_docs' 
                   AND column_name = 'admin_notes') THEN
        ALTER TABLE public.driver_docs ADD COLUMN admin_notes TEXT;
        RAISE NOTICE 'Added admin_notes to driver_docs table';
    END IF;

    -- Document expiry date (for licenses, etc.)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'driver_docs' 
                   AND column_name = 'expiry_date') THEN
        ALTER TABLE public.driver_docs ADD COLUMN expiry_date DATE;
        RAISE NOTICE 'Added expiry_date to driver_docs table';
    END IF;
END $$;

-- Add indexes for driver_docs
CREATE INDEX IF NOT EXISTS idx_driver_docs_verification_status ON public.driver_docs(verification_status);
CREATE INDEX IF NOT EXISTS idx_driver_docs_driver_id ON public.driver_docs(driver_id);

-- ============================================================================
-- SECTION 4: EXTEND VEHICLES TABLE
-- ============================================================================
-- Existing columns: id, driver_id, type, make, model, year, license_plate, 
--                   capacity_tons, photo_url, created_at, color

DO $$
BEGIN
    -- Vehicle verification status
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'vehicles' 
                   AND column_name = 'verification_status') THEN
        ALTER TABLE public.vehicles ADD COLUMN verification_status public.verification_status DEFAULT 'pending';
        RAISE NOTICE 'Added verification_status to vehicles table';
    END IF;

    -- Who verified this vehicle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'vehicles' 
                   AND column_name = 'verified_by') THEN
        ALTER TABLE public.vehicles ADD COLUMN verified_by UUID REFERENCES public.users(id);
        RAISE NOTICE 'Added verified_by to vehicles table';
    END IF;

    -- When was vehicle verified
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'vehicles' 
                   AND column_name = 'verified_at') THEN
        ALTER TABLE public.vehicles ADD COLUMN verified_at TIMESTAMPTZ;
        RAISE NOTICE 'Added verified_at to vehicles table';
    END IF;

    -- Registration document URL
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'vehicles' 
                   AND column_name = 'registration_document_url') THEN
        ALTER TABLE public.vehicles ADD COLUMN registration_document_url TEXT;
        RAISE NOTICE 'Added registration_document_url to vehicles table';
    END IF;

    -- Insurance document URL (may already exist as insurance_document_url)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'vehicles' 
                   AND column_name = 'insurance_document_url') THEN
        ALTER TABLE public.vehicles ADD COLUMN insurance_document_url TEXT;
        RAISE NOTICE 'Added insurance_document_url to vehicles table';
    END IF;

    -- Roadworthy certificate URL
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'vehicles' 
                   AND column_name = 'roadworthy_certificate_url') THEN
        ALTER TABLE public.vehicles ADD COLUMN roadworthy_certificate_url TEXT;
        RAISE NOTICE 'Added roadworthy_certificate_url to vehicles table';
    END IF;

    -- Additional vehicle photos (JSON array of URLs)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'vehicles' 
                   AND column_name = 'additional_photos') THEN
        ALTER TABLE public.vehicles ADD COLUMN additional_photos JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Added additional_photos to vehicles table';
    END IF;

    -- Rejection reason
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'vehicles' 
                   AND column_name = 'rejection_reason') THEN
        ALTER TABLE public.vehicles ADD COLUMN rejection_reason TEXT;
        RAISE NOTICE 'Added rejection_reason to vehicles table';
    END IF;

    -- Admin notes
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'vehicles' 
                   AND column_name = 'admin_notes') THEN
        ALTER TABLE public.vehicles ADD COLUMN admin_notes TEXT;
        RAISE NOTICE 'Added admin_notes to vehicles table';
    END IF;
END $$;

-- Add indexes for vehicles
CREATE INDEX IF NOT EXISTS idx_vehicles_verification_status ON public.vehicles(verification_status);
CREATE INDEX IF NOT EXISTS idx_vehicles_driver_id ON public.vehicles(driver_id);

-- ============================================================================
-- SECTION 5: EXTEND DRIVER_BANK_ACCOUNTS TABLE
-- ============================================================================
-- Existing columns: id, driver_id, bank_code, bank_name, account_number,
--                   account_name, paystack_recipient_code, paystack_recipient_id,
--                   is_verified, verified_at, verification_details, is_primary,
--                   is_active, created_at, updated_at, currency

DO $$
BEGIN
    -- Who verified this bank account (admin user id)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'driver_bank_accounts' 
                   AND column_name = 'verified_by') THEN
        ALTER TABLE public.driver_bank_accounts ADD COLUMN verified_by UUID REFERENCES public.users(id);
        RAISE NOTICE 'Added verified_by to driver_bank_accounts table';
    END IF;

    -- Verification method
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'driver_bank_accounts' 
                   AND column_name = 'verification_method') THEN
        ALTER TABLE public.driver_bank_accounts ADD COLUMN verification_method TEXT DEFAULT 'api';
        COMMENT ON COLUMN public.driver_bank_accounts.verification_method IS 'Method used: api (Paystack), manual, override';
        RAISE NOTICE 'Added verification_method to driver_bank_accounts table';
    END IF;

    -- Verification notes
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'driver_bank_accounts' 
                   AND column_name = 'verification_notes') THEN
        ALTER TABLE public.driver_bank_accounts ADD COLUMN verification_notes TEXT;
        RAISE NOTICE 'Added verification_notes to driver_bank_accounts table';
    END IF;

    -- Rejection timestamp
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'driver_bank_accounts' 
                   AND column_name = 'rejected_at') THEN
        ALTER TABLE public.driver_bank_accounts ADD COLUMN rejected_at TIMESTAMPTZ;
        RAISE NOTICE 'Added rejected_at to driver_bank_accounts table';
    END IF;

    -- Rejection reason
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'driver_bank_accounts' 
                   AND column_name = 'rejection_reason') THEN
        ALTER TABLE public.driver_bank_accounts ADD COLUMN rejection_reason TEXT;
        RAISE NOTICE 'Added rejection_reason to driver_bank_accounts table';
    END IF;
END $$;

-- ============================================================================
-- SECTION 6: CREATE NEW ADMIN DASHBOARD TABLES
-- ============================================================================

-- 6.1 Admin Audit Logs
-- Tracks all administrative actions for compliance and debugging
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES public.users(id),
    action TEXT NOT NULL,
    target_type TEXT NOT NULL,  -- 'user', 'driver', 'vehicle', 'payment', 'dispute', etc.
    target_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Add comment
COMMENT ON TABLE public.admin_audit_logs IS 'Tracks all administrative actions for compliance and debugging';

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_admin_id ON public.admin_audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_target ON public.admin_audit_logs(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_created_at ON public.admin_audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_action ON public.admin_audit_logs(action);

-- 6.2 Driver Approval History
-- Tracks the history of driver verification decisions
CREATE TABLE IF NOT EXISTS public.driver_approval_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES public.users(id),
    admin_id UUID NOT NULL REFERENCES public.users(id),
    previous_status public.verification_status,
    new_status public.verification_status NOT NULL,
    reason TEXT,
    notes TEXT,
    documents_reviewed JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Add comment
COMMENT ON TABLE public.driver_approval_history IS 'Tracks the history of driver verification status changes';

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_driver_approval_history_driver_id ON public.driver_approval_history(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_approval_history_admin_id ON public.driver_approval_history(admin_id);
CREATE INDEX IF NOT EXISTS idx_driver_approval_history_created_at ON public.driver_approval_history(created_at DESC);

-- 6.3 Disputes
-- Main disputes table for tracking issues between shippers and drivers
CREATE TABLE IF NOT EXISTS public.disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    freight_post_id UUID NOT NULL REFERENCES public.freight_posts(id),
    raised_by UUID NOT NULL REFERENCES public.users(id),
    raised_against UUID NOT NULL REFERENCES public.users(id),
    dispute_type public.dispute_type NOT NULL,
    priority public.dispute_priority DEFAULT 'medium' NOT NULL,
    status public.dispute_status DEFAULT 'open' NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    admin_assigned UUID REFERENCES public.users(id),
    resolution TEXT,
    resolved_by UUID REFERENCES public.users(id),
    resolved_at TIMESTAMPTZ,
    refund_amount NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Add comments
COMMENT ON TABLE public.disputes IS 'Tracks disputes between shippers and drivers';
COMMENT ON COLUMN public.disputes.raised_by IS 'User who raised the dispute (shipper or driver)';
COMMENT ON COLUMN public.disputes.raised_against IS 'User the dispute is against (shipper or driver)';
COMMENT ON COLUMN public.disputes.admin_assigned IS 'Admin user assigned to handle this dispute';

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_disputes_status ON public.disputes(status);
CREATE INDEX IF NOT EXISTS idx_disputes_priority ON public.disputes(priority);
CREATE INDEX IF NOT EXISTS idx_disputes_freight_post_id ON public.disputes(freight_post_id);
CREATE INDEX IF NOT EXISTS idx_disputes_raised_by ON public.disputes(raised_by);
CREATE INDEX IF NOT EXISTS idx_disputes_raised_against ON public.disputes(raised_against);
CREATE INDEX IF NOT EXISTS idx_disputes_admin_assigned ON public.disputes(admin_assigned);
CREATE INDEX IF NOT EXISTS idx_disputes_created_at ON public.disputes(created_at DESC);

-- 6.4 Dispute Evidence
-- Stores evidence files and notes for disputes
CREATE TABLE IF NOT EXISTS public.dispute_evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispute_id UUID NOT NULL REFERENCES public.disputes(id) ON DELETE CASCADE,
    submitted_by UUID NOT NULL REFERENCES public.users(id),
    evidence_type TEXT NOT NULL,  -- 'image', 'document', 'gps_data', 'message', 'note'
    file_url TEXT,
    description TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Add comment
COMMENT ON TABLE public.dispute_evidence IS 'Stores evidence files and notes for disputes';
COMMENT ON COLUMN public.dispute_evidence.metadata IS 'Additional data like GPS coordinates, timestamps, etc.';

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_dispute_evidence_dispute_id ON public.dispute_evidence(dispute_id);
CREATE INDEX IF NOT EXISTS idx_dispute_evidence_submitted_by ON public.dispute_evidence(submitted_by);

-- 6.5 Admin Messages
-- For admin-to-user messaging
CREATE TABLE IF NOT EXISTS public.admin_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sent_by UUID NOT NULL REFERENCES public.users(id),
    recipient_id UUID REFERENCES public.users(id),
    message_type TEXT NOT NULL DEFAULT 'direct',  -- 'direct', 'broadcast', 'system'
    recipient_role public.user_role,  -- For broadcasts: 'Driver', 'Shipper', or NULL for all
    subject TEXT,
    body TEXT NOT NULL,
    sent_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    read_at TIMESTAMPTZ,
    push_notification_sent BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Add comments
COMMENT ON TABLE public.admin_messages IS 'Admin-to-user messaging system';
COMMENT ON COLUMN public.admin_messages.recipient_role IS 'For broadcasts: target role (Driver, Shipper, or NULL for all)';
COMMENT ON COLUMN public.admin_messages.message_type IS 'direct = single user, broadcast = multiple users, system = automated';

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_admin_messages_sent_by ON public.admin_messages(sent_by);
CREATE INDEX IF NOT EXISTS idx_admin_messages_recipient_id ON public.admin_messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_admin_messages_sent_at ON public.admin_messages(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_messages_unread ON public.admin_messages(recipient_id, read_at) WHERE read_at IS NULL;

-- ============================================================================
-- SECTION 7: DATA MIGRATION FOR EXISTING RECORDS
-- ============================================================================

-- Set default verification status for existing drivers
UPDATE public.users 
SET driver_verification_status = 
    CASE 
        WHEN driver_verified_at IS NOT NULL THEN 'approved'::public.verification_status
        ELSE 'pending'::public.verification_status
    END
WHERE role = 'Driver' 
AND driver_verification_status IS NULL;

-- Set default verification status for existing driver documents
UPDATE public.driver_docs 
SET verification_status = 'pending'::public.verification_status
WHERE verification_status IS NULL;

-- Set default verification status for existing vehicles
UPDATE public.vehicles 
SET verification_status = 'pending'::public.verification_status
WHERE verification_status IS NULL;

-- ============================================================================
-- SECTION 8: HELPER FUNCTIONS
-- ============================================================================

-- 8.1 Function to log admin actions
CREATE OR REPLACE FUNCTION public.log_admin_action(
    p_admin_id UUID,
    p_action TEXT,
    p_target_type TEXT,
    p_target_id UUID DEFAULT NULL,
    p_old_values JSONB DEFAULT NULL,
    p_new_values JSONB DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO public.admin_audit_logs (
        admin_id, action, target_type, target_id, 
        old_values, new_values, ip_address, user_agent
    ) VALUES (
        p_admin_id, p_action, p_target_type, p_target_id,
        p_old_values, p_new_values, p_ip_address, p_user_agent
    ) RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8.2 Function to update driver verification status
CREATE OR REPLACE FUNCTION public.update_driver_verification(
    p_driver_id UUID,
    p_admin_id UUID,
    p_new_status public.verification_status,
    p_reason TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_old_status public.verification_status;
BEGIN
    -- Get current status
    SELECT driver_verification_status INTO v_old_status
    FROM public.users
    WHERE id = p_driver_id AND role = 'Driver';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Driver not found: %', p_driver_id;
    END IF;
    
    -- Update user record
    UPDATE public.users
    SET driver_verification_status = p_new_status,
        driver_verified_by = CASE WHEN p_new_status = 'approved' THEN p_admin_id ELSE driver_verified_by END,
        driver_verified_at = CASE WHEN p_new_status = 'approved' THEN NOW() ELSE driver_verified_at END,
        verification_notes = COALESCE(p_notes, verification_notes),
        updated_at = NOW()
    WHERE id = p_driver_id;
    
    -- Log the change
    INSERT INTO public.driver_approval_history (
        driver_id, admin_id, previous_status, new_status, reason, notes
    ) VALUES (
        p_driver_id, p_admin_id, v_old_status, p_new_status, p_reason, p_notes
    );
    
    -- Log admin action
    PERFORM public.log_admin_action(
        p_admin_id,
        'update_driver_verification',
        'user',
        p_driver_id,
        jsonb_build_object('status', v_old_status),
        jsonb_build_object('status', p_new_status, 'reason', p_reason)
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8.3 Function to suspend/unsuspend a user
CREATE OR REPLACE FUNCTION public.set_user_suspension(
    p_user_id UUID,
    p_admin_id UUID,
    p_is_suspended BOOLEAN,
    p_reason TEXT DEFAULT NULL,
    p_ends_at TIMESTAMPTZ DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.users
    SET is_suspended = p_is_suspended,
        suspended_at = CASE WHEN p_is_suspended THEN NOW() ELSE NULL END,
        suspended_reason = CASE WHEN p_is_suspended THEN p_reason ELSE NULL END,
        suspended_by = CASE WHEN p_is_suspended THEN p_admin_id ELSE NULL END,
        suspension_ends_at = CASE WHEN p_is_suspended THEN p_ends_at ELSE NULL END,
        updated_at = NOW()
    WHERE id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found: %', p_user_id;
    END IF;
    
    -- Log admin action
    PERFORM public.log_admin_action(
        p_admin_id,
        CASE WHEN p_is_suspended THEN 'suspend_user' ELSE 'unsuspend_user' END,
        'user',
        p_user_id,
        NULL,
        jsonb_build_object('reason', p_reason, 'ends_at', p_ends_at)
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- SECTION 9: TRIGGERS
-- ============================================================================

-- 9.1 Trigger to update updated_at on disputes
CREATE OR REPLACE FUNCTION public.update_disputes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_disputes_updated_at ON public.disputes;
CREATE TRIGGER trigger_disputes_updated_at
    BEFORE UPDATE ON public.disputes
    FOR EACH ROW
    EXECUTE FUNCTION public.update_disputes_updated_at();

-- ============================================================================
-- SECTION 10: ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS on new tables
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_approval_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dispute_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_messages ENABLE ROW LEVEL SECURITY;

-- 10.1 Admin Audit Logs - Only admins can view
DROP POLICY IF EXISTS "Admins can view audit logs" ON public.admin_audit_logs;
CREATE POLICY "Admins can view audit logs" ON public.admin_audit_logs
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'Admin'
        )
    );

DROP POLICY IF EXISTS "Service role full access to audit logs" ON public.admin_audit_logs;
CREATE POLICY "Service role full access to audit logs" ON public.admin_audit_logs
    TO service_role
    USING (TRUE)
    WITH CHECK (TRUE);

-- 10.2 Driver Approval History - Admins can view all, drivers can view their own
DROP POLICY IF EXISTS "Admins can view all approval history" ON public.driver_approval_history;
CREATE POLICY "Admins can view all approval history" ON public.driver_approval_history
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'Admin'
        )
    );

DROP POLICY IF EXISTS "Drivers can view their own approval history" ON public.driver_approval_history;
CREATE POLICY "Drivers can view their own approval history" ON public.driver_approval_history
    FOR SELECT
    TO authenticated
    USING (driver_id = auth.uid());

DROP POLICY IF EXISTS "Service role full access to approval history" ON public.driver_approval_history;
CREATE POLICY "Service role full access to approval history" ON public.driver_approval_history
    TO service_role
    USING (TRUE)
    WITH CHECK (TRUE);

-- 10.3 Disputes - Admins can view all, users can view their own
DROP POLICY IF EXISTS "Admins can manage all disputes" ON public.disputes;
CREATE POLICY "Admins can manage all disputes" ON public.disputes
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'Admin'
        )
    );

DROP POLICY IF EXISTS "Users can view their own disputes" ON public.disputes;
CREATE POLICY "Users can view their own disputes" ON public.disputes
    FOR SELECT
    TO authenticated
    USING (raised_by = auth.uid() OR raised_against = auth.uid());

DROP POLICY IF EXISTS "Users can create disputes" ON public.disputes;
CREATE POLICY "Users can create disputes" ON public.disputes
    FOR INSERT
    TO authenticated
    WITH CHECK (raised_by = auth.uid());

-- 10.4 Dispute Evidence - Admins can view all, parties can view and add to their disputes
DROP POLICY IF EXISTS "Admins can manage all evidence" ON public.dispute_evidence;
CREATE POLICY "Admins can manage all evidence" ON public.dispute_evidence
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'Admin'
        )
    );

DROP POLICY IF EXISTS "Dispute parties can view evidence" ON public.dispute_evidence;
CREATE POLICY "Dispute parties can view evidence" ON public.dispute_evidence
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.disputes d
            WHERE d.id = dispute_id 
            AND (d.raised_by = auth.uid() OR d.raised_against = auth.uid())
        )
    );

DROP POLICY IF EXISTS "Dispute parties can add evidence" ON public.dispute_evidence;
CREATE POLICY "Dispute parties can add evidence" ON public.dispute_evidence
    FOR INSERT
    TO authenticated
    WITH CHECK (
        submitted_by = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.disputes d
            WHERE d.id = dispute_id 
            AND (d.raised_by = auth.uid() OR d.raised_against = auth.uid())
            AND d.status NOT IN ('resolved', 'closed')
        )
    );

-- 10.5 Admin Messages - Admins can send, recipients can view
DROP POLICY IF EXISTS "Admins can manage messages" ON public.admin_messages;
CREATE POLICY "Admins can manage messages" ON public.admin_messages
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'Admin'
        )
    );

DROP POLICY IF EXISTS "Users can view their messages" ON public.admin_messages;
CREATE POLICY "Users can view their messages" ON public.admin_messages
    FOR SELECT
    TO authenticated
    USING (
        recipient_id = auth.uid() 
        OR (message_type = 'broadcast' AND (
            recipient_role IS NULL 
            OR recipient_role = (SELECT role FROM public.users WHERE id = auth.uid())
        ))
    );

DROP POLICY IF EXISTS "Users can mark messages as read" ON public.admin_messages;
CREATE POLICY "Users can mark messages as read" ON public.admin_messages
    FOR UPDATE
    TO authenticated
    USING (recipient_id = auth.uid())
    WITH CHECK (recipient_id = auth.uid());

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Log completion
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Admin Dashboard Schema Migration v2.0 Complete';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Created ENUMs: verification_status, dispute_status, dispute_priority, dispute_type';
    RAISE NOTICE 'Extended tables: users, driver_docs, vehicles, driver_bank_accounts';
    RAISE NOTICE 'Created tables: admin_audit_logs, driver_approval_history, disputes, dispute_evidence, admin_messages';
    RAISE NOTICE 'Created functions: log_admin_action, update_driver_verification, set_user_suspension';
    RAISE NOTICE 'Created RLS policies for all new tables';
    RAISE NOTICE '============================================';
END $$;
