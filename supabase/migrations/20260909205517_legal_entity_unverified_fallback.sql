-- Unverified legal-entity fallback when GUS BIR is down.
-- Tenant managers may create pending_manual rows via SECURITY DEFINER RPC.
-- Direct PostgREST writes stay platform-admin only.

-- ---------------------------------------------------------------------------
-- Schema
-- ---------------------------------------------------------------------------

CREATE TYPE public.legal_entity_verification_status AS ENUM (
  'gus_verified',
  'pending_manual',
  'manually_verified'
);

ALTER TABLE public.legal_entities
  ADD COLUMN verification_status public.legal_entity_verification_status
    NOT NULL DEFAULT 'gus_verified',
  ADD COLUMN verification_reason text,
  ADD COLUMN verification_requested_at timestamptz,
  ADD COLUMN verification_resolved_at timestamptz,
  ADD COLUMN verification_resolved_by uuid REFERENCES auth.users (id) ON DELETE SET NULL;

ALTER TABLE public.legal_entities
  ADD CONSTRAINT legal_entities_verification_reason_chk
  CHECK (
    verification_reason IS NULL
    OR verification_reason = ANY (ARRAY['gus_unavailable'::text, 'gus_not_configured'::text])
  );

COMMENT ON COLUMN public.legal_entities.verification_status IS
  'gus_verified = BIR payload stored; pending_manual = created during GUS outage; manually_verified = platform admin confirmed without BIR.';

ALTER TABLE public.legal_entities
  ALTER COLUMN regon DROP NOT NULL;

ALTER TABLE public.legal_entities
  DROP CONSTRAINT legal_entities_regon_chk,
  ADD CONSTRAINT legal_entities_regon_chk
  CHECK (regon_normalized IS NULL OR public.regon_checksum_ok(regon_normalized));

DROP INDEX IF EXISTS public.legal_entities_regon_uidx;
CREATE UNIQUE INDEX legal_entities_regon_uidx
  ON public.legal_entities (regon_normalized)
  WHERE regon_normalized IS NOT NULL;

ALTER TABLE public.legal_entities
  DROP CONSTRAINT legal_entities_krs_required_chk,
  ADD CONSTRAINT legal_entities_krs_required_chk
  CHECK (
    kind <> 'housing_cooperative'::public.legal_entity_kind
    OR verification_status = 'pending_manual'::public.legal_entity_verification_status
    OR krs_normalized ~ '^[0-9]{10}$'
  );

ALTER TABLE public.legal_entities
  DROP CONSTRAINT legal_entities_gus_or_admin_chk,
  ADD CONSTRAINT legal_entities_gus_or_admin_chk
  CHECK (
    gus_fetched_at IS NOT NULL
    OR created_without_gus = true
    OR verification_status = ANY (
      ARRAY[
        'pending_manual'::public.legal_entity_verification_status,
        'manually_verified'::public.legal_entity_verification_status
      ]
    )
  );

CREATE INDEX legal_entities_pending_manual_idx
  ON public.legal_entities (created_at DESC)
  WHERE verification_status = 'pending_manual'::public.legal_entity_verification_status;

-- ---------------------------------------------------------------------------
-- Write guard: RPC may UPDATE verification / GUS columns
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.legal_entity_mark_rpc_writer()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  PERFORM set_config('app.legal_entity_writer', 'rpc', true);
END;
$$;

REVOKE ALL ON FUNCTION public.legal_entity_mark_rpc_writer() FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.tg_legal_entities_write_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.updated_at := now();
    NEW.updated_by := COALESCE(NEW.updated_by, auth.uid());
    IF NEW.created_without_gus IS TRUE AND NOT public.is_platform_admin() THEN
      RAISE EXCEPTION 'LEGAL_ENTITY_GUS_REQUIRED'
        USING HINT = 'Only a platform admin may create a legal entity that is not in GUS.';
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    NEW.updated_at := now();
    NEW.updated_by := COALESCE(auth.uid(), NEW.updated_by);
    IF current_setting('app.legal_entity_writer', true) = 'rpc' THEN
      RETURN NEW;
    END IF;
    IF NOT public.is_platform_admin() THEN
      RAISE EXCEPTION 'LEGAL_ENTITY_PLATFORM_ADMIN_ONLY'
        USING HINT = 'Registry identity may be corrected only by a Domio platform admin.';
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    IF NOT public.is_platform_admin() THEN
      RAISE EXCEPTION 'LEGAL_ENTITY_PLATFORM_ADMIN_ONLY';
    END IF;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

