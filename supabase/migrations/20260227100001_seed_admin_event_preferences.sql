-- ============================================================================
-- Seed new admin event preferences for existing admins.
--
-- This MUST run in a separate transaction after 20260227100000 has committed,
-- because the new enum values (dispute_escalated, dispute_resolved,
-- driver_document_uploaded, driver_suspended) are only usable after commit.
--
-- If this migration fails with "invalid input value for enum", it means the
-- previous migration has not been committed yet.  Apply that migration first,
-- then re-run this one.
-- ============================================================================
SELECT create_default_admin_event_preferences(id)
FROM public.users
WHERE role = 'Admin';
