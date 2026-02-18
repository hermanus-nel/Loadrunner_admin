-- Migration: Create RPC function for updating last_login_at
--
-- This project uses custom auth via an Edge Function (auth-handler),
-- NOT Supabase's built-in auth. auth.sessions is empty, so triggers
-- on that table won't fire.
--
-- Instead, we create an RPC function that the Edge Function calls
-- during 'create-session' to stamp the login time.

-- 1. Drop dead triggers from any previous migration attempt
DROP TRIGGER IF EXISTS on_auth_session_created ON auth.sessions;
DROP TRIGGER IF EXISTS on_auth_session_refreshed ON auth.sessions;
DROP FUNCTION IF EXISTS public.handle_auth_session_created();

-- 2. Create RPC function the Edge Function will call
CREATE OR REPLACE FUNCTION public.stamp_user_login(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.users
    SET last_login_at = NOW()
    WHERE id = p_user_id;
END;
$$;

-- 3. Backfill: for users with NULL last_login_at, approximate from
-- their most recent activity (freight_posts for shippers, bids via
-- vehicles for drivers, or profile updated_at as a fallback).
UPDATE public.users u
SET last_login_at = GREATEST(
    COALESCE(fp.latest_post, u.created_at),
    COALESCE(b.latest_bid, u.created_at),
    u.updated_at,
    u.created_at
)
FROM public.users target
LEFT JOIN LATERAL (
    SELECT MAX(created_at) AS latest_post
    FROM public.freight_posts
    WHERE shipper_id = target.id
) fp ON true
LEFT JOIN LATERAL (
    SELECT MAX(bi.created_at) AS latest_bid
    FROM public.bids bi
    JOIN public.vehicles v ON v.id = bi.vehicle_id
    WHERE v.driver_id = target.id
) b ON true
WHERE u.id = target.id
  AND u.last_login_at IS NULL;
