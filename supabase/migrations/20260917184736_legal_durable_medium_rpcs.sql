-- Layer 3: consent recording and email-queue RPCs (service_role only).
-- HMAC stays in private.legal_acceptance_hmac (Vault salt).

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
REVOKE ALL ON SCHEMA private FROM anon, authenticated;
GRANT USAGE ON SCHEMA private TO postgres, service_role;

-- ---------------------------------------------------------------------------
-- Email copy
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.legal_welcome_email_subject()
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path TO 'pg_catalog'
AS $$
  SELECT 'DOMIO — Regulamin i Polityka prywatności'::text;
$$;

CREATE OR REPLACE FUNCTION private.legal_welcome_email_html(
  p_accepted_at timestamptz,
  p_versions text
)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'pg_catalog'
AS $$
BEGIN
  RETURN
    '<p>Dzień dobry,</p>'
    || '<p>dziękujemy za konto w DOMIO. W załączniku przesyłamy plik PDF z treścią '
    || '<strong>Regulaminu</strong> i <strong>Polityki prywatności</strong>'
    || CASE WHEN p_versions IS NOT NULL AND p_versions <> '' THEN ' (' || p_versions || ')' ELSE '' END
    || ', obowiązującą w chwili akceptacji'
    || CASE
         WHEN p_accepted_at IS NULL THEN '.'
         ELSE ' (' || to_char(p_accepted_at AT TIME ZONE 'Europe/Warsaw', 'YYYY-MM-DD HH24:MI')
           || ' czas polski).'
       END
    || '</p>'
    || '<p>Zachowaj tę wiadomość. Stanowi ona trwały nośnik dokumentów — późniejsza zmiana treści na stronie nie zmienia załącznika.</p>'
    || '<p>Pozdrawiamy,<br>Zespół DOMIO</p>';
END;
$$;

CREATE OR REPLACE FUNCTION private.legal_welcome_filename(p_accepted_at timestamptz)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path TO 'pg_catalog'
AS $$
  SELECT 'DOMIO_Regulamin_i_Polityka_Prywatnosci_'
    || to_char(COALESCE(p_accepted_at, clock_timestamp()) AT TIME ZONE 'Europe/Warsaw', 'YYYY-MM-DD')
    || '.pdf';
$$;

