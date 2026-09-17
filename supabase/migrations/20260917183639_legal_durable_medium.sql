-- Layer 1: durable-medium legal schema (tables, immutability, indexes).
-- RLS is enabled with no policies (deny-by-default). Policies, HMAC salt,
-- and RPCs are Layer 2. PDF/email dispatch is Layer 3.

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
REVOKE ALL ON SCHEMA private FROM anon, authenticated;
GRANT USAGE ON SCHEMA private TO postgres, service_role;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.legal_content_sha256(p_content text)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path TO 'extensions', 'pg_catalog'
AS $$
  SELECT encode(extensions.digest(convert_to(p_content, 'UTF8'), 'sha256'), 'hex');
$$;

REVOKE ALL ON FUNCTION private.legal_content_sha256(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.legal_content_sha256(text) TO postgres, service_role;

CREATE OR REPLACE FUNCTION private.assert_sha256_hex(p_value text, p_field text)
RETURNS void
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'pg_catalog'
AS $$
BEGIN
  IF p_value IS NULL OR p_value !~ '^[0-9a-f]{64}$' THEN
    RAISE EXCEPTION '% must be a lowercase 64-char SHA-256 hex digest', p_field
      USING ERRCODE = 'check_violation';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION private.assert_sha256_hex(text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.assert_sha256_hex(text, text) TO postgres, service_role;

-- ---------------------------------------------------------------------------
-- legal_documents: versioning columns + freeze published content
-- ---------------------------------------------------------------------------

ALTER TABLE public.legal_documents
  ADD COLUMN IF NOT EXISTS content_hash text,
  ADD COLUMN IF NOT EXISTS active_from timestamptz,
  ADD COLUMN IF NOT EXISTS active_until timestamptz;

UPDATE public.legal_documents
SET is_active = false
WHERE is_active IS NULL;

UPDATE public.legal_documents
SET is_required = true
WHERE is_required IS NULL;

ALTER TABLE public.legal_documents
  ALTER COLUMN is_active SET DEFAULT false,
  ALTER COLUMN is_active SET NOT NULL,
  ALTER COLUMN is_required SET DEFAULT true,
  ALTER COLUMN is_required SET NOT NULL;

-- Keep a single current row per document_type before the unique index.
UPDATE public.legal_documents d
SET is_active = false
WHERE d.is_active = true
  AND d.id NOT IN (
    SELECT DISTINCT ON (document_type) id
    FROM public.legal_documents
    WHERE is_active = true
    ORDER BY document_type, published_at DESC NULLS LAST, id DESC
  );

UPDATE public.legal_documents
SET content_hash = private.legal_content_sha256(content)
WHERE content_hash IS NULL OR content_hash = '';

UPDATE public.legal_documents
SET active_from = COALESCE(published_at, clock_timestamp())
WHERE active_from IS NULL;

WITH ordered AS (
  SELECT
    id,
    is_active,
    lead(active_from) OVER (
      PARTITION BY document_type
      ORDER BY active_from, id
    ) AS next_from
  FROM public.legal_documents
)
UPDATE public.legal_documents d
SET active_until = CASE
  WHEN d.is_active THEN NULL
  ELSE o.next_from
END
FROM ordered o
WHERE d.id = o.id
  AND d.active_until IS NULL;

ALTER TABLE public.legal_documents
  ALTER COLUMN content_hash SET NOT NULL,
  ALTER COLUMN active_from SET NOT NULL;

ALTER TABLE public.legal_documents
  DROP CONSTRAINT IF EXISTS legal_documents_content_hash_hex,
  DROP CONSTRAINT IF EXISTS legal_documents_active_window_chk;

ALTER TABLE public.legal_documents
  ADD CONSTRAINT legal_documents_content_hash_hex
    CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  ADD CONSTRAINT legal_documents_active_window_chk
    CHECK (active_until IS NULL OR active_until >= active_from);

CREATE UNIQUE INDEX IF NOT EXISTS legal_documents_one_active_per_type
  ON public.legal_documents (document_type)
  WHERE is_active = true;

COMMENT ON COLUMN public.legal_documents.content_hash IS
  'SHA-256 (hex) of UTF-8 content. Frozen after insert.';
COMMENT ON COLUMN public.legal_documents.active_from IS
  'Start of this version. Frozen after insert.';
COMMENT ON COLUMN public.legal_documents.active_until IS
  'End of this version. NULL means currently in force.';

CREATE OR REPLACE FUNCTION private.tg_legal_documents_before_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions', 'pg_catalog'
AS $$
DECLARE
  v_expected text;
BEGIN
  IF NEW.content IS NULL OR btrim(NEW.content) = '' THEN
    RAISE EXCEPTION 'legal document content must not be empty'
      USING ERRCODE = 'check_violation';
  END IF;

  v_expected := private.legal_content_sha256(NEW.content);
  IF NEW.content_hash IS NULL OR NEW.content_hash = '' THEN
    NEW.content_hash := v_expected;
  ELSIF NEW.content_hash IS DISTINCT FROM v_expected THEN
    RAISE EXCEPTION 'content_hash does not match document content'
      USING ERRCODE = 'check_violation';
  END IF;

  NEW.active_from := COALESCE(NEW.active_from, NEW.published_at, clock_timestamp());
  IF NEW.is_active THEN
    NEW.active_until := NULL;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION private.tg_legal_documents_after_insert_close_previous()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  IF NEW.is_active THEN
    UPDATE public.legal_documents
    SET is_active = false
    WHERE document_type = NEW.document_type
      AND is_active = true
      AND id IS DISTINCT FROM NEW.id;
  END IF;
  RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION private.tg_legal_documents_before_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  IF NEW.id IS DISTINCT FROM OLD.id
     OR NEW.document_type IS DISTINCT FROM OLD.document_type
     OR NEW.version IS DISTINCT FROM OLD.version
     OR NEW.content IS DISTINCT FROM OLD.content
     OR NEW.content_hash IS DISTINCT FROM OLD.content_hash
     OR NEW.active_from IS DISTINCT FROM OLD.active_from
     OR NEW.created_by IS DISTINCT FROM OLD.created_by
     OR NEW.is_required IS DISTINCT FROM OLD.is_required
  THEN
    RAISE EXCEPTION 'Published legal documents are immutable (id=%)', OLD.id
      USING ERRCODE = 'integrity_constraint_violation';
  END IF;

  IF OLD.is_active AND NOT NEW.is_active AND NEW.active_until IS NULL THEN
    NEW.active_until := clock_timestamp();
  END IF;

  IF (NOT OLD.is_active) AND NEW.is_active THEN
    NEW.active_until := NULL;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION private.tg_legal_documents_forbid_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $$
BEGIN
  RAISE EXCEPTION 'legal_documents rows cannot be deleted (id=%)', OLD.id
    USING ERRCODE = 'integrity_constraint_violation';
END;
$$;

DROP TRIGGER IF EXISTS trg_legal_documents_before_insert ON public.legal_documents;
CREATE TRIGGER trg_legal_documents_before_insert
  BEFORE INSERT ON public.legal_documents
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_legal_documents_before_insert();

DROP TRIGGER IF EXISTS trg_legal_documents_after_insert_close_previous ON public.legal_documents;
CREATE TRIGGER trg_legal_documents_after_insert_close_previous
  AFTER INSERT ON public.legal_documents
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_legal_documents_after_insert_close_previous();

DROP TRIGGER IF EXISTS trg_legal_documents_before_update ON public.legal_documents;
CREATE TRIGGER trg_legal_documents_before_update
  BEFORE UPDATE ON public.legal_documents
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_legal_documents_before_update();

DROP TRIGGER IF EXISTS trg_legal_documents_forbid_delete ON public.legal_documents;
CREATE TRIGGER trg_legal_documents_forbid_delete
  BEFORE DELETE ON public.legal_documents
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_legal_documents_forbid_delete();

-- ---------------------------------------------------------------------------
-- profiles: privacy_version cache only (not legal proof)
-- ---------------------------------------------------------------------------

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS privacy_version text;

COMMENT ON COLUMN public.profiles.privacy_version IS
  'Denormalized cache of last accepted privacy policy version. Source of truth is user_consents.';
COMMENT ON COLUMN public.profiles.accepted_terms_at IS
  'Denormalized cache of last terms acceptance time. Source of truth is user_consents.';
COMMENT ON COLUMN public.profiles.terms_version IS
  'Denormalized cache of last accepted terms version. Source of truth is user_consents.';

-- ---------------------------------------------------------------------------
-- user_consent_batches: one click / one PDF
-- ---------------------------------------------------------------------------

CREATE TABLE public.user_consent_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE RESTRICT,
  accepted_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  source text NOT NULL,
  email text NOT NULL,
  ip_address text,
  user_agent text,
  pdf_sha256 text,
  pdf_storage_path text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_consent_batches_source_chk
    CHECK (source IN ('signup_email', 'signup_oauth', 'reacceptance')),
  CONSTRAINT user_consent_batches_email_chk
    CHECK (length(btrim(email)) > 2 AND length(email) <= 320),
  CONSTRAINT user_consent_batches_ip_chk
    CHECK (ip_address IS NULL OR length(ip_address) BETWEEN 1 AND 64),
  CONSTRAINT user_consent_batches_ua_chk
    CHECK (user_agent IS NULL OR length(user_agent) BETWEEN 1 AND 1024),
  CONSTRAINT user_consent_batches_pdf_sha_chk
    CHECK (pdf_sha256 IS NULL OR pdf_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT user_consent_batches_pdf_pair_chk
    CHECK (
      (pdf_sha256 IS NULL AND pdf_storage_path IS NULL)
      OR (pdf_sha256 IS NOT NULL AND pdf_storage_path IS NOT NULL)
    )
);

CREATE INDEX user_consent_batches_user_accepted_idx
  ON public.user_consent_batches (user_id, accepted_at DESC);

COMMENT ON TABLE public.user_consent_batches IS
  'One acceptance click. Groups user_consents rows and the durable-medium PDF.';

CREATE OR REPLACE FUNCTION private.tg_user_consent_batches_before_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $$
BEGIN
  IF NEW.id IS DISTINCT FROM OLD.id
     OR NEW.user_id IS DISTINCT FROM OLD.user_id
     OR NEW.accepted_at IS DISTINCT FROM OLD.accepted_at
     OR NEW.source IS DISTINCT FROM OLD.source
     OR NEW.email IS DISTINCT FROM OLD.email
     OR NEW.ip_address IS DISTINCT FROM OLD.ip_address
     OR NEW.user_agent IS DISTINCT FROM OLD.user_agent
     OR NEW.created_at IS DISTINCT FROM OLD.created_at
  THEN
    RAISE EXCEPTION 'user_consent_batches identity columns are immutable (id=%)', OLD.id
      USING ERRCODE = 'integrity_constraint_violation';
  END IF;

  IF OLD.pdf_sha256 IS NOT NULL AND NEW.pdf_sha256 IS DISTINCT FROM OLD.pdf_sha256 THEN
    RAISE EXCEPTION 'pdf_sha256 can only be set once (id=%)', OLD.id
      USING ERRCODE = 'integrity_constraint_violation';
  END IF;

  IF OLD.pdf_storage_path IS NOT NULL AND NEW.pdf_storage_path IS DISTINCT FROM OLD.pdf_storage_path THEN
    RAISE EXCEPTION 'pdf_storage_path can only be set once (id=%)', OLD.id
      USING ERRCODE = 'integrity_constraint_violation';
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION private.tg_user_consent_batches_forbid_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $$
BEGIN
  RAISE EXCEPTION 'user_consent_batches rows cannot be deleted (id=%)', OLD.id
    USING ERRCODE = 'integrity_constraint_violation';
END;
$$;

DROP TRIGGER IF EXISTS trg_user_consent_batches_before_update ON public.user_consent_batches;
CREATE TRIGGER trg_user_consent_batches_before_update
  BEFORE UPDATE ON public.user_consent_batches
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_user_consent_batches_before_update();

DROP TRIGGER IF EXISTS trg_user_consent_batches_forbid_delete ON public.user_consent_batches;
CREATE TRIGGER trg_user_consent_batches_forbid_delete
  BEFORE DELETE ON public.user_consent_batches
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_user_consent_batches_forbid_delete();

-- ---------------------------------------------------------------------------
-- user_consents: one row per accepted document version
-- ---------------------------------------------------------------------------

CREATE TABLE public.user_consents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id uuid NOT NULL REFERENCES public.user_consent_batches (id) ON DELETE RESTRICT,
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE RESTRICT,
  document_id uuid NOT NULL REFERENCES public.legal_documents (id) ON DELETE RESTRICT,
  document_type text NOT NULL,
  document_version text NOT NULL,
  accepted_at timestamptz NOT NULL,
  ip_address text,
  user_agent text,
  acceptance_hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_consents_batch_document_key UNIQUE (batch_id, document_id),
  CONSTRAINT user_consents_document_type_chk
    CHECK (document_type IN ('terms', 'privacy', 'marketing')),
  CONSTRAINT user_consents_version_chk
    CHECK (length(btrim(document_version)) > 0),
  CONSTRAINT user_consents_hash_chk
    CHECK (acceptance_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT user_consents_ip_chk
    CHECK (ip_address IS NULL OR length(ip_address) BETWEEN 1 AND 64),
  CONSTRAINT user_consents_ua_chk
    CHECK (user_agent IS NULL OR length(user_agent) BETWEEN 1 AND 1024)
);

CREATE INDEX user_consents_user_type_accepted_idx
  ON public.user_consents (user_id, document_type, accepted_at DESC);

CREATE INDEX user_consents_user_document_idx
  ON public.user_consents (user_id, document_id);

COMMENT ON TABLE public.user_consents IS
  'Append-only consent log. Each row is a specific legal_documents version accepted by a user.';
COMMENT ON COLUMN public.user_consents.acceptance_hash IS
  'HMAC-SHA256 hex. Computed in Layer 3 from user_id, accepted_at, document_id, version, pdf_sha256, server salt.';
COMMENT ON COLUMN public.user_consents.document_id IS
  'FK to the exact published version. Never retarget after insert.';

CREATE OR REPLACE FUNCTION private.tg_user_consents_before_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_batch public.user_consent_batches%ROWTYPE;
  v_doc public.legal_documents%ROWTYPE;
BEGIN
  PERFORM private.assert_sha256_hex(NEW.acceptance_hash, 'acceptance_hash');

  SELECT * INTO v_batch
  FROM public.user_consent_batches
  WHERE id = NEW.batch_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'unknown consent batch %', NEW.batch_id
      USING ERRCODE = 'foreign_key_violation';
  END IF;

  SELECT * INTO v_doc
  FROM public.legal_documents
  WHERE id = NEW.document_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'unknown legal document %', NEW.document_id
      USING ERRCODE = 'foreign_key_violation';
  END IF;

  NEW.user_id := v_batch.user_id;
  NEW.accepted_at := v_batch.accepted_at;
  NEW.ip_address := COALESCE(NEW.ip_address, v_batch.ip_address);
  NEW.user_agent := COALESCE(NEW.user_agent, v_batch.user_agent);
  NEW.document_type := v_doc.document_type;
  NEW.document_version := v_doc.version;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION private.tg_user_consents_forbid_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $$
BEGIN
  RAISE EXCEPTION 'user_consents rows are append-only (id=%)', OLD.id
    USING ERRCODE = 'integrity_constraint_violation';
END;
$$;

DROP TRIGGER IF EXISTS trg_user_consents_before_insert ON public.user_consents;
CREATE TRIGGER trg_user_consents_before_insert
  BEFORE INSERT ON public.user_consents
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_user_consents_before_insert();

DROP TRIGGER IF EXISTS trg_user_consents_forbid_update ON public.user_consents;
CREATE TRIGGER trg_user_consents_forbid_update
  BEFORE UPDATE ON public.user_consents
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_user_consents_forbid_mutation();

DROP TRIGGER IF EXISTS trg_user_consents_forbid_delete ON public.user_consents;
CREATE TRIGGER trg_user_consents_forbid_delete
  BEFORE DELETE ON public.user_consents
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_user_consents_forbid_mutation();

-- ---------------------------------------------------------------------------
-- legal_welcome_dispatches: email queue (mutable status only)
-- ---------------------------------------------------------------------------

CREATE TABLE public.legal_welcome_dispatches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id uuid NOT NULL UNIQUE REFERENCES public.user_consent_batches (id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'pending',
  attempt_count integer NOT NULL DEFAULT 0,
  last_error text,
  provider text NOT NULL DEFAULT 'ovh_smtp',
  provider_message_id text,
  sent_at timestamptz,
  next_attempt_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT legal_welcome_dispatches_status_chk
    CHECK (status IN ('pending', 'processing', 'sent', 'failed')),
  CONSTRAINT legal_welcome_dispatches_attempts_chk
    CHECK (attempt_count >= 0),
  CONSTRAINT legal_welcome_dispatches_sent_chk
    CHECK (
      (status = 'sent' AND sent_at IS NOT NULL)
      OR (status <> 'sent')
    )
);

CREATE INDEX legal_welcome_dispatches_pending_idx
  ON public.legal_welcome_dispatches (next_attempt_at)
  WHERE status IN ('pending', 'failed');

COMMENT ON TABLE public.legal_welcome_dispatches IS
  'Outbound durable-medium email queue. One row per consent batch.';

CREATE OR REPLACE FUNCTION private.tg_legal_welcome_dispatches_before_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $$
BEGIN
  IF NEW.id IS DISTINCT FROM OLD.id
     OR NEW.batch_id IS DISTINCT FROM OLD.batch_id
     OR NEW.created_at IS DISTINCT FROM OLD.created_at
     OR NEW.provider IS DISTINCT FROM OLD.provider
  THEN
    RAISE EXCEPTION 'legal_welcome_dispatches identity columns are immutable (id=%)', OLD.id
      USING ERRCODE = 'integrity_constraint_violation';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_legal_welcome_dispatches_before_update ON public.legal_welcome_dispatches;
CREATE TRIGGER trg_legal_welcome_dispatches_before_update
  BEFORE UPDATE ON public.legal_welcome_dispatches
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_legal_welcome_dispatches_before_update();

-- ---------------------------------------------------------------------------
-- Storage bucket (object policies are Layer 2)
-- ---------------------------------------------------------------------------

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'legal-acceptances',
  'legal-acceptances',
  false,
  10485760,
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO UPDATE
SET public = false,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- Grants + RLS enabled (no policies yet — deny-by-default until Layer 2)
-- ---------------------------------------------------------------------------

ALTER TABLE public.user_consent_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_welcome_dispatches ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.user_consent_batches FROM anon, authenticated, PUBLIC;
REVOKE ALL ON TABLE public.user_consents FROM anon, authenticated, PUBLIC;
REVOKE ALL ON TABLE public.legal_welcome_dispatches FROM anon, authenticated, PUBLIC;

GRANT SELECT ON TABLE public.user_consent_batches TO authenticated;
GRANT SELECT ON TABLE public.user_consents TO authenticated;
GRANT SELECT ON TABLE public.legal_welcome_dispatches TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.user_consent_batches TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.user_consents TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.legal_welcome_dispatches TO service_role;

REVOKE ALL ON FUNCTION private.tg_legal_documents_before_insert() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.tg_legal_documents_after_insert_close_previous() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.tg_legal_documents_before_update() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.tg_legal_documents_forbid_delete() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.tg_user_consent_batches_before_update() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.tg_user_consent_batches_forbid_delete() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.tg_user_consents_before_insert() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.tg_user_consents_forbid_mutation() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.tg_legal_welcome_dispatches_before_update() FROM PUBLIC, anon, authenticated;
