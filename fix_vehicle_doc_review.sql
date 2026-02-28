-- Vehicle Document Review: Per-document status tracking
-- Adds 12 columns to vehicles table (4 per document type)
-- This is NOT required for vehicle-level approval — purely optional per-document status tracking.

-- Registration document
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS registration_doc_status public.verification_status DEFAULT 'pending';
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS registration_doc_verified_by uuid REFERENCES public.users(id);
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS registration_doc_verified_at timestamptz;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS registration_doc_rejection_reason text;

-- Insurance document
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS insurance_doc_status public.verification_status DEFAULT 'pending';
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS insurance_doc_verified_by uuid REFERENCES public.users(id);
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS insurance_doc_verified_at timestamptz;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS insurance_doc_rejection_reason text;

-- Roadworthy document
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS roadworthy_doc_status public.verification_status DEFAULT 'pending';
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS roadworthy_doc_verified_by uuid REFERENCES public.users(id);
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS roadworthy_doc_verified_at timestamptz;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS roadworthy_doc_rejection_reason text;

-- Trigger: reset per-document status to 'pending' when the driver re-uploads.
-- Fires when the doc status is 'documents_requested' or 'rejected', the URL is
-- non-null, and _verified_by is NOT changing (i.e. this is a driver action, not
-- an admin review action which always sets _verified_by).
DROP TRIGGER IF EXISTS trg_reset_vehicle_doc_status ON public.vehicles;
DROP FUNCTION IF EXISTS public.reset_vehicle_doc_status_on_reupload();

CREATE OR REPLACE FUNCTION public.reset_vehicle_doc_status_on_reupload()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Registration document
  IF NEW.registration_document_url IS NOT NULL
     AND OLD.registration_doc_status IN ('documents_requested', 'rejected')
     AND NEW.registration_doc_verified_by IS NOT DISTINCT FROM OLD.registration_doc_verified_by
  THEN
    NEW.registration_doc_status := 'pending';
    NEW.registration_doc_verified_by := NULL;
    NEW.registration_doc_verified_at := NULL;
    NEW.registration_doc_rejection_reason := NULL;
  END IF;

  -- Insurance document
  IF NEW.insurance_document_url IS NOT NULL
     AND OLD.insurance_doc_status IN ('documents_requested', 'rejected')
     AND NEW.insurance_doc_verified_by IS NOT DISTINCT FROM OLD.insurance_doc_verified_by
  THEN
    NEW.insurance_doc_status := 'pending';
    NEW.insurance_doc_verified_by := NULL;
    NEW.insurance_doc_verified_at := NULL;
    NEW.insurance_doc_rejection_reason := NULL;
  END IF;

  -- Roadworthy document
  IF NEW.roadworthy_certificate_url IS NOT NULL
     AND OLD.roadworthy_doc_status IN ('documents_requested', 'rejected')
     AND NEW.roadworthy_doc_verified_by IS NOT DISTINCT FROM OLD.roadworthy_doc_verified_by
  THEN
    NEW.roadworthy_doc_status := 'pending';
    NEW.roadworthy_doc_verified_by := NULL;
    NEW.roadworthy_doc_verified_at := NULL;
    NEW.roadworthy_doc_rejection_reason := NULL;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_reset_vehicle_doc_status
  BEFORE UPDATE ON public.vehicles
  FOR EACH ROW
  EXECUTE FUNCTION public.reset_vehicle_doc_status_on_reupload();

-- Add notification type enum values (safe: only adds if not exists)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'vehicle_document_approved' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'notification_type')) THEN
    ALTER TYPE public.notification_type ADD VALUE 'vehicle_document_approved';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'vehicle_document_rejected' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'notification_type')) THEN
    ALTER TYPE public.notification_type ADD VALUE 'vehicle_document_rejected';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'vehicle_document_reupload_requested' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'notification_type')) THEN
    ALTER TYPE public.notification_type ADD VALUE 'vehicle_document_reupload_requested';
  END IF;
END
$$;