CREATE OR REPLACE FUNCTION private.legal_welcome_payload(p_dispatch_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_dispatch public.legal_welcome_dispatches%ROWTYPE;
  v_batch public.user_consent_batches%ROWTYPE;
  v_versions text;
BEGIN
  SELECT * INTO v_dispatch
  FROM public.legal_welcome_dispatches
  WHERE id = p_dispatch_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_batch
  FROM public.user_consent_batches
  WHERE id = v_dispatch.batch_id;

  SELECT string_agg(c.document_type || ' v' || c.document_version, ', ' ORDER BY c.document_type)
  INTO v_versions
  FROM public.user_consents c
  WHERE c.batch_id = v_batch.id;

  RETURN jsonb_build_object(
    'dispatch_id', v_dispatch.id,
    'batch_id', v_batch.id,
    'status', v_dispatch.status,
    'already_sent', v_dispatch.status = 'sent',
    'to_email', v_batch.email,
    'subject', private.legal_welcome_email_subject(),
    'html', private.legal_welcome_email_html(v_batch.accepted_at, v_versions),
    'storage_path', v_batch.pdf_storage_path,
    'filename', private.legal_welcome_filename(v_batch.accepted_at)
  );
END;
$$;

REVOKE ALL ON FUNCTION private.legal_welcome_payload(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.legal_welcome_payload(uuid) TO postgres, service_role;

-- ---------------------------------------------------------------------------
-- begin_legal_consent
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.begin_legal_consent(
  p_user_id uuid,
  p_source text,
  p_email text,
  p_ip_address text,
  p_user_agent text,
  p_document_ids uuid[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_email text;
  v_ip text;
  v_ua text;
  v_ids uuid[];
  v_pending uuid[];
  v_missing uuid[];
  v_batch public.user_consent_batches%ROWTYPE;
  v_existing uuid;
  v_dispatch uuid;
  v_docs jsonb;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'LEGAL_AUTH_REQUIRED' USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF p_source IS NULL OR p_source NOT IN ('signup_email', 'signup_oauth', 'reacceptance') THEN
    RAISE EXCEPTION 'LEGAL_SOURCE_INVALID' USING ERRCODE = 'check_violation';
  END IF;

  SELECT au.email INTO v_email
  FROM auth.users au
  WHERE au.id = p_user_id;

  v_email := NULLIF(btrim(COALESCE(v_email, p_email, '')), '');
  IF v_email IS NULL OR length(v_email) < 3 THEN
    RAISE EXCEPTION 'LEGAL_EMAIL_REQUIRED' USING ERRCODE = 'check_violation';
  END IF;

  v_ip := NULLIF(left(btrim(COALESCE(p_ip_address, '')), 64), '');
  v_ua := NULLIF(left(btrim(COALESCE(p_user_agent, '')), 1024), '');

  SELECT ARRAY(
    SELECT DISTINCT x
    FROM unnest(COALESCE(p_document_ids, ARRAY[]::uuid[])) AS x
    WHERE x IS NOT NULL
  )
  INTO v_ids;

  IF v_ids IS NULL OR coalesce(array_length(v_ids, 1), 0) = 0 THEN
    RAISE EXCEPTION 'LEGAL_DOCUMENTS_REQUIRED' USING ERRCODE = 'check_violation';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM unnest(v_ids) AS i(id)
    LEFT JOIN public.legal_documents d ON d.id = i.id
    WHERE d.id IS NULL OR d.is_active IS NOT TRUE
  ) THEN
    RAISE EXCEPTION 'LEGAL_DOCUMENTS_STALE' USING ERRCODE = 'check_violation';
  END IF;

  SELECT ARRAY(
    SELECT d.id
    FROM public.legal_documents d
    WHERE d.is_active = true
      AND d.is_required = true
      AND NOT EXISTS (
        SELECT 1
        FROM public.user_consents c
        WHERE c.user_id = p_user_id
          AND c.document_id = d.id
      )
  )
  INTO v_pending;

  SELECT ARRAY(
    SELECT p
    FROM unnest(COALESCE(v_pending, ARRAY[]::uuid[])) AS p
    WHERE p <> ALL (v_ids)
  )
  INTO v_missing;

  IF coalesce(array_length(v_missing, 1), 0) > 0 THEN
    RAISE EXCEPTION 'LEGAL_REQUIRED_DOCS_MISSING' USING ERRCODE = 'check_violation';
  END IF;

  SELECT ARRAY(
    SELECT i
    FROM unnest(v_ids) AS i
    WHERE NOT EXISTS (
      SELECT 1
      FROM public.user_consents c
      WHERE c.user_id = p_user_id
        AND c.document_id = i
    )
  )
  INTO v_ids;

  IF coalesce(array_length(v_ids, 1), 0) = 0 THEN
    SELECT c.batch_id INTO v_existing
    FROM public.user_consents c
    WHERE c.user_id = p_user_id
    ORDER BY c.accepted_at DESC
    LIMIT 1;

    SELECT d.id INTO v_dispatch
    FROM public.legal_welcome_dispatches d
    WHERE d.batch_id = v_existing
    LIMIT 1;

    RETURN jsonb_build_object(
      'already_recorded', true,
      'batch_id', v_existing,
      'dispatch_id', v_dispatch,
      'document_ids', ARRAY[]::uuid[]
    );
  END IF;

  INSERT INTO public.user_consent_batches (
    user_id, source, email, ip_address, user_agent
  )
  VALUES (
    p_user_id, p_source, v_email, v_ip, v_ua
  )
  RETURNING * INTO v_batch;

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', d.id,
        'document_type', d.document_type,
        'version', d.version,
        'content', d.content,
        'content_hash', d.content_hash,
        'active_from', d.active_from
      )
      ORDER BY
        CASE d.document_type
          WHEN 'terms' THEN 1
          WHEN 'privacy' THEN 2
          ELSE 3
        END
    ),
    '[]'::jsonb
  )
  INTO v_docs
  FROM public.legal_documents d
  WHERE d.id = ANY (v_ids);

  RETURN jsonb_build_object(
    'already_recorded', false,
    'batch_id', v_batch.id,
    'accepted_at', v_batch.accepted_at,
    'email', v_batch.email,
    'ip_address', v_batch.ip_address,
    'user_agent', v_batch.user_agent,
    'source', v_batch.source,
    'document_ids', to_jsonb(v_ids),
    'documents', v_docs
  );
END;
$$;

REVOKE ALL ON FUNCTION private.begin_legal_consent(uuid, text, text, text, text, uuid[])
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.begin_legal_consent(uuid, text, text, text, text, uuid[])
  TO postgres, service_role;