-- ---------------------------------------------------------------------------
-- Public JSON + lookup
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.legal_entity_public_json(p_row public.legal_entities)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT jsonb_build_object(
    'id', p_row.id,
    'kind', p_row.kind,
    'status', p_row.status,
    'nip', p_row.nip_normalized,
    'regon', p_row.regon_normalized,
    'krs', p_row.krs_normalized,
    'shortName', p_row.short_name,
    'legalName', p_row.legal_name,
    'city', p_row.city,
    'postalCode', p_row.postal_code,
    'seatFullAddress', p_row.seat_full_address,
    'verificationStatus', p_row.verification_status,
    'verificationReason', p_row.verification_reason
  );
$$;

CREATE OR REPLACE FUNCTION public.lookup_legal_entity_by_nip(p_nip text, p_org_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_digits text;
  v_row public.legal_entities%ROWTYPE;
  v_enrolled boolean;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_AUTH_REQUIRED';
  END IF;

  IF p_org_id IS NULL OR NOT public.is_org_management(p_org_id) THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_LOOKUP_FORBIDDEN'
      USING HINT = 'Only organisation management may look up a contractor by NIP.';
  END IF;

  v_digits := regexp_replace(COALESCE(p_nip, ''), '[^0-9]', '', 'g');
  IF NOT public.nip_checksum_ok(v_digits) THEN
    RETURN jsonb_build_object(
      'status', 'invalid_nip'::text,
      'entity', NULL,
      'alreadyEnrolledInThisOrg', false
    );
  END IF;

  SELECT * INTO v_row
  FROM public.legal_entities
  WHERE nip_normalized = v_digits;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'status', 'not_in_domio'::text,
      'entity', NULL,
      'alreadyEnrolledInThisOrg', false
    );
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM public.org_legal_entity_enrollments e
    WHERE e.org_id = p_org_id
      AND e.legal_entity_id = v_row.id
  ) INTO v_enrolled;

  RETURN jsonb_build_object(
    'status', 'exists_in_domio'::text,
    'alreadyEnrolledInThisOrg', v_enrolled,
    'entity', public.legal_entity_public_json(v_row)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.user_can_verify_legal_entity(p_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    public.is_platform_admin()
    OR EXISTS (
      SELECT 1
      FROM public.org_legal_entity_enrollments e
      WHERE e.legal_entity_id = p_id
        AND e.status = 'active'
        AND public.is_org_management(e.org_id)
    );
$$;

REVOKE ALL ON FUNCTION public.user_can_verify_legal_entity(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.user_can_verify_legal_entity(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.enroll_legal_entity_for_org(
  p_org_id uuid,
  p_legal_entity_id uuid,
  p_is_cleaning boolean DEFAULT false,
  p_is_maintenance boolean DEFAULT false,
  p_is_admin boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.legal_entities%ROWTYPE;
  v_enroll public.org_legal_entity_enrollments%ROWTYPE;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_AUTH_REQUIRED';
  END IF;

  IF p_org_id IS NULL
     OR (
       NOT public.is_org_management(p_org_id)
       AND NOT public.is_platform_admin()
     )
  THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_ENROLL_FORBIDDEN';
  END IF;

  SELECT * INTO v_row
  FROM public.legal_entities
  WHERE id = p_legal_entity_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_NOT_FOUND';
  END IF;

  INSERT INTO public.org_legal_entity_enrollments (
    org_id,
    legal_entity_id,
    is_cleaning,
    is_maintenance,
    is_admin,
    status
  )
  VALUES (
    p_org_id,
    p_legal_entity_id,
    COALESCE(p_is_cleaning, false),
    COALESCE(p_is_maintenance, false),
    COALESCE(p_is_admin, false),
    'active'
  )
  ON CONFLICT (org_id, legal_entity_id) DO UPDATE
    SET
      is_cleaning = public.org_legal_entity_enrollments.is_cleaning OR EXCLUDED.is_cleaning,
      is_maintenance = public.org_legal_entity_enrollments.is_maintenance OR EXCLUDED.is_maintenance,
      is_admin = public.org_legal_entity_enrollments.is_admin OR EXCLUDED.is_admin,
      status = 'active'
  RETURNING * INTO v_enroll;

  PERFORM public.sync_legal_entity_legacy_overlay(v_row, p_org_id);

  RETURN jsonb_build_object(
    'status', 'enrolled',
    'enrollmentId', v_enroll.id,
    'alreadyEnrolledInThisOrg', true,
    'entity', public.legal_entity_public_json(v_row)
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- Create without GUS (tenant emergency path)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.create_legal_entity_unverified(
  p_org_id uuid,
  p_kind public.legal_entity_kind,
  p_nip text,
  p_short_name text,
  p_legal_name text,
  p_email text,
  p_phone text,
  p_city text,
  p_postal_code text,
  p_reason text,
  p_street text DEFAULT NULL,
  p_building_number text DEFAULT NULL,
  p_voivodeship text DEFAULT NULL,
  p_is_cleaning boolean DEFAULT false,
  p_is_maintenance boolean DEFAULT false,
  p_is_admin boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_nip text;
  v_short text;
  v_legal text;
  v_city text;
  v_postal text;
  v_street text;
  v_building text;
  v_voiv text;
  v_seat text;
  v_existing uuid;
  v_row public.legal_entities%ROWTYPE;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_AUTH_REQUIRED';
  END IF;

  IF p_org_id IS NULL
     OR (
       NOT public.is_org_management(p_org_id)
       AND NOT public.is_platform_admin()
     )
  THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_UNVERIFIED_FORBIDDEN';
  END IF;

  IF p_reason IS NULL OR p_reason NOT IN ('gus_unavailable', 'gus_not_configured') THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_INVALID_VERIFICATION_REASON';
  END IF;

  v_nip := regexp_replace(COALESCE(p_nip, ''), '[^0-9]', '', 'g');
  v_short := NULLIF(btrim(COALESCE(p_short_name, '')), '');
  v_legal := NULLIF(btrim(COALESCE(p_legal_name, '')), '');
  v_city := NULLIF(btrim(COALESCE(p_city, '')), '');
  v_postal := public.normalize_pl_postal(p_postal_code);
  v_street := NULLIF(btrim(COALESCE(p_street, '')), '');
  v_building := NULLIF(btrim(COALESCE(p_building_number, '')), '');
  v_voiv := NULLIF(btrim(COALESCE(p_voivodeship, '')), '');

  IF v_short IS NULL THEN
    v_short := left(COALESCE(v_legal, ''), 80);
  END IF;
  IF v_legal IS NULL THEN
    v_legal := v_short;
  END IF;
  IF v_voiv IS NULL THEN
    v_voiv := 'nieustalone';
  END IF;
  IF v_building IS NULL THEN
    v_building := 'b.n.';
  END IF;

  v_seat := concat_ws(
    ', ',
    NULLIF(concat_ws(' ', v_street, v_building), ''),
    NULLIF(concat_ws(' ', v_postal, v_city), '')
  );

  IF NOT public.nip_checksum_ok(v_nip)
     OR v_short IS NULL
     OR v_legal IS NULL
     OR v_city IS NULL
     OR v_postal IS NULL
     OR char_length(btrim(COALESCE(p_email, ''))) < 5
     OR char_length(regexp_replace(COALESCE(p_phone, ''), '[^0-9+]', '', 'g')) < 9
  THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_INCOMPLETE_DATA';
  END IF;

  SELECT id INTO v_existing
  FROM public.legal_entities
  WHERE nip_normalized = v_nip;

  IF v_existing IS NOT NULL THEN
    RETURN public.enroll_legal_entity_for_org(
      p_org_id,
      v_existing,
      p_is_cleaning,
      p_is_maintenance,
      p_is_admin
    ) || jsonb_build_object('status', 'exists_in_domio');
  END IF;

  PERFORM public.legal_entity_mark_rpc_writer();

  INSERT INTO public.legal_entities (
    kind,
    status,
    nip,
    regon,
    krs,
    short_name,
    legal_name,
    voivodeship,
    county,
    commune,
    city,
    postal_code,
    street,
    building_number,
    apartment_number,
    seat_full_address,
    email,
    phone,
    created_without_gus,
    gus_fetched_at,
    verification_status,
    verification_reason,
    verification_requested_at,
    created_by_org_id,
    updated_by
  )
  VALUES (
    p_kind,
    'active',
    v_nip,
    NULL,
    NULL,
    v_short,
    v_legal,
    v_voiv,
    NULL,
    NULL,
    v_city,
    v_postal,
    v_street,
    v_building,
    NULL,
    v_seat,
    btrim(p_email),
    btrim(p_phone),
    false,
    NULL,
    'pending_manual',
    p_reason,
    now(),
    p_org_id,
    auth.uid()
  )
  RETURNING * INTO v_row;

  PERFORM public.enroll_legal_entity_for_org(
    p_org_id,
    v_row.id,
    p_is_cleaning,
    p_is_maintenance,
    p_is_admin
  );

  RETURN jsonb_build_object(
    'status', 'created_unverified',
    'alreadyEnrolledInThisOrg', true,
    'entity', public.legal_entity_public_json(v_row)
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- Alert lists
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.list_org_verification_alerts(p_org_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_AUTH_REQUIRED';
  END IF;

  IF p_org_id IS NULL
     OR (
       NOT public.is_org_management(p_org_id)
       AND NOT public.is_platform_admin()
     )
  THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_UNVERIFIED_FORBIDDEN';
  END IF;

  RETURN COALESCE(
    (
      SELECT jsonb_agg(item ORDER BY item ->> 'createdAt')
      FROM (
        SELECT jsonb_build_object(
          'legalEntityId', le.id,
          'orgId', e.org_id,
          'orgName', o.name,
          'kind', le.kind,
          'nip', le.nip_normalized,
          'shortName', le.short_name,
          'createdAt', le.created_at,
          'reason', le.verification_reason,
          'overlayKind', CASE
            WHEN le.kind IN (
              'housing_community'::public.legal_entity_kind,
              'housing_cooperative'::public.legal_entity_kind
            ) THEN 'community'
            ELSE 'company'
          END,
          'overlayId', COALESCE(c.id, co.id)
        ) AS item
        FROM public.legal_entities le
        INNER JOIN public.org_legal_entity_enrollments e
          ON e.legal_entity_id = le.id
         AND e.org_id = p_org_id
         AND e.status = 'active'
        INNER JOIN public.organizations o ON o.id = e.org_id
        LEFT JOIN public.communities c
          ON c.org_id = e.org_id
         AND c.legal_entity_id = le.id
        LEFT JOIN public.companies co
          ON co.legal_entity_id = le.id
        WHERE le.verification_status = 'pending_manual'::public.legal_entity_verification_status
      ) s
    ),
    '[]'::jsonb
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.count_org_verification_alerts(p_org_id uuid)
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_count integer;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_AUTH_REQUIRED';
  END IF;

  IF p_org_id IS NULL
     OR (
       NOT public.is_org_management(p_org_id)
       AND NOT public.is_platform_admin()
     )
  THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_UNVERIFIED_FORBIDDEN';
  END IF;

  SELECT count(*)::integer
  INTO v_count
  FROM public.legal_entities le
  INNER JOIN public.org_legal_entity_enrollments e
    ON e.legal_entity_id = le.id
   AND e.org_id = p_org_id
   AND e.status = 'active'
  WHERE le.verification_status = 'pending_manual'::public.legal_entity_verification_status;

  RETURN COALESCE(v_count, 0);
END;
$$;

CREATE OR REPLACE FUNCTION public.list_platform_verification_alerts()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_AUTH_REQUIRED';
  END IF;

  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_VERIFY_PLATFORM_ONLY';
  END IF;

  RETURN COALESCE(
    (
      SELECT jsonb_agg(item ORDER BY item ->> 'createdAt')
      FROM (
        SELECT jsonb_build_object(
          'legalEntityId', le.id,
          'orgId', le.created_by_org_id,
          'orgName', o.name,
          'kind', le.kind,
          'nip', le.nip_normalized,
          'shortName', le.short_name,
          'createdAt', le.created_at,
          'reason', le.verification_reason,
          'overlayKind', CASE
            WHEN le.kind IN (
              'housing_community'::public.legal_entity_kind,
              'housing_cooperative'::public.legal_entity_kind
            ) THEN 'community'
            ELSE 'company'
          END,
          'overlayId', COALESCE(c.id, co.id)
        ) AS item
        FROM public.legal_entities le
        LEFT JOIN public.organizations o ON o.id = le.created_by_org_id
        LEFT JOIN LATERAL (
          SELECT id
          FROM public.communities
          WHERE legal_entity_id = le.id
          ORDER BY created_at
          LIMIT 1
        ) c ON true
        LEFT JOIN LATERAL (
          SELECT id
          FROM public.companies
          WHERE legal_entity_id = le.id
          ORDER BY created_at
          LIMIT 1
        ) co ON true
        WHERE le.verification_status = 'pending_manual'::public.legal_entity_verification_status
      ) s
    ),
    '[]'::jsonb
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.count_platform_verification_alerts()
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_count integer;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_AUTH_REQUIRED';
  END IF;

  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_VERIFY_PLATFORM_ONLY';
  END IF;

  SELECT count(*)::integer
  INTO v_count
  FROM public.legal_entities
  WHERE verification_status = 'pending_manual'::public.legal_entity_verification_status;

  RETURN COALESCE(v_count, 0);
END;
$$;

-- ---------------------------------------------------------------------------
-- Apply GUS after outage / resolve manually
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.apply_legal_entity_gus_data(
  p_legal_entity_id uuid,
  p_gus jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.legal_entities%ROWTYPE;
  v_regon text;
  v_krs text;
  v_legal_name text;
  v_city text;
  v_postal text;
  v_street text;
  v_building text;
  v_apt text;
  v_voiv text;
  v_county text;
  v_commune text;
  v_seat text;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_AUTH_REQUIRED';
  END IF;

  IF p_legal_entity_id IS NULL OR NOT public.user_can_verify_legal_entity(p_legal_entity_id) THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_UNVERIFIED_FORBIDDEN';
  END IF;

  IF p_gus IS NULL OR jsonb_typeof(p_gus) <> 'object' THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_GUS_PAYLOAD_REQUIRED';
  END IF;

  SELECT * INTO v_row
  FROM public.legal_entities
  WHERE id = p_legal_entity_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_NOT_FOUND';
  END IF;

  IF v_row.verification_status <> 'pending_manual'::public.legal_entity_verification_status THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_ALREADY_VERIFIED';
  END IF;

  IF NULLIF(btrim(COALESCE(p_gus ->> 'endedAt', '')), '') IS NOT NULL THEN
    RAISE EXCEPTION 'GUS_INACTIVE';
  END IF;

  v_regon := NULLIF(regexp_replace(COALESCE(p_gus ->> 'regon', ''), '[^0-9]', '', 'g'), '');
  v_krs := NULLIF(regexp_replace(COALESCE(p_gus ->> 'krs', ''), '[^0-9]', '', 'g'), '');
  v_legal_name := NULLIF(btrim(COALESCE(p_gus ->> 'legalName', '')), '');
  v_city := NULLIF(btrim(COALESCE(p_gus ->> 'city', '')), '');
  v_postal := public.normalize_pl_postal(p_gus ->> 'postalCode');
  v_street := NULLIF(btrim(COALESCE(p_gus ->> 'street', '')), '');
  v_building := NULLIF(btrim(COALESCE(p_gus ->> 'buildingNumber', '')), '');
  v_apt := NULLIF(btrim(COALESCE(p_gus ->> 'apartmentNumber', '')), '');
  v_voiv := NULLIF(btrim(COALESCE(p_gus ->> 'voivodeship', '')), '');
  v_county := NULLIF(btrim(COALESCE(p_gus ->> 'county', '')), '');
  v_commune := NULLIF(btrim(COALESCE(p_gus ->> 'commune', '')), '');

  IF v_voiv IS NULL THEN
    v_voiv := v_row.voivodeship;
  END IF;
  IF v_building IS NULL THEN
    v_building := COALESCE(v_row.building_number, 'b.n.');
  END IF;
  IF v_city IS NULL THEN
    v_city := v_row.city;
  END IF;
  IF v_postal IS NULL THEN
    v_postal := v_row.postal_code;
  END IF;
  IF v_legal_name IS NULL THEN
    v_legal_name := v_row.legal_name;
  END IF;

  v_seat := NULLIF(btrim(COALESCE(p_gus ->> 'seatFullAddress', '')), '');
  IF v_seat IS NULL THEN
    v_seat := concat_ws(
      ', ',
      NULLIF(concat_ws(' ', v_street, v_building, v_apt), ''),
      NULLIF(concat_ws(' ', v_postal, v_city), '')
    );
  END IF;

  IF v_legal_name IS NULL OR v_city IS NULL OR v_postal IS NULL THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_INCOMPLETE_DATA';
  END IF;

  IF v_row.kind = 'housing_cooperative'::public.legal_entity_kind
     AND (v_krs IS NULL OR v_krs !~ '^[0-9]{10}$')
  THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_INCOMPLETE_DATA';
  END IF;

  PERFORM public.legal_entity_mark_rpc_writer();

  UPDATE public.legal_entities
  SET
    regon = v_regon,
    krs = v_krs,
    legal_name = v_legal_name,
    voivodeship = v_voiv,
    county = v_county,
    commune = v_commune,
    city = v_city,
    postal_code = v_postal,
    street = COALESCE(v_street, street),
    building_number = v_building,
    apartment_number = COALESCE(v_apt, apartment_number),
    seat_full_address = v_seat,
    gus_legal_form_code = NULLIF(btrim(COALESCE(p_gus ->> 'legalFormCode', '')), ''),
    gus_legal_form_name = NULLIF(btrim(COALESCE(p_gus ->> 'legalFormName', '')), ''),
    gus_fetched_at = now(),
    gus_payload = p_gus,
    verification_status = 'gus_verified',
    verification_reason = NULL,
    verification_resolved_at = now(),
    verification_resolved_by = auth.uid()
  WHERE id = p_legal_entity_id
  RETURNING * INTO v_row;

  UPDATE public.communities
  SET
    nip = v_row.nip_normalized,
    legal_name = v_row.legal_name,
    regon = v_row.regon_normalized,
    updated_at = now()
  WHERE legal_entity_id = v_row.id;

  UPDATE public.companies
  SET
    tax_id = v_row.nip_normalized,
    address = v_row.seat_full_address,
    updated_at = now()
  WHERE legal_entity_id = v_row.id;

  RETURN jsonb_build_object(
    'status', 'gus_verified',
    'entity', public.legal_entity_public_json(v_row)
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_REGON_TAKEN';
END;
$$;

CREATE OR REPLACE FUNCTION public.resolve_legal_entity_verification(p_legal_entity_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.legal_entities%ROWTYPE;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_AUTH_REQUIRED';
  END IF;

  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_VERIFY_PLATFORM_ONLY';
  END IF;

  SELECT * INTO v_row
  FROM public.legal_entities
  WHERE id = p_legal_entity_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_NOT_FOUND';
  END IF;

  IF v_row.verification_status <> 'pending_manual'::public.legal_entity_verification_status THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_ALREADY_VERIFIED';
  END IF;

  PERFORM public.legal_entity_mark_rpc_writer();

  UPDATE public.legal_entities
  SET
    verification_status = 'manually_verified',
    verification_resolved_at = now(),
    verification_resolved_by = auth.uid()
  WHERE id = p_legal_entity_id
  RETURNING * INTO v_row;

  RETURN jsonb_build_object(
    'status', 'manually_verified',
    'entity', public.legal_entity_public_json(v_row)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.platform_admin_create_legal_entity_without_gus(
  p_kind public.legal_entity_kind,
  p_nip text,
  p_regon text,
  p_krs text,
  p_short_name text,
  p_legal_name text,
  p_voivodeship text,
  p_county text,
  p_commune text,
  p_city text,
  p_postal_code text,
  p_street text,
  p_building_number text,
  p_apartment_number text,
  p_seat_full_address text,
  p_email text,
  p_phone text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.legal_entities%ROWTYPE;
  v_nip text;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_PLATFORM_ADMIN_ONLY';
  END IF;

  v_nip := regexp_replace(COALESCE(p_nip, ''), '[^0-9]', '', 'g');

  INSERT INTO public.legal_entities (
    kind,
    status,
    nip,
    regon,
    krs,
    short_name,
    legal_name,
    voivodeship,
    county,
    commune,
    city,
    postal_code,
    street,
    building_number,
    apartment_number,
    seat_full_address,
    email,
    phone,
    created_without_gus,
    gus_fetched_at,
    verification_status,
    verification_resolved_at,
    verification_resolved_by,
    updated_by
  )
  VALUES (
    p_kind,
    'active',
    v_nip,
    p_regon,
    NULLIF(btrim(COALESCE(p_krs, '')), ''),
    btrim(p_short_name),
    btrim(p_legal_name),
    btrim(p_voivodeship),
    NULLIF(btrim(COALESCE(p_county, '')), ''),
    NULLIF(btrim(COALESCE(p_commune, '')), ''),
    btrim(p_city),
    public.normalize_pl_postal(p_postal_code),
    NULLIF(btrim(COALESCE(p_street, '')), ''),
    btrim(p_building_number),
    NULLIF(btrim(COALESCE(p_apartment_number, '')), ''),
    btrim(p_seat_full_address),
    btrim(p_email),
    btrim(p_phone),
    true,
    NULL,
    'manually_verified',
    now(),
    auth.uid(),
    auth.uid()
  )
  RETURNING * INTO v_row;

  RETURN jsonb_build_object(
    'status', 'created_without_gus',
    'entity', public.legal_entity_public_json(v_row)
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

REVOKE ALL ON FUNCTION public.create_legal_entity_unverified(
  uuid, public.legal_entity_kind, text, text, text, text, text, text, text, text, text, text, text, boolean, boolean, boolean
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_org_verification_alerts(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.count_org_verification_alerts(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_platform_verification_alerts() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.count_platform_verification_alerts() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.apply_legal_entity_gus_data(uuid, jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.resolve_legal_entity_verification(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.platform_admin_create_legal_entity_without_gus(
  public.legal_entity_kind, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.create_legal_entity_unverified(
  uuid, public.legal_entity_kind, text, text, text, text, text, text, text, text, text, text, text, boolean, boolean, boolean
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_org_verification_alerts(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.count_org_verification_alerts(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_platform_verification_alerts() TO authenticated;
GRANT EXECUTE ON FUNCTION public.count_platform_verification_alerts() TO authenticated;
GRANT EXECUTE ON FUNCTION public.apply_legal_entity_gus_data(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_legal_entity_verification(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.platform_admin_create_legal_entity_without_gus(
  public.legal_entity_kind, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text
) TO authenticated;

COMMENT ON FUNCTION public.create_legal_entity_unverified IS
  'Emergency create when GUS is down. Sets pending_manual. Edge function must re-probe BIR first.';
COMMENT ON FUNCTION public.list_platform_verification_alerts() IS
  'Platform-admin queue of legal entities awaiting GUS or manual verification.';
