-- ============================================================================
-- Admin Event Notifications System
--
-- Separate admin event notification system for the LoadRunner_Admin app.
-- Admin events are NOT mixed into user-facing notifications tables.
-- Delivery reuses existing send-push / send-sms edge functions.
-- ============================================================================

-- ============================================================================
-- 1. Enum: admin_event_type
-- ============================================================================
CREATE TYPE public.admin_event_type AS ENUM (
    'new_user',
    'new_shipment',
    'payment_completed',
    'driver_registered',
    'dispute_lodged',
    'driver_payout'
);

-- ============================================================================
-- 2. Table: admin_event_preferences
-- ============================================================================
CREATE TABLE public.admin_event_preferences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid NOT NULL,
    event_type public.admin_event_type NOT NULL,
    fcm_enabled boolean DEFAULT true NOT NULL,
    sms_enabled boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT admin_event_preferences_pkey PRIMARY KEY (id),
    CONSTRAINT admin_event_preferences_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT admin_event_preferences_admin_event_unique UNIQUE (admin_id, event_type)
);

COMMENT ON TABLE public.admin_event_preferences IS 'Per-admin, per-event-type delivery channel configuration';

-- ============================================================================
-- 3. Table: admin_event_notifications
-- ============================================================================
CREATE TABLE public.admin_event_notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid NOT NULL,
    event_type public.admin_event_type NOT NULL,
    message text NOT NULL,
    related_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb,
    is_read boolean DEFAULT false NOT NULL,
    archived boolean DEFAULT false NOT NULL,
    archived_at timestamp with time zone,
    delivery_method text,
    sent_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT admin_event_notifications_pkey PRIMARY KEY (id),
    CONSTRAINT admin_event_notifications_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE CASCADE
);

COMMENT ON TABLE public.admin_event_notifications IS 'Per-admin event records with individual read/archived state';

-- Enable realtime for the notifications table
ALTER TABLE public.admin_event_notifications REPLICA IDENTITY FULL;

-- Index for efficient queries
CREATE INDEX idx_admin_event_notifications_admin_id ON public.admin_event_notifications (admin_id, created_at DESC);
CREATE INDEX idx_admin_event_notifications_unread ON public.admin_event_notifications (admin_id) WHERE is_read = false AND archived = false;

-- ============================================================================
-- 4. RLS Policies
-- ============================================================================

-- admin_event_preferences
ALTER TABLE public.admin_event_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view their own event preferences"
    ON public.admin_event_preferences FOR SELECT
    USING (admin_id = auth.uid());

CREATE POLICY "Admins can update their own event preferences"
    ON public.admin_event_preferences FOR UPDATE
    USING (admin_id = auth.uid());

CREATE POLICY "Service role can insert event preferences"
    ON public.admin_event_preferences FOR INSERT
    WITH CHECK (true);

-- admin_event_notifications
ALTER TABLE public.admin_event_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view their own event notifications"
    ON public.admin_event_notifications FOR SELECT
    USING (admin_id = auth.uid());

CREATE POLICY "Admins can update their own event notifications"
    ON public.admin_event_notifications FOR UPDATE
    USING (admin_id = auth.uid());

CREATE POLICY "Service role can insert event notifications"
    ON public.admin_event_notifications FOR INSERT
    WITH CHECK (true);

-- ============================================================================
-- 5. Function: create_default_admin_event_preferences(uuid)
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
        (p_admin_id, 'driver_payout', true, false)
    ON CONFLICT (admin_id, event_type) DO NOTHING;
END;
$$;

