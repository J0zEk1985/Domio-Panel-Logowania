-- Layer 2: RLS, Vault HMAC salt, storage read policies, security-definer RPCs.
-- Write path (PDF + consent insert) remains Layer 3 / service_role.

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
REVOKE ALL ON SCHEMA private FROM anon, authenticated;
GRANT USAGE ON SCHEMA private TO postgres, service_role;

-- ---------------------------------------------------------------------------
-- HMAC salt (generated at apply time, never committed to git)
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM vault.secrets
    WHERE name = 'legal_acceptance_salt'
  ) THEN
    PERFORM vault.create_secret(
      encode(extensions.gen_random_bytes(32), 'hex'),
      'legal_acceptance_salt',
      'HMAC-SHA256 key for user_consents.acceptance_hash. Never expose via API or Edge env.'
    );
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION private.legal_acceptance_salt()
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'vault', 'pg_catalog'
AS $$
DECLARE
  v_salt text;
BEGIN
  SELECT ds.decrypted_secret
  INTO v_salt
  FROM vault.decrypted_secrets ds
  WHERE ds.name = 'legal_acceptance_salt';

  IF v_salt IS NULL OR length(v_salt) < 32 THEN
    RAISE EXCEPTION 'LEGAL_ACCEPTANCE_SALT_MISSING'
      USING ERRCODE = 'configuration_limit_exceeded';
  END IF;

  RETURN v_salt;
END;
$$;

REVOKE ALL ON FUNCTION private.legal_acceptance_salt() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.legal_acceptance_salt() TO postgres, service_role;

CREATE OR REPLACE FUNCTION private.legal_acceptance_hmac(
  p_user_id uuid,
  p_accepted_at timestamptz,
  p_document_id uuid,
  p_document_version text,
  p_pdf_sha256 text
)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'extensions', 'pg_catalog'
AS $$
DECLARE
  v_payload text;
