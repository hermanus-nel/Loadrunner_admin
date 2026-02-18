-- ============================================================================
-- LOADRUNNER ADMIN DASHBOARD SCHEMA MIGRATION v2.0 PATCH
-- ============================================================================
-- Version: 2.0.1
-- Date: January 30, 2026
-- Description: Adds missing columns and helper functions per spec
-- ============================================================================

-- ============================================================================
-- SECTION 1: MISSING USERS TABLE COLUMNS
-- ============================================================================

DO $$
BEGIN
    -- Last login IP address for security tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'public'
                   AND table_name = 'users'
                   AND column_name = 'last_login_ip') THEN
        ALTER TABLE public.users ADD COLUMN last_login_ip INET;
        RAISE NOTICE 'Added last_login_ip to users table';
    END IF;

    -- Driver rejection reason (direct access without querying approval history)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'public'
                   AND table_name = 'users'
                   AND column_name = 'driver_rejection_reason') THEN
        ALTER TABLE public.users ADD COLUMN driver_rejection_reason TEXT;
        RAISE NOTICE 'Added driver_rejection_reason to users table';
    END IF;
END $$;

-- ============================================================================
-- SECTION 2: MISSING HELPER FUNCTIONS
-- ============================================================================

-- 2.1 Get admin dashboard stats
-- Returns key metrics for the dashboard home screen in a single call
CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_active_shipments INT;
    v_pending_approvals INT;
    v_new_registrations INT;
    v_active_users INT;
    v_revenue_today NUMERIC(10,2);
    v_pending_disputes INT;
    v_pending_bank_verifications INT;
    v_pending_document_verifications INT;
    v_total_drivers INT;
    v_total_shippers INT;
BEGIN
    -- Active shipments
    SELECT COUNT(*) INTO v_active_shipments
    FROM public.freight_posts
    WHERE status IN ('Bidding', 'Pickup', 'OnRoute');

    -- Pending driver approvals
    SELECT COUNT(*) INTO v_pending_approvals
    FROM public.users
    WHERE role = 'Driver' AND driver_verification_status = 'pending';

    -- New registrations today
    SELECT COUNT(*) INTO v_new_registrations
    FROM public.users
    WHERE created_at >= date_trunc('day', NOW() AT TIME ZONE 'UTC');

    -- Active users in last 24 hours
    SELECT COUNT(*) INTO v_active_users
    FROM public.users
    WHERE last_login_at >= NOW() - INTERVAL '24 hours';

    -- Revenue today (completed payments)
    SELECT COALESCE(SUM(amount), 0) INTO v_revenue_today
    FROM public.payments
    WHERE status = 'Completed'
    AND created_at >= date_trunc('day', NOW() AT TIME ZONE 'UTC');

    -- Pending disputes
    SELECT COUNT(*) INTO v_pending_disputes
    FROM public.disputes
    WHERE status IN ('open', 'under_review');

    -- Pending bank verifications
    SELECT COUNT(*) INTO v_pending_bank_verifications
    FROM public.driver_bank_accounts
    WHERE is_verified = FALSE;

    -- Pending document verifications
    SELECT COUNT(*) INTO v_pending_document_verifications
    FROM public.driver_docs
    WHERE verification_status = 'pending';

    -- Total drivers
    SELECT COUNT(*) INTO v_total_drivers
    FROM public.users
    WHERE role = 'Driver';

    -- Total shippers
    SELECT COUNT(*) INTO v_total_shippers
    FROM public.users
    WHERE role = 'Shipper';

    -- Build result
    v_result := json_build_object(
        'active_shipments', v_active_shipments,
        'pending_driver_approvals', v_pending_approvals,
        'new_registrations_today', v_new_registrations,
        'active_users_24h', v_active_users,
        'revenue_today', v_revenue_today,
        'pending_disputes', v_pending_disputes,
        'pending_bank_verifications', v_pending_bank_verifications,
        'pending_document_verifications', v_pending_document_verifications,
        'total_drivers', v_total_drivers,
        'total_shippers', v_total_shippers,
        'fetched_at', NOW()
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_admin_dashboard_stats() IS 'Returns all key dashboard metrics in a single call for optimal performance';

-- 2.2 Get pending document verifications
-- Returns a list of documents awaiting admin verification
CREATE OR REPLACE FUNCTION public.get_pending_document_verifications(
    p_limit INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    doc_id UUID,
    doc_type TEXT,
    doc_url TEXT,
    driver_id UUID,
    driver_first_name TEXT,
    driver_last_name TEXT,
    driver_phone TEXT,
    submitted_at TIMESTAMPTZ,
    verification_status public.verification_status
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        dd.id AS doc_id,
        dd.doc_type,
        dd.doc_url,
        dd.driver_id,
        u.first_name AS driver_first_name,
        u.last_name AS driver_last_name,
        u.phone_number AS driver_phone,
        dd.created_at AS submitted_at,
        dd.verification_status
    FROM public.driver_docs dd
    JOIN public.users u ON u.id = dd.driver_id
    WHERE dd.verification_status = 'pending'
    ORDER BY dd.created_at ASC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_pending_document_verifications(INT, INT) IS 'Returns pending document verifications with driver info, ordered by submission date';

-- ============================================================================
-- PATCH COMPLETE
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Admin Dashboard Schema v2.0 Patch Complete';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Added columns: last_login_ip, driver_rejection_reason';
    RAISE NOTICE 'Added functions: get_admin_dashboard_stats, get_pending_document_verifications';
    RAISE NOTICE '============================================';
END $$;
