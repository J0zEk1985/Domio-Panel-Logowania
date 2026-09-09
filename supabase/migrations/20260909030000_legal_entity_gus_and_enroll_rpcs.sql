-- Layer 3: GUS-backed create, enrollment, building attach, legacy-table locks.

CREATE OR REPLACE FUNCTION public.normalize_pl_postal(p_raw text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SET search_path TO 'public'
AS $$
  SELECT CASE
    WHEN regexp_replace(COALESCE(p_raw, ''), '[^0-9]', '', 'g') ~ '^[0-9]{5}$'
      THEN substr(regexp_replace(p_raw, '[^0-9]', '', 'g'), 1, 2)
        || '-'
        || substr(regexp_replace(p_raw, '[^0-9]', '', 'g'), 3, 3)
    WHEN COALESCE(p_raw, '') ~ '^[0-9]{2}-[0-9]{3}$' THEN p_raw
    ELSE NULL
  END;
$$;

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
    'seatFullAddress', p_row.seat_full_address
  );
$$;

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

  IF p_org_id IS NULL OR NOT public.is_org_management(p_org_id) THEN
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

  RETURN jsonb_build_object(
    'status', 'enrolled',
    'enrollmentId', v_enroll.id,
    'alreadyEnrolledInThisOrg', true,
    'entity', public.legal_entity_public_json(v_row)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_legal_entity_legacy_overlay(
  p_entity public.legal_entities,
  p_org_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF p_entity.kind IN (
    'housing_community'::public.legal_entity_kind,
    'housing_cooperative'::public.legal_entity_kind
  ) THEN
    INSERT INTO public.communities (
      org_id,
      name,
      nip,
      legal_name,
      regon,
      status,
      legal_entity_id
    )
    SELECT
      p_org_id,
      p_entity.short_name,
      p_entity.nip_normalized,
      p_entity.legal_name,
      p_entity.regon_normalized,
      'active',
      p_entity.id
    WHERE NOT EXISTS (
      SELECT 1 FROM public.communities c WHERE c.legal_entity_id = p_entity.id
    );
  ELSE
    INSERT INTO public.companies (
      org_id,
      name,
      tax_id,
      category,
      address,
      email,
      phone,
      legal_entity_id
    )
    SELECT
      p_org_id,
      p_entity.legal_name,
      p_entity.nip_normalized,
      CASE
        WHEN p_entity.kind = 'property_manager'::public.legal_entity_kind
          THEN 'contractor'::public.company_category
        ELSE 'other'::public.company_category
      END,
      p_entity.seat_full_address,
      p_entity.email,
      p_entity.phone,
      p_entity.id
    WHERE NOT EXISTS (
      SELECT 1 FROM public.companies c WHERE c.legal_entity_id = p_entity.id
    );
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_legal_entity_from_gus(
  p_org_id uuid,
  p_kind public.legal_entity_kind,
  p_gus jsonb,
  p_email text,
  p_phone text,
  p_short_name text,
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
  v_regon text;
  v_krs text;
  v_legal_name text;
  v_short text;
  v_city text;
  v_postal text;
  v_street text;
  v_building text;
  v_apt text;
  v_voiv text;
  v_county text;
  v_commune text;
  v_seat text;
  v_row public.legal_entities%ROWTYPE;
  v_existing uuid;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_AUTH_REQUIRED';
  END IF;

  IF p_org_id IS NULL OR NOT public.is_org_management(p_org_id) THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_CREATE_FORBIDDEN';
  END IF;

  IF p_gus IS NULL OR jsonb_typeof(p_gus) <> 'object' THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_GUS_PAYLOAD_REQUIRED';
  END IF;

  v_nip := regexp_replace(COALESCE(p_gus ->> 'nip', ''), '[^0-9]', '', 'g');
  v_regon := regexp_replace(COALESCE(p_gus ->> 'regon', ''), '[^0-9]', '', 'g');
  v_krs := NULLIF(regexp_replace(COALESCE(p_gus ->> 'krs', ''), '[^0-9]', '', 'g'), '');
  v_legal_name := NULLIF(btrim(COALESCE(p_gus ->> 'legalName', '')), '');
  v_short := NULLIF(btrim(COALESCE(p_short_name, '')), '');
  v_city := NULLIF(btrim(COALESCE(p_gus ->> 'city', '')), '');
  v_postal := public.normalize_pl_postal(p_gus ->> 'postalCode');
  v_street := NULLIF(btrim(COALESCE(p_gus ->> 'street', '')), '');
  v_building := NULLIF(btrim(COALESCE(p_gus ->> 'buildingNumber', '')), '');
  v_apt := NULLIF(btrim(COALESCE(p_gus ->> 'apartmentNumber', '')), '');
  v_voiv := NULLIF(btrim(COALESCE(p_gus ->> 'voivodeship', '')), '');
  v_county := NULLIF(btrim(COALESCE(p_gus ->> 'county', '')), '');
  v_commune := NULLIF(btrim(COALESCE(p_gus ->> 'commune', '')), '');

  IF v_short IS NULL THEN
    v_short := left(COALESCE(v_legal_name, ''), 80);
  END IF;

  IF v_voiv IS NULL THEN
    v_voiv := 'nieustalone';
  END IF;

  IF v_building IS NULL THEN
    v_building := 'b.n.';
  END IF;

  v_seat := NULLIF(btrim(COALESCE(p_gus ->> 'seatFullAddress', '')), '');
  IF v_seat IS NULL THEN
    v_seat := concat_ws(
      ', ',
      NULLIF(concat_ws(' ', v_street, v_building, v_apt), ''),
      NULLIF(concat_ws(' ', v_postal, v_city), '')
    );
  END IF;

  IF NOT public.nip_checksum_ok(v_nip)
     OR v_legal_name IS NULL
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
    gus_legal_form_code,
    gus_legal_form_name,
    gus_fetched_at,
    gus_payload,
    created_without_gus,
    created_by_org_id,
    updated_by
  )
  VALUES (
    p_kind,
    'active',
    v_nip,
    v_regon,
    v_krs,
    v_short,
    v_legal_name,
    v_voiv,
    v_county,
    v_commune,
    v_city,
    v_postal,
    v_street,
    v_building,
    v_apt,
    v_seat,
    btrim(p_email),
    btrim(p_phone),
    NULLIF(btrim(COALESCE(p_gus ->> 'legalFormCode', '')), ''),
    NULLIF(btrim(COALESCE(p_gus ->> 'legalFormName', '')), ''),
    now(),
    p_gus,
    false,
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
  PERFORM public.sync_legal_entity_legacy_overlay(v_row, p_org_id);

  RETURN jsonb_build_object(
    'status', 'created',
    'alreadyEnrolledInThisOrg', true,
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
    auth.uid()
  )
  RETURNING * INTO v_row;

  RETURN jsonb_build_object(
    'status', 'created_without_gus',
    'entity', public.legal_entity_public_json(v_row)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.enroll_building_for_legal_entity(
  p_org_id uuid,
  p_legal_entity_id uuid,
  p_google_place_id text,
  p_address text,
  p_latitude double precision,
  p_longitude double precision,
  p_module text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_place text;
  v_addr text;
  v_master public.locations%ROWTYPE;
  v_loc public.cleaning_locations%ROWTYPE;
  v_owner public.legal_entities%ROWTYPE;
  v_community_id uuid;
  v_city text;
  v_postal text;
  v_created boolean := false;
  v_already boolean := false;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_AUTH_REQUIRED';
  END IF;

  IF p_org_id IS NULL OR NOT public.is_org_management(p_org_id) THEN
    RAISE EXCEPTION 'BUILDING_ENROLL_FORBIDDEN';
  END IF;

  IF p_module IS NULL OR p_module NOT IN ('cleaning', 'maintenance', 'admin') THEN
    RAISE EXCEPTION 'BUILDING_MODULE_INVALID';
  END IF;

  v_place := NULLIF(btrim(COALESCE(p_google_place_id, '')), '');
  v_addr := NULLIF(btrim(COALESCE(p_address, '')), '');
  IF v_place IS NULL OR v_addr IS NULL THEN
    RAISE EXCEPTION 'BUILDING_ADDRESS_REQUIRED';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.org_legal_entity_enrollments e
    WHERE e.org_id = p_org_id
      AND e.legal_entity_id = p_legal_entity_id
      AND e.status = 'active'
  ) THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_NOT_ENROLLED';
  END IF;

  UPDATE public.org_legal_entity_enrollments
  SET
    is_cleaning = is_cleaning OR (p_module = 'cleaning'),
    is_maintenance = is_maintenance OR (p_module = 'maintenance'),
    is_admin = is_admin OR (p_module = 'admin')
  WHERE org_id = p_org_id
    AND legal_entity_id = p_legal_entity_id;

  SELECT * INTO v_master
  FROM public.locations
  WHERE google_place_id = v_place
  LIMIT 1;

  IF FOUND THEN
    IF v_master.legal_entity_id IS NOT NULL
       AND v_master.legal_entity_id IS DISTINCT FROM p_legal_entity_id THEN
      SELECT * INTO v_owner FROM public.legal_entities WHERE id = v_master.legal_entity_id;
      RAISE EXCEPTION 'ADDRESS_OWNED_BY_OTHER_ENTITY'
        USING DETAIL = jsonb_build_object(
          'ownerNip', v_owner.nip_normalized,
          'ownerName', v_owner.short_name
        )::text;
    END IF;

    IF v_master.legal_entity_id IS NULL THEN
      UPDATE public.locations
      SET legal_entity_id = p_legal_entity_id
      WHERE id = v_master.id
      RETURNING * INTO v_master;
    END IF;
  ELSE
    v_postal := (regexp_match(v_addr, '[0-9]{2}-[0-9]{3}'))[1];
    v_city := NULLIF(btrim(split_part(v_addr, ',', 2)), '');

    INSERT INTO public.locations (
      org_id,
      google_place_id,
      full_address,
      latitude,
      longitude,
      city,
      postal_code,
      legal_entity_id
    )
    VALUES (
      p_org_id,
      v_place,
      v_addr,
      p_latitude,
      p_longitude,
      v_city,
      v_postal,
      p_legal_entity_id
    )
    RETURNING * INTO v_master;
  END IF;

  SELECT c.id INTO v_community_id
  FROM public.communities c
  WHERE c.legal_entity_id = p_legal_entity_id
  LIMIT 1;

  SELECT * INTO v_loc
  FROM public.cleaning_locations
  WHERE org_id = p_org_id
    AND location_master_id = v_master.id
  LIMIT 1;

  IF FOUND THEN
    v_already :=
      (p_module = 'cleaning' AND v_loc.is_cleaning_active)
      OR (p_module = 'maintenance' AND v_loc.is_maintenance_active)
      OR (p_module = 'admin' AND v_loc.is_admin_active);

    UPDATE public.cleaning_locations
    SET
      is_cleaning_active = is_cleaning_active OR (p_module = 'cleaning'),
      is_maintenance_active = is_maintenance_active OR (p_module = 'maintenance'),
      is_admin_active = is_admin_active OR (p_module = 'admin'),
      community_id = COALESCE(community_id, v_community_id),
      status = 'active',
      address = v_addr,
      google_place_id = v_place,
      latitude = COALESCE(p_latitude, latitude),
      longitude = COALESCE(p_longitude, longitude)
    WHERE id = v_loc.id
    RETURNING * INTO v_loc;
  ELSE
    INSERT INTO public.cleaning_locations (
      org_id,
      location_master_id,
      address,
      google_place_id,
      latitude,
      longitude,
      status,
      is_cleaning_active,
      is_maintenance_active,
      is_admin_active,
      community_id
    )
    VALUES (
      p_org_id,
      v_master.id,
      v_addr,
      v_place,
      p_latitude,
      p_longitude,
      'active',
      p_module = 'cleaning',
      p_module = 'maintenance',
      p_module = 'admin',
      v_community_id
    )
    RETURNING * INTO v_loc;
    v_created := true;
  END IF;

  RETURN jsonb_build_object(
    'status', CASE
      WHEN v_already THEN 'duplicate'
      WHEN v_created THEN 'created'
      ELSE 'enrolled'
    END,
    'cleaningLocationId', v_loc.id,
    'locationMasterId', v_master.id,
    'address', v_loc.address
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.tg_legacy_identity_requires_legal_entity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.legal_entity_id IS NULL AND NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'LEGACY_IDENTITY_LEGAL_ENTITY_REQUIRED'
      USING HINT = 'Create the contractor via NIP lookup (legal_entities), not a direct insert.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_communities_require_legal_entity ON public.communities;
CREATE TRIGGER trg_communities_require_legal_entity
  BEFORE INSERT ON public.communities
  FOR EACH ROW
  EXECUTE FUNCTION public.tg_legacy_identity_requires_legal_entity();

DROP TRIGGER IF EXISTS trg_companies_require_legal_entity ON public.companies;
CREATE TRIGGER trg_companies_require_legal_entity
  BEFORE INSERT ON public.companies
  FOR EACH ROW
  EXECUTE FUNCTION public.tg_legacy_identity_requires_legal_entity();

REVOKE ALL ON FUNCTION public.normalize_pl_postal(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.legal_entity_public_json(public.legal_entities) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.enroll_legal_entity_for_org(uuid, uuid, boolean, boolean, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.sync_legal_entity_legacy_overlay(public.legal_entities, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_legal_entity_from_gus(uuid, public.legal_entity_kind, jsonb, text, text, text, boolean, boolean, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.platform_admin_create_legal_entity_without_gus(public.legal_entity_kind, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.enroll_building_for_legal_entity(uuid, uuid, text, text, double precision, double precision, text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.normalize_pl_postal(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.enroll_legal_entity_for_org(uuid, uuid, boolean, boolean, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_legal_entity_from_gus(uuid, public.legal_entity_kind, jsonb, text, text, text, boolean, boolean, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.platform_admin_create_legal_entity_without_gus(public.legal_entity_kind, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.enroll_building_for_legal_entity(uuid, uuid, text, text, double precision, double precision, text) TO authenticated;