BEGIN
  IF p_user_id IS NULL
     OR p_accepted_at IS NULL
     OR p_document_id IS NULL
     OR p_document_version IS NULL
     OR p_pdf_sha256 IS NULL
     OR p_pdf_sha256 !~ '^[0-9a-f]{64}$'
  THEN
    RAISE EXCEPTION 'LEGAL_ACCEPTANCE_HMAC_INPUT'
      USING ERRCODE = 'check_violation';
  END IF;

  v_payload :=
    p_user_id::text || '|' ||
    to_char(p_accepted_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') || '|' ||
    p_document_id::text || '|' ||
    p_document_version || '|' ||
    p_pdf_sha256;

  RETURN encode(
    extensions.hmac(v_payload, private.legal_acceptance_salt(), 'sha256'),
    'hex'
  );
END;
$$;

REVOKE ALL ON FUNCTION private.legal_acceptance_hmac(uuid, timestamptz, uuid, text, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.legal_acceptance_hmac(uuid, timestamptz, uuid, text, text)
  TO postgres, service_role;

-- ---------------------------------------------------------------------------
-- Consent wall helper (hub/consumer accounts only)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.pending_required_legal_documents(p_user_id uuid)
RETURNS TABLE (
  id uuid,
  document_type text,
  version text,
  active_from timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'LEGAL_AUTH_REQUIRED'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Workers / simplified staff are not consumers of platform ToS in this flow.
  IF EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = p_user_id
      AND p.account_type = 'simplified'
  ) THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    d.id,
    d.document_type,
    d.version,
    d.active_from
  FROM public.legal_documents d
  WHERE d.is_active = true
    AND d.is_required = true
    AND NOT EXISTS (
      SELECT 1
      FROM public.user_consents c
      WHERE c.user_id = p_user_id
        AND c.document_id = d.id
    )
  ORDER BY
    CASE d.document_type
      WHEN 'terms' THEN 1
      WHEN 'privacy' THEN 2
      ELSE 3
    END,
    d.active_from;
END;
$$;

REVOKE ALL ON FUNCTION private.pending_required_legal_documents(uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.pending_required_legal_documents(uuid)
  TO postgres, service_role;

CREATE OR REPLACE FUNCTION public.pending_required_legal_documents()
RETURNS TABLE (
  id uuid,
  document_type text,
  version text,
  active_from timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'private', 'public', 'pg_catalog'
AS $$
DECLARE
  v_uid uuid := (SELECT auth.uid());
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Wymagane logowanie'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  RETURN QUERY
  SELECT p.id, p.document_type, p.version, p.active_from
  FROM private.pending_required_legal_documents(v_uid) p;
END;
$$;

REVOKE ALL ON FUNCTION public.pending_required_legal_documents() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pending_required_legal_documents() TO authenticated;
GRANT EXECUTE ON FUNCTION public.pending_required_legal_documents() TO service_role;

-- ---------------------------------------------------------------------------
-- Forensic HMAC verification (admin only; never returns the salt)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.verify_user_consent(p_consent_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_consent public.user_consents%ROWTYPE;
  v_batch public.user_consent_batches%ROWTYPE;
  v_expected text;
  v_matches boolean := false;
BEGIN
  IF p_consent_id IS NULL THEN
    RAISE EXCEPTION 'LEGAL_CONSENT_ID_REQUIRED'
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT * INTO v_consent
  FROM public.user_consents
  WHERE id = p_consent_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'ok', false,
      'reason', 'consent_not_found'
    );
  END IF;

  SELECT * INTO v_batch
  FROM public.user_consent_batches
  WHERE id = v_consent.batch_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'ok', false,
      'consent_id', v_consent.id,
      'reason', 'batch_not_found'
    );
  END IF;

  IF v_batch.pdf_sha256 IS NULL THEN
    RETURN jsonb_build_object(
      'ok', true,
      'consent_id', v_consent.id,
      'user_id', v_consent.user_id,
      'document_id', v_consent.document_id,
      'document_version', v_consent.document_version,
      'accepted_at', v_consent.accepted_at,
      'hash_matches', false,
      'pdf_sha256_present', false,
      'reason', 'pdf_sha256_missing'
    );
  END IF;

  v_expected := private.legal_acceptance_hmac(
    v_consent.user_id,
    v_consent.accepted_at,
    v_consent.document_id,
    v_consent.document_version,
    v_batch.pdf_sha256
  );
  v_matches := (v_expected = v_consent.acceptance_hash);

  RETURN jsonb_build_object(
    'ok', true,
    'consent_id', v_consent.id,
    'user_id', v_consent.user_id,
    'document_id', v_consent.document_id,
    'document_version', v_consent.document_version,
    'accepted_at', v_consent.accepted_at,
    'hash_matches', v_matches,
    'pdf_sha256_present', true,
    'reason', CASE WHEN v_matches THEN NULL ELSE 'hash_mismatch' END
  );
END;
$$;

REVOKE ALL ON FUNCTION private.verify_user_consent(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.verify_user_consent(uuid) TO postgres, service_role;

CREATE OR REPLACE FUNCTION public.verify_user_consent(p_consent_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'private', 'public', 'pg_catalog'
AS $$
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'Wymagane logowanie'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF NOT (SELECT public.is_platform_admin()) THEN
    RAISE EXCEPTION 'Brak uprawnień'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  RETURN private.verify_user_consent(p_consent_id);
END;
$$;

REVOKE ALL ON FUNCTION public.verify_user_consent(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.verify_user_consent(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_user_consent(uuid) TO service_role;

-- ---------------------------------------------------------------------------
-- Storage read helper (writes stay service_role-only)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.can_read_legal_acceptance_object(p_name text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'storage', 'pg_catalog'
AS $$
DECLARE
  v_folder text;
  v_uid uuid := (SELECT auth.uid());
BEGIN
  IF p_name IS NULL OR v_uid IS NULL THEN
    RETURN false;
  END IF;

  IF (SELECT public.is_platform_admin()) THEN
    RETURN true;
  END IF;

  v_folder := (storage.foldername(p_name))[1];
  RETURN v_folder IS NOT NULL AND v_folder = v_uid::text;
END;
$$;

REVOKE ALL ON FUNCTION private.can_read_legal_acceptance_object(text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.can_read_legal_acceptance_object(text)
  TO postgres, service_role;

CREATE OR REPLACE FUNCTION public.can_read_legal_acceptance_object(p_name text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'private', 'public', 'pg_catalog'
AS $$
  SELECT private.can_read_legal_acceptance_object(p_name);
$$;

REVOKE ALL ON FUNCTION public.can_read_legal_acceptance_object(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_read_legal_acceptance_object(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_read_legal_acceptance_object(text) TO service_role;

-- ---------------------------------------------------------------------------
-- legal_documents: drop overly broad GRANTs (RLS already limits rows)
-- ---------------------------------------------------------------------------

REVOKE ALL ON TABLE public.legal_documents FROM anon, PUBLIC;
GRANT SELECT ON TABLE public.legal_documents TO anon;
GRANT SELECT, INSERT, UPDATE ON TABLE public.legal_documents TO authenticated;
GRANT ALL ON TABLE public.legal_documents TO service_role;

-- ---------------------------------------------------------------------------
-- Table RLS (SELECT only; no write policies for authenticated)
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS user_consent_batches_select_own ON public.user_consent_batches;
CREATE POLICY user_consent_batches_select_own
  ON public.user_consent_batches
  FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS user_consent_batches_select_admin ON public.user_consent_batches;
CREATE POLICY user_consent_batches_select_admin
  ON public.user_consent_batches
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_platform_admin()));

DROP POLICY IF EXISTS user_consents_select_own ON public.user_consents;
CREATE POLICY user_consents_select_own
  ON public.user_consents
  FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS user_consents_select_admin ON public.user_consents;
CREATE POLICY user_consents_select_admin
  ON public.user_consents
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_platform_admin()));

DROP POLICY IF EXISTS legal_welcome_dispatches_select_own ON public.legal_welcome_dispatches;
CREATE POLICY legal_welcome_dispatches_select_own
  ON public.legal_welcome_dispatches
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.user_consent_batches b
      WHERE b.id = legal_welcome_dispatches.batch_id
        AND b.user_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS legal_welcome_dispatches_select_admin ON public.legal_welcome_dispatches;
CREATE POLICY legal_welcome_dispatches_select_admin
  ON public.legal_welcome_dispatches
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_platform_admin()));

-- ---------------------------------------------------------------------------
-- Storage: authenticated can read own / admin all. No client writes.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS legal_acceptances_storage_select ON storage.objects;
CREATE POLICY legal_acceptances_storage_select
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'legal-acceptances'
    AND (SELECT public.can_read_legal_acceptance_object(name))
  );
