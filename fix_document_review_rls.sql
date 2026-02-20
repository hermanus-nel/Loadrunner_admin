-- =============================================================================
-- FIX: Document Review Actions (Reject, Re-upload, Approve) not working
-- =============================================================================
-- Root cause: Missing RLS policies for admin users and missing notification_type
-- enum values. All 3 actions fail silently because:
--   1) Admins cannot UPDATE driver_docs (no RLS policy)
--   2) Admins cannot INSERT into notifications (no RLS policy)
--   3) Admins cannot INSERT into driver_approval_history (no RLS policy)
--   4) notification_type enum is missing document review types
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Add missing notification_type enum values
-- ---------------------------------------------------------------------------
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'document_approved';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'document_rejected';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'document_reupload_requested';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'account_verified';

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
