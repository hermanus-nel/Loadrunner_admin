-- =============================================================================
-- FIX: Missing RLS policies and enum values for admin actions
-- =============================================================================
-- Root causes:
--   1) Admins cannot UPDATE driver_docs (no RLS policy)
--   2) Admins cannot INSERT into notifications (no RLS policy)
--   3) Admins cannot INSERT into driver_approval_history (no RLS policy)
--   4) notification_type enum missing document review + auto-verify types
--   5) Admins cannot UPDATE vehicles (no RLS policy) — vehicle approval silent fail
--   6) Admins cannot INSERT into admin_audit_logs (no RLS policy)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Add missing notification_type enum values
-- ---------------------------------------------------------------------------
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'document_approved';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'document_rejected';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'document_reupload_requested';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'account_verified';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'driver_approved';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'driver_auto_verified';

-- ---------------------------------------------------------------------------
-- 2. Allow admins to UPDATE driver_docs (approve/reject/request reupload)
-- ---------------------------------------------------------------------------
CREATE POLICY "Admins can review documents"
  ON public.driver_docs
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
        AND users.role = 'Admin'::public.user_role
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
        AND users.role = 'Admin'::public.user_role
    )
  );

-- Also allow admins to SELECT all driver_docs (for queue view)
CREATE POLICY "Admins can view all documents"
  ON public.driver_docs
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
        AND users.role = 'Admin'::public.user_role
    )
  );

-- ---------------------------------------------------------------------------
-- 3. Allow admins to INSERT notifications (to notify drivers)
-- ---------------------------------------------------------------------------
CREATE POLICY "Admins can send notifications"
  ON public.notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
        AND users.role = 'Admin'::public.user_role
    )
  );

-- ---------------------------------------------------------------------------
-- 4. Allow admins to INSERT into driver_approval_history (audit trail)
-- ---------------------------------------------------------------------------
CREATE POLICY "Admins can log approval actions"
  ON public.driver_approval_history
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
        AND users.role = 'Admin'::public.user_role
    )
  );

-- ---------------------------------------------------------------------------
-- 5. Allow admins to UPDATE vehicles (approve/reject/suspend/reinstate)
-- ---------------------------------------------------------------------------
CREATE POLICY "Admins can manage vehicles"
  ON public.vehicles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
        AND users.role = 'Admin'::public.user_role
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
        AND users.role = 'Admin'::public.user_role
    )
  );

-- ---------------------------------------------------------------------------
-- 6. Allow admins to INSERT into admin_audit_logs (action logging)
-- ---------------------------------------------------------------------------
CREATE POLICY "Admins can insert audit logs"
  ON public.admin_audit_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
        AND users.role = 'Admin'::public.user_role
    )
  );
