-- Overlay communities are per organisation (access codes stay tenant-local).
-- Enroll must create the overlay. Maintenance enroll sets Serwis flags.

DROP INDEX IF EXISTS public.communities_legal_entity_id_uidx;

CREATE UNIQUE INDEX communities_org_legal_entity_uidx
  ON public.communities (org_id, legal_entity_id)
  WHERE legal_entity_id IS NOT NULL;

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
      SELECT 1
      FROM public.communities c
      WHERE c.org_id = p_org_id
        AND c.legal_entity_id = p_entity.id
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
      SELECT 1
      FROM public.companies c
      WHERE c.legal_entity_id = p_entity.id
    );
  END IF;
END;
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

  PERFORM public.sync_legal_entity_legacy_overlay(v_row, p_org_id);

  RETURN jsonb_build_object(
    'status', 'enrolled',
    'enrollmentId', v_enroll.id,
    'alreadyEnrolledInThisOrg', true,
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
  v_entity uuid;
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
  v_entity := p_legal_entity_id;

  IF v_place IS NULL OR v_addr IS NULL THEN
    RAISE EXCEPTION 'BUILDING_ADDRESS_REQUIRED';
  END IF;

  IF v_entity IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1
      FROM public.org_legal_entity_enrollments e
      WHERE e.org_id = p_org_id
        AND e.legal_entity_id = v_entity
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
      AND legal_entity_id = v_entity;
  END IF;

  SELECT * INTO v_master
  FROM public.locations
  WHERE google_place_id = v_place
  LIMIT 1;

  IF FOUND THEN
    IF v_entity IS NOT NULL
       AND v_master.legal_entity_id IS NOT NULL
       AND v_master.legal_entity_id IS DISTINCT FROM v_entity THEN
      SELECT * INTO v_owner FROM public.legal_entities WHERE id = v_master.legal_entity_id;
      RAISE EXCEPTION 'ADDRESS_OWNED_BY_OTHER_ENTITY'
        USING DETAIL = jsonb_build_object(
          'ownerNip', v_owner.nip_normalized,
          'ownerName', v_owner.short_name
        )::text;
    END IF;

    IF v_entity IS NOT NULL AND v_master.legal_entity_id IS NULL THEN
      UPDATE public.locations
      SET legal_entity_id = v_entity
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
      v_entity
    )
    RETURNING * INTO v_master;
  END IF;

  IF v_entity IS NOT NULL THEN
    SELECT c.id INTO v_community_id
    FROM public.communities c
    WHERE c.legal_entity_id = v_entity
      AND c.org_id = p_org_id
    LIMIT 1;
  END IF;

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
      is_active_in_serwis = is_active_in_serwis OR (p_module = 'maintenance'),
      community_id = COALESCE(community_id, v_community_id),
      status = 'active',
      address = v_addr,
      google_place_id = v_place,
      place_id = COALESCE(place_id, v_place),
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
      place_id,
      latitude,
      longitude,
      status,
      is_cleaning_active,
      is_maintenance_active,
      is_admin_active,
      is_active_in_serwis,
      community_id
    )
    VALUES (
      p_org_id,
      v_master.id,
      v_addr,
      v_place,
      v_place,
      p_latitude,
      p_longitude,
      'active',
      p_module = 'cleaning',
      p_module = 'maintenance',
      p_module = 'admin',
      p_module = 'maintenance',
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
    'address', v_loc.address,
    'legalEntityId', v_master.legal_entity_id,
    'contractorRecommended', v_master.legal_entity_id IS NULL
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.attach_legal_entity_to_building(
  p_org_id uuid,
  p_cleaning_location_id uuid,
  p_legal_entity_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_loc public.cleaning_locations%ROWTYPE;
  v_master public.locations%ROWTYPE;
  v_owner public.legal_entities%ROWTYPE;
  v_community_id uuid;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_AUTH_REQUIRED';
  END IF;

  IF p_org_id IS NULL OR NOT public.is_org_management(p_org_id) THEN
    RAISE EXCEPTION 'BUILDING_ENROLL_FORBIDDEN';
  END IF;

  IF p_legal_entity_id IS NULL THEN
    RAISE EXCEPTION 'LEGAL_ENTITY_REQUIRED_FOR_ATTACH';
  END IF;

  SELECT * INTO v_loc
  FROM public.cleaning_locations
  WHERE id = p_cleaning_location_id
    AND org_id = p_org_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'BUILDING_NOT_FOUND';
  END IF;

  PERFORM public.enroll_legal_entity_for_org(p_org_id, p_legal_entity_id, false, false, false);

  IF v_loc.location_master_id IS NULL THEN
    RAISE EXCEPTION 'BUILDING_MASTER_MISSING';
  END IF;

  SELECT * INTO v_master
  FROM public.locations
  WHERE id = v_loc.location_master_id;

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

  SELECT c.id INTO v_community_id
  FROM public.communities c
  WHERE c.legal_entity_id = p_legal_entity_id
    AND c.org_id = p_org_id
  LIMIT 1;

  UPDATE public.cleaning_locations
  SET community_id = COALESCE(community_id, v_community_id)
  WHERE id = v_loc.id
  RETURNING * INTO v_loc;

  RETURN jsonb_build_object(
    'status', 'attached',
    'cleaningLocationId', v_loc.id,
    'locationMasterId', v_master.id,
    'legalEntityId', v_master.legal_entity_id
  );
END;
$$;