-- ============================================================================
-- 6. Function: notify_admins_event()
-- ============================================================================
CREATE OR REPLACE FUNCTION public.notify_admins_event(
    p_event_type public.admin_event_type,
    p_message text,
    p_related_id uuid DEFAULT NULL,
    p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_admin RECORD;
    v_fcm_enabled boolean;
    v_sms_enabled boolean;
    v_delivery_method text;
    v_notification_id uuid;
    v_user_phone text;
    v_device RECORD;
    v_request_id bigint;
    v_supabase_url text;
    v_service_role_key text;
    v_can_send_http boolean := false;
BEGIN
    -- Check if Supabase settings are available
    v_supabase_url := current_setting('app.settings.supabase_url', true);
    v_service_role_key := current_setting('app.settings.service_role_key', true);

    IF v_supabase_url IS NOT NULL AND v_service_role_key IS NOT NULL THEN
        v_can_send_http := true;
    ELSE
        RAISE WARNING 'Supabase URL or service role key not set — push/SMS will be skipped, notification records will still be created';
    END IF;

    FOR v_admin IN
        SELECT id FROM public.users WHERE role = 'Admin'
    LOOP
        -- Get this admin's preferences for this event type
        SELECT fcm_enabled, sms_enabled
        INTO v_fcm_enabled, v_sms_enabled
        FROM public.admin_event_preferences
        WHERE admin_id = v_admin.id
          AND event_type = p_event_type;

        -- If no preferences found, default to fcm=true, sms=false
        IF NOT FOUND THEN
            v_fcm_enabled := true;
            v_sms_enabled := false;
        END IF;

        -- Determine delivery method
        IF v_fcm_enabled AND v_sms_enabled THEN
            v_delivery_method := 'both';
        ELSIF v_fcm_enabled THEN
            v_delivery_method := 'push';
        ELSIF v_sms_enabled THEN
            v_delivery_method := 'sms';
        ELSE
            v_delivery_method := NULL;
        END IF;

        -- Always create the notification record (even if delivery disabled)
        INSERT INTO public.admin_event_notifications (
            admin_id, event_type, message, related_id, metadata,
            delivery_method, sent_at
        ) VALUES (
            v_admin.id, p_event_type, p_message, p_related_id, p_metadata,
            v_delivery_method,
            CASE WHEN v_delivery_method IS NOT NULL THEN NOW() ELSE NULL END
        )
        RETURNING id INTO v_notification_id;

        -- Send FCM push to all registered devices if enabled
        IF v_fcm_enabled AND v_can_send_http THEN
            FOR v_device IN
                SELECT fcm_token FROM public.device_tokens WHERE user_id = v_admin.id
            LOOP
                SELECT net.http_post(
                    url := v_supabase_url || '/functions/v1/send-push',
                    headers := jsonb_build_object(
                        'Content-Type', 'application/json',
                        'Authorization', 'Bearer ' || v_service_role_key
                    ),
                    body := jsonb_build_object(
                        'fcm_token', v_device.fcm_token,
                        'title', 'LoadRunner Admin',
                        'body', p_message,
                        'notification_type', p_event_type::text,
                        'related_id', p_related_id
                    )
                ) INTO v_request_id;
            END LOOP;

            -- Also try legacy single-token field on users table
            SELECT fcm_token INTO v_user_phone FROM public.users WHERE id = v_admin.id;
            IF v_user_phone IS NOT NULL AND NOT EXISTS (
                SELECT 1 FROM public.device_tokens WHERE user_id = v_admin.id AND fcm_token = v_user_phone
            ) THEN
                SELECT net.http_post(
                    url := v_supabase_url || '/functions/v1/send-push',
                    headers := jsonb_build_object(
                        'Content-Type', 'application/json',
                        'Authorization', 'Bearer ' || v_service_role_key
                    ),
                    body := jsonb_build_object(
                        'fcm_token', v_user_phone,
                        'title', 'LoadRunner Admin',
                        'body', p_message,
                        'notification_type', p_event_type::text,
                        'related_id', p_related_id
                    )
                ) INTO v_request_id;
            END IF;
        END IF;

        -- Send SMS if enabled
        IF v_sms_enabled AND v_can_send_http THEN
            SELECT phone_number INTO v_user_phone FROM public.users WHERE id = v_admin.id;
            IF v_user_phone IS NOT NULL THEN
                SELECT net.http_post(
                    url := v_supabase_url || '/functions/v1/send-sms',
                    headers := jsonb_build_object(
                        'Content-Type', 'application/json',
                        'Authorization', 'Bearer ' || v_service_role_key
                    ),
                    body := jsonb_build_object(
                        'user_id', v_admin.id,
                        'phone_number', v_user_phone,
                        'message', p_message,
                        'notification_type', p_event_type::text
                    )
                ) INTO v_request_id;
            END IF;
        END IF;
    END LOOP;
END;
$$;

-- ============================================================================
-- 7. Update: handle_new_user_preferences()
--    Add admin event preferences seeding when role = 'Admin'
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user_preferences()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
    -- Create default notification preferences for new user
    PERFORM create_default_notification_preferences(NEW.id);

    -- If user is an Admin, also create default admin event preferences
    IF NEW.role = 'Admin' THEN
        PERFORM create_default_admin_event_preferences(NEW.id);
    END IF;

    RETURN NEW;
END;
$$;

-- ============================================================================
-- 8. Trigger functions for each admin event
-- ============================================================================

-- 8a. New user trigger (fires for ALL new users)
CREATE OR REPLACE FUNCTION public.trg_admin_event_new_user_fn()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_name text;
BEGIN
    v_name := COALESCE(NEW.first_name || ' ' || NEW.last_name, NEW.phone_number, 'Unknown');

    PERFORM notify_admins_event(
        'new_user',
        'New ' || NEW.role || ' registered: ' || v_name,
        NEW.id,
        jsonb_build_object('role', NEW.role)
    );

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_admin_event_new_user
    AFTER INSERT ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_admin_event_new_user_fn();

-- 8b. New shipment trigger (fires when freight_post created with status = 'Bidding')
CREATE OR REPLACE FUNCTION public.trg_admin_event_new_shipment_fn()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_shipper_name text;
BEGIN
    IF NEW.status = 'Bidding' THEN
        SELECT COALESCE(first_name || ' ' || last_name, phone_number, 'Unknown')
        INTO v_shipper_name
        FROM public.users WHERE id = NEW.shipper_id;

        PERFORM notify_admins_event(
            'new_shipment',
            'New shipment by ' || v_shipper_name || ': ' || COALESCE(LEFT(NEW.description, 80), 'No description'),
            NEW.id,
            jsonb_build_object('shipper_id', NEW.shipper_id, 'description', NEW.description)
        );
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_admin_event_new_shipment
    AFTER INSERT ON public.freight_posts
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_admin_event_new_shipment_fn();

-- 8c. Payment completed trigger (fires when payment status changes to 'completed')
CREATE OR REPLACE FUNCTION public.trg_admin_event_payment_fn()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_shipper_name text;
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'completed' THEN
        SELECT COALESCE(first_name || ' ' || last_name, phone_number, 'Unknown')
        INTO v_shipper_name
        FROM public.users WHERE id = NEW.shipper_id;

        PERFORM notify_admins_event(
            'payment_completed',
            'Payment completed: R' || NEW.amount || ' by ' || COALESCE(v_shipper_name, 'Unknown'),
            NEW.id,
            jsonb_build_object(
                'amount', NEW.amount,
                'shipper_id', NEW.shipper_id,
                'freight_post_id', NEW.freight_post_id
            )
        );
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_admin_event_payment
    AFTER UPDATE ON public.payments
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_admin_event_payment_fn();

-- 8d. Driver registered trigger (fires ONLY for Drivers)
CREATE OR REPLACE FUNCTION public.trg_admin_event_driver_reg_fn()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_name text;
BEGIN
    IF NEW.role = 'Driver' THEN
        v_name := COALESCE(NEW.first_name || ' ' || NEW.last_name, NEW.phone_number, 'Unknown');

        PERFORM notify_admins_event(
            'driver_registered',
            'Driver registration pending: ' || v_name,
            NEW.id,
            jsonb_build_object('phone_number', NEW.phone_number)
        );
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_admin_event_driver_reg
    AFTER INSERT ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_admin_event_driver_reg_fn();

-- 8e. Dispute lodged trigger
CREATE OR REPLACE FUNCTION public.trg_admin_event_dispute_fn()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_name text;
BEGIN
    SELECT COALESCE(first_name || ' ' || last_name, phone_number, 'Unknown')
    INTO v_name
    FROM public.users WHERE id = NEW.raised_by;

    PERFORM notify_admins_event(
        'dispute_lodged',
        'Dispute filed by ' || v_name || ': ' || NEW.title,
        NEW.id,
        jsonb_build_object(
            'raised_by', NEW.raised_by,
            'raised_against', NEW.raised_against,
            'dispute_type', NEW.dispute_type::text,
            'priority', NEW.priority::text,
            'freight_post_id', NEW.freight_post_id
        )
    );

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_admin_event_dispute
    AFTER INSERT ON public.disputes
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_admin_event_dispute_fn();

-- 8f. Driver payout trigger (fires when payout status changes to 'success')
CREATE OR REPLACE FUNCTION public.trg_admin_event_payout_fn()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_driver_name text;
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'success' THEN
        SELECT COALESCE(first_name || ' ' || last_name, phone_number, 'Unknown')
        INTO v_driver_name
        FROM public.users WHERE id = NEW.driver_id;

        PERFORM notify_admins_event(
            'driver_payout',
            'Payout: R' || NEW.net_amount || ' to ' || v_driver_name,
            NEW.id,
            jsonb_build_object(
                'driver_id', NEW.driver_id,
                'gross_amount', NEW.gross_amount,
                'net_amount', NEW.net_amount,
                'driver_commission', NEW.driver_commission,
                'freight_post_id', NEW.freight_post_id
            )
        );
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_admin_event_payout
    AFTER UPDATE ON public.driver_payouts
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_admin_event_payout_fn();

-- ============================================================================
-- 9. Backfill: seed preferences for existing Admin users
-- ============================================================================
DO $$
DECLARE
    v_admin RECORD;
BEGIN
    FOR v_admin IN
        SELECT id FROM public.users WHERE role = 'Admin'
    LOOP
        PERFORM create_default_admin_event_preferences(v_admin.id);
    END LOOP;
END;
$$;
