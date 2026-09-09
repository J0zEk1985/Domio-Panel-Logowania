-- Global legal-entity registry (one NIP in all of Domio) + tenant enrollments + RLS.
-- Identity writes: platform admin (profiles.platform_role = admin) or future SECURITY DEFINER RPCs.
-- Tenants must not INSERT/UPDATE legal_entities via PostgREST; they enroll and attach buildings.

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

CREATE TYPE public.legal_entity_kind AS ENUM (
  'housing_community',
  'housing_cooperative',
  'property_manager',
  'company'
);

CREATE TYPE public.legal_entity_status AS ENUM (
  'active',
  'inactive',
  'deregistered'
);

CREATE TYPE public.legal_entity_lookup_status AS ENUM (
  'invalid_nip',
  'exists_in_domio',
  'not_in_domio'
);

-- ---------------------------------------------------------------------------
-- Identifier checksums
-- ---------------------------------------------------------------------------

CREATE FUNCTION public.nip_checksum_ok(digits text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
PARALLEL SAFE
SET search_path TO 'public'
AS $$
DECLARE
  s integer;
  c integer;
BEGIN
  IF digits IS NULL OR digits !~ '^[0-9]{10}$' THEN
    RETURN false;
  END IF;

  s :=
    6 * substr(digits, 1, 1)::integer
    + 5 * substr(digits, 2, 1)::integer
    + 7 * substr(digits, 3, 1)::integer
    + 2 * substr(digits, 4, 1)::integer
    + 3 * substr(digits, 5, 1)::integer
    + 4 * substr(digits, 6, 1)::integer
    + 5 * substr(digits, 7, 1)::integer
    + 6 * substr(digits, 8, 1)::integer
    + 7 * substr(digits, 9, 1)::integer;
  c := s % 11;
  IF c = 10 THEN
    RETURN false;
  END IF;
  RETURN c = substr(digits, 10, 1)::integer;
END;
$$;

CREATE FUNCTION public.regon_checksum_ok(digits text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
PARALLEL SAFE
SET search_path TO 'public'
AS $$
DECLARE
  s integer;
  c integer;
  w integer[];
  i integer;
  body text;
BEGIN
  IF digits IS NULL OR digits !~ '^[0-9]{9}([0-9]{5})?$' THEN
    RETURN false;
  END IF;

  IF length(digits) = 9 THEN
    w := ARRAY[8, 9, 2, 3, 4, 5, 6, 7];
    body := substr(digits, 1, 8);
  ELSE
    w := ARRAY[2, 4, 8, 5, 0, 9, 7, 3, 6, 1, 2, 4, 8];
    body := substr(digits, 1, 13);
  END IF;

  s := 0;
  FOR i IN 1..array_length(w, 1) LOOP
    s := s + w[i] * substr(body, i, 1)::integer;
  END LOOP;
  c := s % 11;
  IF c = 10 THEN
    c := 0;
  END IF;
  RETURN c = substr(digits, length(digits), 1)::integer;
END;
$$;

REVOKE ALL ON FUNCTION public.nip_checksum_ok(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.regon_checksum_ok(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.nip_checksum_ok(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.regon_checksum_ok(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.regon_checksum_ok(text) TO authenticated;

-- ---------------------------------------------------------------------------
-- Registry
-- ---------------------------------------------------------------------------

CREATE TABLE public.legal_entities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind public.legal_entity_kind NOT NULL,
  status public.legal_entity_status NOT NULL DEFAULT 'active',

  nip text NOT NULL,
  nip_normalized text GENERATED ALWAYS AS (regexp_replace(nip, '[^0-9]', '', 'g')) STORED,
  regon text NOT NULL,
  regon_normalized text GENERATED ALWAYS AS (regexp_replace(regon, '[^0-9]', '', 'g')) STORED,
  krs text,
  krs_normalized text GENERATED ALWAYS AS (
    NULLIF(regexp_replace(COALESCE(krs, ''), '[^0-9]', '', 'g'), '')
  ) STORED,

  short_name text NOT NULL,
  legal_name text NOT NULL,

  voivodeship text NOT NULL,
  county text,
  commune text,
  city text NOT NULL,
  postal_code text NOT NULL,
  street text,
  building_number text NOT NULL,
  apartment_number text,
  seat_full_address text NOT NULL,

  email text NOT NULL,
  phone text NOT NULL,

  gus_legal_form_code text,
  gus_legal_form_name text,
  gus_fetched_at timestamptz,
  gus_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_without_gus boolean NOT NULL DEFAULT false,

  created_by_org_id uuid REFERENCES public.organizations (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES auth.users (id) ON DELETE SET NULL,

  CONSTRAINT legal_entities_short_name_chk
    CHECK (char_length(btrim(short_name)) >= 3),
  CONSTRAINT legal_entities_legal_name_chk
    CHECK (char_length(btrim(legal_name)) >= 3),
  CONSTRAINT legal_entities_email_chk
    CHECK (email ~* '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'),
  CONSTRAINT legal_entities_phone_chk
    CHECK (char_length(regexp_replace(phone, '[^0-9+]', '', 'g')) >= 9),
  CONSTRAINT legal_entities_postal_chk
    CHECK (postal_code ~ '^[0-9]{2}-[0-9]{3}$'),
  CONSTRAINT legal_entities_nip_chk
    CHECK (public.nip_checksum_ok(nip_normalized)),
  CONSTRAINT legal_entities_regon_chk
    CHECK (public.regon_checksum_ok(regon_normalized)),
  CONSTRAINT legal_entities_krs_required_chk
    CHECK (
      kind <> 'housing_cooperative'::public.legal_entity_kind
      OR krs_normalized ~ '^[0-9]{10}$'
    ),
  CONSTRAINT legal_entities_gus_or_admin_chk
    CHECK (created_without_gus = true OR gus_fetched_at IS NOT NULL),
  CONSTRAINT legal_entities_gus_payload_obj_chk
    CHECK (jsonb_typeof(gus_payload) = 'object')
);

COMMENT ON TABLE public.legal_entities IS
  'Global legal-party registry for Domio. One row per NIP (wspólnota, spółdzielnia, zarządca, firma).';

CREATE UNIQUE INDEX legal_entities_nip_uidx
  ON public.legal_entities (nip_normalized);

CREATE UNIQUE INDEX legal_entities_regon_uidx
  ON public.legal_entities (regon_normalized);

CREATE UNIQUE INDEX legal_entities_krs_uidx
  ON public.legal_entities (krs_normalized)
  WHERE krs_normalized IS NOT NULL;

CREATE INDEX legal_entities_kind_status_idx
  ON public.legal_entities (kind, status);

-- ---------------------------------------------------------------------------
-- Tenant enrollment (operational secrets stay here, not on the global row)
-- ---------------------------------------------------------------------------

CREATE TABLE public.org_legal_entity_enrollments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations (id) ON DELETE CASCADE,
  legal_entity_id uuid NOT NULL REFERENCES public.legal_entities (id) ON DELETE RESTRICT,
  is_cleaning boolean NOT NULL DEFAULT false,
  is_maintenance boolean NOT NULL DEFAULT false,
  is_admin boolean NOT NULL DEFAULT false,
  access_codes jsonb NOT NULL DEFAULT '{}'::jsonb,
  operational_notes jsonb NOT NULL DEFAULT '{}'::jsonb,
  financial_details jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, legal_entity_id),
  CONSTRAINT org_legal_entity_enrollments_status_chk
    CHECK (status = ANY (ARRAY['active'::text, 'inactive'::text])),
  CONSTRAINT org_legal_entity_enrollments_access_codes_chk
    CHECK (jsonb_typeof(access_codes) = 'object'),
  CONSTRAINT org_legal_entity_enrollments_notes_chk
    CHECK (jsonb_typeof(operational_notes) = 'object'),
  CONSTRAINT org_legal_entity_enrollments_fin_chk
    CHECK (jsonb_typeof(financial_details) = 'object')
);

COMMENT ON TABLE public.org_legal_entity_enrollments IS
  'Which tenant org services a global legal entity, and that org''s operational data.';

CREATE INDEX org_legal_entity_enrollments_entity_idx
  ON public.org_legal_entity_enrollments (legal_entity_id);

CREATE INDEX org_legal_entity_enrollments_org_idx
  ON public.org_legal_entity_enrollments (org_id);

-- ---------------------------------------------------------------------------
-- Platform-admin audit
-- ---------------------------------------------------------------------------

CREATE TABLE public.legal_entity_audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legal_entity_id uuid REFERENCES public.legal_entities (id) ON DELETE SET NULL,
  actor_id uuid,
  action text NOT NULL,
  before_row jsonb,
  after_row jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT legal_entity_audit_log_action_chk
    CHECK (action = ANY (ARRAY['insert'::text, 'update'::text, 'delete'::text]))
);

CREATE INDEX legal_entity_audit_log_entity_idx
  ON public.legal_entity_audit_log (legal_entity_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- Physical address owns at most one legal entity (locations.google_place_id is already unique)
-- ---------------------------------------------------------------------------

ALTER TABLE public.locations
  ADD COLUMN legal_entity_id uuid REFERENCES public.legal_entities (id) ON DELETE RESTRICT;

CREATE INDEX locations_legal_entity_id_idx
  ON public.locations (legal_entity_id);

COMMENT ON COLUMN public.locations.legal_entity_id IS
  'Canonical owner of this address. Two legal entities cannot share a google_place_id.';

-- Bridge for existing module tables (writes still allowed until Layer 3 RPCs).
ALTER TABLE public.communities
  ADD COLUMN legal_entity_id uuid REFERENCES public.legal_entities (id) ON DELETE RESTRICT;

CREATE UNIQUE INDEX communities_legal_entity_id_uidx
  ON public.communities (legal_entity_id)
  WHERE legal_entity_id IS NOT NULL;

ALTER TABLE public.companies
  ADD COLUMN legal_entity_id uuid REFERENCES public.legal_entities (id) ON DELETE RESTRICT;

CREATE UNIQUE INDEX companies_legal_entity_id_uidx
  ON public.companies (legal_entity_id)
  WHERE legal_entity_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Auth helpers (SECURITY DEFINER, called from RLS — wrap auth.uid() once)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_org_management(p_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.memberships m
    WHERE m.org_id = p_org_id
      AND m.user_id = (SELECT auth.uid())
      AND COALESCE(m.is_active, true) = true
      AND m.role ILIKE ANY (
        ARRAY[
          'owner',
          'admin',
          'administrator',
          'manager',
          'coordinator',
          'koordynator',
          'wlasciciel'
        ]
      )
  );
$$;

CREATE FUNCTION public.is_active_org_member(p_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.memberships m
    WHERE m.org_id = p_org_id
      AND m.user_id = (SELECT auth.uid())
      AND COALESCE(m.is_active, true) = true
  );
$$;

CREATE FUNCTION public.user_can_read_legal_entity(p_id uuid)
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
        AND public.is_active_org_member(e.org_id)
    )
    OR EXISTS (
      SELECT 1
      FROM public.location_access la
      INNER JOIN public.cleaning_locations cl ON cl.id = la.location_id
      INNER JOIN public.locations loc ON loc.id = cl.location_master_id
      WHERE la.user_id = (SELECT auth.uid())
        AND loc.legal_entity_id = p_id
    );
$$;

CREATE FUNCTION public.user_can_assign_location_legal_entity(p_legal_entity_id uuid)
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
      WHERE e.legal_entity_id = p_legal_entity_id
        AND e.status = 'active'
        AND public.is_org_management(e.org_id)
    );
$$;

REVOKE ALL ON FUNCTION public.is_org_management(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_active_org_member(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.user_can_read_legal_entity(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.user_can_assign_location_legal_entity(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_org_management(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_active_org_member(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_can_read_legal_entity(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_can_assign_location_legal_entity(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

CREATE FUNCTION public.tg_legal_entities_write_guard()
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

CREATE TRIGGER trg_legal_entities_write_guard
  BEFORE INSERT OR UPDATE OR DELETE ON public.legal_entities
  FOR EACH ROW
  EXECUTE FUNCTION public.tg_legal_entities_write_guard();

CREATE FUNCTION public.tg_legal_entities_audit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.legal_entity_audit_log (legal_entity_id, actor_id, action, after_row)
    VALUES (NEW.id, auth.uid(), 'insert', to_jsonb(NEW) - 'gus_payload');
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO public.legal_entity_audit_log (legal_entity_id, actor_id, action, before_row, after_row)
    VALUES (NEW.id, auth.uid(), 'update', to_jsonb(OLD) - 'gus_payload', to_jsonb(NEW) - 'gus_payload');
    RETURN NEW;
  ELSE
    INSERT INTO public.legal_entity_audit_log (legal_entity_id, actor_id, action, before_row)
    VALUES (OLD.id, auth.uid(), 'delete', to_jsonb(OLD) - 'gus_payload');
    RETURN OLD;
  END IF;
END;
$$;

CREATE TRIGGER trg_legal_entities_audit
  AFTER INSERT OR UPDATE OR DELETE ON public.legal_entities
  FOR EACH ROW
  EXECUTE FUNCTION public.tg_legal_entities_audit();

CREATE FUNCTION public.tg_org_enrollments_touch()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_org_enrollments_touch
  BEFORE UPDATE ON public.org_legal_entity_enrollments
  FOR EACH ROW
  EXECUTE FUNCTION public.tg_org_enrollments_touch();

CREATE FUNCTION public.tg_locations_legal_entity_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.legal_entity_id IS NOT DISTINCT FROM OLD.legal_entity_id THEN
    RETURN NEW;
  END IF;

  IF public.is_platform_admin() THEN
    RETURN NEW;
  END IF;

  -- New addresses may be created unassigned (existing Cleaning/Serwis enroll).
  IF NEW.legal_entity_id IS NULL THEN
    IF TG_OP = 'INSERT' THEN
      RETURN NEW;
    END IF;
    RAISE EXCEPTION 'LOCATION_LEGAL_ENTITY_CLEAR_FORBIDDEN'
      USING HINT = 'Only a platform admin may detach an address from a legal entity.';
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.legal_entity_id IS NOT NULL THEN
    RAISE EXCEPTION 'LOCATION_LEGAL_ENTITY_REASSIGN_FORBIDDEN'
      USING HINT = 'An address already belongs to another contractor. Platform admin must reassign.';
  END IF;

  IF NOT public.user_can_assign_location_legal_entity(NEW.legal_entity_id) THEN
    RAISE EXCEPTION 'LOCATION_LEGAL_ENTITY_ASSIGN_FORBIDDEN'
      USING HINT = 'Enroll the contractor in your organisation before attaching buildings.';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_locations_legal_entity_guard
  BEFORE INSERT OR UPDATE ON public.locations
  FOR EACH ROW
  EXECUTE FUNCTION public.tg_locations_legal_entity_guard();

-- ---------------------------------------------------------------------------
-- NIP probe (no full registry listing). GUS fetch is Layer 3.
-- ---------------------------------------------------------------------------

CREATE FUNCTION public.lookup_legal_entity_by_nip(p_nip text, p_org_id uuid)
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
    'entity', jsonb_build_object(
      'id', v_row.id,
      'kind', v_row.kind,
      'status', v_row.status,
      'nip', v_row.nip_normalized,
      'regon', v_row.regon_normalized,
      'krs', v_row.krs_normalized,
      'shortName', v_row.short_name,
      'legalName', v_row.legal_name,
      'city', v_row.city,
      'postalCode', v_row.postal_code,
      'seatFullAddress', v_row.seat_full_address
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION public.lookup_legal_entity_by_nip(text, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.lookup_legal_entity_by_nip(text, uuid) TO authenticated;

COMMENT ON FUNCTION public.lookup_legal_entity_by_nip(text, uuid) IS
  'NIP-first probe: invalid / exists in Domio / not in Domio. Does not list the registry. GUS is a later RPC.';

-- ---------------------------------------------------------------------------
-- Grants + RLS
-- ---------------------------------------------------------------------------

ALTER TABLE public.legal_entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.org_legal_entity_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_entity_audit_log ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.legal_entities FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.org_legal_entity_enrollments FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.legal_entity_audit_log FROM anon, PUBLIC;

GRANT SELECT ON TABLE public.legal_entities TO authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.legal_entities TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.org_legal_entity_enrollments TO authenticated;

GRANT SELECT ON TABLE public.legal_entity_audit_log TO authenticated;

CREATE POLICY legal_entities_select_visible
  ON public.legal_entities
  FOR SELECT
  TO authenticated
  USING ((SELECT public.user_can_read_legal_entity(id)));

CREATE POLICY legal_entities_write_platform_admin
  ON public.legal_entities
  FOR ALL
  TO authenticated
  USING ((SELECT public.is_platform_admin()))
  WITH CHECK ((SELECT public.is_platform_admin()));

CREATE POLICY org_enrollments_select_member
  ON public.org_legal_entity_enrollments
  FOR SELECT
  TO authenticated
  USING (
    (SELECT public.is_platform_admin())
    OR (SELECT public.is_active_org_member(org_id))
  );

CREATE POLICY org_enrollments_insert_management
  ON public.org_legal_entity_enrollments
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT public.is_platform_admin())
    OR (SELECT public.is_org_management(org_id))
  );

CREATE POLICY org_enrollments_update_management
  ON public.org_legal_entity_enrollments
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT public.is_platform_admin())
    OR (SELECT public.is_org_management(org_id))
  )
  WITH CHECK (
    (SELECT public.is_platform_admin())
    OR (SELECT public.is_org_management(org_id))
  );

CREATE POLICY org_enrollments_delete_management
  ON public.org_legal_entity_enrollments
  FOR DELETE
  TO authenticated
  USING (
    (SELECT public.is_platform_admin())
    OR (SELECT public.is_org_management(org_id))
  );

CREATE POLICY legal_entity_audit_select_platform_admin
  ON public.legal_entity_audit_log
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_platform_admin()));
