-- ============================================================================
-- Patch: Admin Event Notifications — fill coverage gaps, drop old triggers
--
-- NOTE: ALTER TYPE ... ADD VALUE commits the new enum labels but they are
-- not usable for DML/casts until AFTER the transaction commits.  All code
-- that references the new values lives inside plpgsql function bodies, which
-- are stored as text and only parsed at execution time — so they are safe
-- to create here.  The seed INSERT for existing admins is handled by calling
-- create_default_admin_event_preferences() from the app (or manually after
-- this migration commits — see bottom of file).
-- ============================================================================

-- ============================================================================
-- 1. Extend admin_event_type enum
-- ============================================================================
ALTER TYPE public.admin_event_type ADD VALUE IF NOT EXISTS 'dispute_escalated';
ALTER TYPE public.admin_event_type ADD VALUE IF NOT EXISTS 'dispute_resolved';
ALTER TYPE public.admin_event_type ADD VALUE IF NOT EXISTS 'driver_document_uploaded';
ALTER TYPE public.admin_event_type ADD VALUE IF NOT EXISTS 'driver_suspended';

-- ============================================================================
-- 2. Trigger: dispute escalated / resolved (on disputes UPDATE)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.trg_admin_event_dispute_update_fn()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_name text;
BEGIN
    -- Only fire when status actually changes
    IF OLD.status IS NOT DISTINCT FROM NEW.status THEN
        RETURN NEW;
    END IF;

    SELECT COALESCE(first_name || ' ' || last_name, phone_number, 'Unknown')
    INTO v_name
    FROM public.users WHERE id = NEW.raised_by;

    IF NEW.status = 'escalated' THEN
        PERFORM notify_admins_event(
            'dispute_escalated',
            'Dispute escalated: ' || NEW.title || ' (by ' || v_name || ')',
            NEW.id,
            jsonb_build_object(
                'raised_by', NEW.raised_by,
                'raised_against', NEW.raised_against,
                'priority', NEW.priority::text,
                'freight_post_id', NEW.freight_post_id
            )
        );
    ELSIF NEW.status = 'resolved' THEN
        PERFORM notify_admins_event(
            'dispute_resolved',
            'Dispute resolved: ' || NEW.title,
            NEW.id,
            jsonb_build_object(
                'raised_by', NEW.raised_by,
                'raised_against', NEW.raised_against,
                'resolved_by', NEW.resolved_by,
                'refund_amount', NEW.refund_amount,
                'freight_post_id', NEW.freight_post_id
            )
        );
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_admin_event_dispute_update
    AFTER UPDATE ON public.disputes
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_admin_event_dispute_update_fn();

-- ============================================================================
-- 3. Trigger: driver document uploaded (on driver_docs INSERT)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.trg_admin_event_doc_uploaded_fn()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_driver_name text;
BEGIN
    SELECT COALESCE(first_name || ' ' || last_name, phone_number, 'Unknown')
    INTO v_driver_name
    FROM public.users WHERE id = NEW.driver_id;

    PERFORM notify_admins_event(
        'driver_document_uploaded',
        'Document uploaded by ' || v_driver_name || ': ' || NEW.doc_type,
        NEW.id,
        jsonb_build_object(
            'driver_id', NEW.driver_id,
            'doc_type', NEW.doc_type
        )
    );

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_admin_event_doc_uploaded
    AFTER INSERT ON public.driver_docs
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_admin_event_doc_uploaded_fn();

-- ============================================================================
-- 4. Trigger: driver suspended (on users UPDATE when is_suspended → true)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.trg_admin_event_driver_suspended_fn()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_name text;
BEGIN
    IF OLD.is_suspended IS DISTINCT FROM NEW.is_suspended
       AND NEW.is_suspended = true THEN
        v_name := COALESCE(NEW.first_name || ' ' || NEW.last_name, NEW.phone_number, 'Unknown');

        PERFORM notify_admins_event(
            'driver_suspended',
            'Driver suspended: ' || v_name,
            NEW.id,
            jsonb_build_object(
                'suspended_reason', NEW.suspended_reason,
                'suspended_by', NEW.suspended_by
            )
        );
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_admin_event_driver_suspended
    AFTER UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_admin_event_driver_suspended_fn();

-- ============================================================================
-- 5. Drop old overlapping triggers (they write to the 'notifications' table)
-- ============================================================================
DROP TRIGGER IF EXISTS trg_notify_dispute_filed ON public.disputes;
DROP TRIGGER IF EXISTS trg_notify_dispute_updated ON public.disputes;
DROP TRIGGER IF EXISTS trg_notify_document_uploaded ON public.driver_docs;
DROP TRIGGER IF EXISTS trg_notify_driver_registered ON public.users;
DROP TRIGGER IF EXISTS trg_notify_driver_status_changed ON public.users;

-- ============================================================================
-- 6. Update create_default_admin_event_preferences() to include new types
--    (plpgsql body is stored as text — safe to reference new enum values here)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.create_default_admin_event_preferences(p_admin_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.admin_event_preferences (admin_id, event_type, fcm_enabled, sms_enabled)
    VALUES
        (p_admin_id, 'new_user', true, false),
        (p_admin_id, 'new_shipment', true, false),
        (p_admin_id, 'payment_completed', true, false),
        (p_admin_id, 'driver_registered', true, false),
        (p_admin_id, 'dispute_lodged', true, false),
        (p_admin_id, 'driver_payout', true, false),
        (p_admin_id, 'dispute_escalated', true, false),
        (p_admin_id, 'dispute_resolved', true, false),
        (p_admin_id, 'driver_document_uploaded', true, false),
        (p_admin_id, 'driver_suspended', true, false)
    ON CONFLICT (admin_id, event_type) DO NOTHING;
END;
$$;

-- ============================================================================
-- 7. Seed preferences for existing admins
--
-- The new enum values are NOT usable for DML until this transaction commits.
-- The Flutter app calls create_default_admin_event_preferences() on
-- preferences screen load, so existing admins will be seeded automatically.
-- notify_admins_event() also defaults to fcm=true when no preference row
-- exists, so notifications work immediately.
--
-- To seed all existing admins manually after this migration has been applied,
-- run the following in a NEW query (separate transaction):
--
--   SELECT create_default_admin_event_preferences(id)
--   FROM public.users WHERE role = 'Admin';
-- ============================================================================