-- ---------------------------------------------------------------------------
-- finalize_legal_consent
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.finalize_legal_consent(
  p_batch_id uuid,
  p_pdf_sha256 text,
  p_pdf_storage_path text,
  p_document_ids uuid[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_batch public.user_consent_batches%ROWTYPE;
  v_doc public.legal_documents%ROWTYPE;
  v_id uuid;
  v_hash text;
  v_dispatch_id uuid;
  v_terms text;
  v_privacy text;
  v_marketing text;
  v_marketing_consent boolean := false;
BEGIN
  PERFORM private.assert_sha256_hex(p_pdf_sha256, 'pdf_sha256');

  IF p_pdf_storage_path IS NULL OR btrim(p_pdf_storage_path) = '' THEN
    RAISE EXCEPTION 'LEGAL_PDF_PATH_REQUIRED' USING ERRCODE = 'check_violation';
  END IF;

  IF p_document_ids IS NULL OR coalesce(array_length(p_document_ids, 1), 0) = 0 THEN
    RAISE EXCEPTION 'LEGAL_DOCUMENTS_REQUIRED' USING ERRCODE = 'check_violation';
  END IF;

  SELECT * INTO v_batch
  FROM public.user_consent_batches
  WHERE id = p_batch_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'LEGAL_BATCH_NOT_FOUND' USING ERRCODE = 'no_data_found';
  END IF;

  SELECT d.id INTO v_dispatch_id
  FROM public.legal_welcome_dispatches d
  WHERE d.batch_id = p_batch_id;

  IF v_dispatch_id IS NOT NULL THEN
    RETURN jsonb_build_object(
      'already_recorded', true,
      'batch_id', p_batch_id,
      'dispatch_id', v_dispatch_id
    );
  END IF;

  UPDATE public.user_consent_batches
  SET
    pdf_sha256 = p_pdf_sha256,
    pdf_storage_path = btrim(p_pdf_storage_path)
  WHERE id = p_batch_id
  RETURNING * INTO v_batch;

  FOREACH v_id IN ARRAY p_document_ids
  LOOP
    SELECT * INTO v_doc
    FROM public.legal_documents
    WHERE id = v_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'LEGAL_DOCUMENTS_STALE' USING ERRCODE = 'check_violation';
    END IF;

    v_hash := private.legal_acceptance_hmac(
      v_batch.user_id,
      v_batch.accepted_at,
      v_doc.id,
      v_doc.version,
      v_batch.pdf_sha256
    );

    INSERT INTO public.user_consents (
      batch_id,
      user_id,
      document_id,
      document_type,
      document_version,
      accepted_at,
      ip_address,
      user_agent,
      acceptance_hash
    )
    VALUES (
      v_batch.id,
      v_batch.user_id,
      v_doc.id,
      v_doc.document_type,
      v_doc.version,
      v_batch.accepted_at,
      v_batch.ip_address,
      v_batch.user_agent,
      v_hash
    );

    IF v_doc.document_type = 'terms' THEN
      v_terms := v_doc.version;
    ELSIF v_doc.document_type = 'privacy' THEN
      v_privacy := v_doc.version;
    ELSIF v_doc.document_type = 'marketing' THEN
      v_marketing := v_doc.version;
      v_marketing_consent := true;
    END IF;
  END LOOP;

  INSERT INTO public.legal_welcome_dispatches (batch_id, status, next_attempt_at)
  VALUES (v_batch.id, 'pending', now())
  RETURNING id INTO v_dispatch_id;

  INSERT INTO public.profiles (
    id,
    email,
    account_type,
    is_first_login,
    accepted_terms_at,
    terms_version,
    privacy_version,
    marketing_consent,
    marketing_version,
    ip_address
  )
  VALUES (
    v_batch.user_id,
    v_batch.email,
    'hub',
    false,
    v_batch.accepted_at,
    COALESCE(v_terms, '1.0'),
    v_privacy,
    v_marketing_consent,
    v_marketing,
    v_batch.ip_address
  )
  ON CONFLICT (id) DO UPDATE
  SET
    email = COALESCE(EXCLUDED.email, public.profiles.email),
    accepted_terms_at = EXCLUDED.accepted_terms_at,
    terms_version = COALESCE(EXCLUDED.terms_version, public.profiles.terms_version),
    privacy_version = COALESCE(EXCLUDED.privacy_version, public.profiles.privacy_version),
    marketing_consent = public.profiles.marketing_consent OR EXCLUDED.marketing_consent,
    marketing_version = COALESCE(EXCLUDED.marketing_version, public.profiles.marketing_version),
    ip_address = COALESCE(EXCLUDED.ip_address, public.profiles.ip_address),
    updated_at = now();

  RETURN jsonb_build_object(
    'already_recorded', false,
    'batch_id', v_batch.id,
    'dispatch_id', v_dispatch_id
  );
END;
$$;

REVOKE ALL ON FUNCTION private.finalize_legal_consent(uuid, text, text, uuid[])
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.finalize_legal_consent(uuid, text, text, uuid[])
  TO postgres, service_role;

-- ---------------------------------------------------------------------------
-- Queue: claim / get / mark sent / mark failed
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.lease_legal_welcome_dispatch(p_dispatch_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_row public.legal_welcome_dispatches%ROWTYPE;
BEGIN
  SELECT * INTO v_row
  FROM public.legal_welcome_dispatches
  WHERE id = p_dispatch_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  IF v_row.status = 'sent' THEN
    RETURN private.legal_welcome_payload(v_row.id);
  END IF;

  UPDATE public.legal_welcome_dispatches
  SET
    status = 'processing',
    attempt_count = attempt_count + 1,
    next_attempt_at = now() + interval '10 minutes'
  WHERE id = p_dispatch_id;

  RETURN private.legal_welcome_payload(p_dispatch_id);
END;
$$;

REVOKE ALL ON FUNCTION private.lease_legal_welcome_dispatch(uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.lease_legal_welcome_dispatch(uuid)
  TO postgres, service_role;

CREATE OR REPLACE FUNCTION public.begin_legal_consent(
  p_user_id uuid,
  p_source text,
  p_email text,
  p_ip_address text,
  p_user_agent text,
  p_document_ids uuid[]
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'private', 'public', 'pg_catalog'
AS $$
  SELECT private.begin_legal_consent(
    p_user_id, p_source, p_email, p_ip_address, p_user_agent, p_document_ids
  );
$$;

CREATE OR REPLACE FUNCTION public.finalize_legal_consent(
  p_batch_id uuid,
  p_pdf_sha256 text,
  p_pdf_storage_path text,
  p_document_ids uuid[]
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'private', 'public', 'pg_catalog'
AS $$
  SELECT private.finalize_legal_consent(
    p_batch_id, p_pdf_sha256, p_pdf_storage_path, p_document_ids
  );
$$;

CREATE OR REPLACE FUNCTION public.get_legal_welcome_email_payload(p_dispatch_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'private', 'public', 'pg_catalog'
AS $$
BEGIN
  RETURN private.lease_legal_welcome_dispatch(p_dispatch_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.claim_legal_welcome_jobs(p_limit integer DEFAULT 10)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'private', 'public', 'pg_catalog'
AS $$
DECLARE
  v_id uuid;
  v_items jsonb := '[]'::jsonb;
  v_payload jsonb;
  v_limit integer := GREATEST(1, LEAST(COALESCE(p_limit, 10), 50));
BEGIN
  FOR v_id IN
    SELECT d.id
    FROM public.legal_welcome_dispatches d
    JOIN public.user_consent_batches b ON b.id = d.batch_id
    WHERE b.pdf_storage_path IS NOT NULL
      AND (
        (d.status IN ('pending', 'failed') AND d.next_attempt_at <= now())
        OR (d.status = 'processing' AND d.next_attempt_at <= now())
      )
      AND d.attempt_count < 12
    ORDER BY d.next_attempt_at
    FOR UPDATE OF d SKIP LOCKED
    LIMIT v_limit
  LOOP
    v_payload := private.lease_legal_welcome_dispatch(v_id);
    IF v_payload IS NOT NULL AND (v_payload->>'already_sent') IS DISTINCT FROM 'true' THEN
      v_items := v_items || jsonb_build_array(v_payload);
    END IF;
  END LOOP;

  RETURN v_items;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_legal_welcome_sent(
  p_dispatch_id uuid,
  p_message_id text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  UPDATE public.legal_welcome_dispatches
  SET
    status = 'sent',
    sent_at = COALESCE(sent_at, now()),
    last_error = NULL,
    provider_message_id = COALESCE(NULLIF(btrim(COALESCE(p_message_id, '')), ''), provider_message_id)
  WHERE id = p_dispatch_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_legal_welcome_failed(
  p_dispatch_id uuid,
  p_error text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_attempts integer;
BEGIN
  SELECT attempt_count INTO v_attempts
  FROM public.legal_welcome_dispatches
  WHERE id = p_dispatch_id;

  UPDATE public.legal_welcome_dispatches
  SET
    status = 'failed',
    last_error = left(COALESCE(NULLIF(btrim(p_error), ''), 'SMTP send failed'), 2000),
    next_attempt_at = now() + (interval '5 minutes' * GREATEST(1, COALESCE(v_attempts, 1)))
  WHERE id = p_dispatch_id
    AND status IS DISTINCT FROM 'sent';
END;
$$;

REVOKE ALL ON FUNCTION public.begin_legal_consent(uuid, text, text, text, text, uuid[])
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.finalize_legal_consent(uuid, text, text, uuid[])
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.get_legal_welcome_email_payload(uuid)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.claim_legal_welcome_jobs(integer)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.mark_legal_welcome_sent(uuid, text)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.mark_legal_welcome_failed(uuid, text)
  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.begin_legal_consent(uuid, text, text, text, text, uuid[])
  TO service_role;
GRANT EXECUTE ON FUNCTION public.finalize_legal_consent(uuid, text, text, uuid[])
  TO service_role;
GRANT EXECUTE ON FUNCTION public.get_legal_welcome_email_payload(uuid)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.claim_legal_welcome_jobs(integer)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.mark_legal_welcome_sent(uuid, text)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.mark_legal_welcome_failed(uuid, text)
  TO service_role;
