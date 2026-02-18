-- ============================================================================
-- FIX: Replace system user approach with nullable admin_id
-- ============================================================================
-- Problem: public.users.id has FK to auth.users.id — can't insert a fake
--          system user without an auth entry.
-- Solution: Make admin_id NULLABLE in driver_approval_history. 
--           NULL admin_id = auto-verification action.
-- ============================================================================

-- Step 1: Make admin_id nullable (it was NOT NULL)
ALTER TABLE public.driver_approval_history 
  ALTER COLUMN admin_id DROP NOT NULL;

-- Step 2: Verify the change
-- SELECT column_name, is_nullable FROM information_schema.columns 
-- WHERE table_name = 'driver_approval_history' AND column_name = 'admin_id';

-- ============================================================================
-- Then replace Section 7 (auto_verify_driver function) with this version
-- that uses NULL instead of the system UUID:
-- ============================================================================

CREATE OR REPLACE FUNCTION public.auto_verify_driver()
RETURNS TRIGGER AS $$
DECLARE
  v_driver_id UUID;
  v_current_status public.verification_status;
  v_is_suspended BOOLEAN;
  v_has_id BOOLEAN;
  v_has_license BOOLEAN;
  v_has_vehicle BOOLEAN;
  v_has_banking BOOLEAN;
  v_vehicle_count INTEGER;
  v_all_pass BOOLEAN;
  v_reason TEXT;
  v_driver_name TEXT;
BEGIN
  v_driver_id := NEW.driver_id;

  SELECT driver_verification_status, is_suspended,
         COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')
  INTO v_current_status, v_is_suspended, v_driver_name
  FROM public.users
  WHERE id = v_driver_id;

  -- Skip if already approved or suspended
  IF v_current_status = 'approved' OR v_current_status = 'suspended' OR v_is_suspended THEN
    RETURN NEW;
  END IF;

  -- CHECK 1: Has approved ID Document
  SELECT EXISTS (
    SELECT 1 FROM public.driver_docs
    WHERE driver_id = v_driver_id
      AND doc_type = 'id_document'
      AND verification_status = 'approved'
  ) INTO v_has_id;

  -- CHECK 2: Has approved Driver's License
  SELECT EXISTS (
    SELECT 1 FROM public.driver_docs
    WHERE driver_id = v_driver_id
      AND doc_type = 'license_front'
      AND verification_status = 'approved'
  ) INTO v_has_license;

  -- CHECK 3: Has at least one vehicle with photo
  SELECT COUNT(*) INTO v_vehicle_count
  FROM public.vehicles
  WHERE driver_id = v_driver_id
    AND photo_url IS NOT NULL
    AND photo_url != '';
  v_has_vehicle := v_vehicle_count > 0;

  -- CHECK 4: Has active primary bank account
  SELECT EXISTS (
    SELECT 1 FROM public.driver_bank_accounts
    WHERE driver_id = v_driver_id
      AND is_active = true
      AND is_primary = true
  ) INTO v_has_banking;

  v_all_pass := v_has_id AND v_has_license AND v_has_vehicle AND v_has_banking;

  IF v_all_pass THEN
    -- ═══ AUTO-APPROVE ═══
    UPDATE public.users SET
      driver_verification_status = 'approved',
      driver_verified_at = NOW(),
      driver_verified_by = NULL,  -- NULL = auto-verified (not a real admin)
      verification_notes = 'Auto-verified: all required documents approved, vehicle and banking confirmed.',
      updated_at = NOW()
    WHERE id = v_driver_id;

    -- Log with admin_id = NULL (identifies this as an auto-action)
    INSERT INTO public.driver_approval_history (
      driver_id, admin_id, previous_status, new_status, reason, notes
    ) VALUES (
      v_driver_id,
      NULL,  -- NULL = auto-verification
      v_current_status,
      'approved',
      'auto_verification',
      format('Auto-verified: id_document=approved, license_front=approved, vehicles=%s, banking=present',
             v_vehicle_count)
    );

    -- Notify the driver
    PERFORM public.send_notification_with_preferences(
      v_driver_id,
      'driver_approved'::public.notification_type,
      'Congratulations! Your driver account has been verified. You can now browse and bid on available loads. Welcome to LoadRunner! Safe travels!',
      v_driver_id
    );

    -- Notify all admins
    PERFORM public.notify_all_admins(
      'driver_auto_verified'::public.notification_type,
      format('Driver auto-verified: %s', TRIM(v_driver_name)),
      v_driver_id
    );

  ELSE
    -- ═══ NOT READY — log evaluation only ═══
    v_reason := '';
    IF NOT v_has_id THEN v_reason := v_reason || 'missing approved ID; '; END IF;
    IF NOT v_has_license THEN v_reason := v_reason || 'missing approved license; '; END IF;
    IF NOT v_has_vehicle THEN v_reason := v_reason || 'no vehicle with photo; '; END IF;
    IF NOT v_has_banking THEN v_reason := v_reason || 'no active bank account; '; END IF;
    v_reason := RTRIM(v_reason, '; ');

    INSERT INTO public.driver_approval_history (
      driver_id, admin_id, previous_status, new_status, reason, notes
    ) VALUES (
      v_driver_id,
      NULL,  -- NULL = auto-verification evaluation
      v_current_status,
      v_current_status,
      'auto_verification_evaluation',
      format('Auto-verify incomplete: %s', v_reason)
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger (same as before)
DROP TRIGGER IF EXISTS trg_auto_verify_driver ON public.driver_docs;

CREATE TRIGGER trg_auto_verify_driver
  AFTER UPDATE OF verification_status ON public.driver_docs
  FOR EACH ROW
  WHEN (NEW.verification_status = 'approved' AND OLD.verification_status != 'approved')
  EXECUTE FUNCTION public.auto_verify_driver();