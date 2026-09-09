-- Cleaning and Serwis may enroll an address without a legal entity
-- (e.g. a privately owned tenement). Attaching a contractor is recommended, not required.
-- At most one legal entity per physical address still holds when an entity IS attached.

COMMENT ON COLUMN public.locations.legal_entity_id IS
  'Optional canonical owner (wspólnota / spółdzielnia / firma). NULL is allowed for Cleaning/Serwis private addresses. When set, no other legal entity may own this google_place_id.';

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

  -- Admin still groups by contractor when one is chosen, but may also
  -- activate a building without an entity (same as Cleaning/Serwis).
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

    -- Do not clear an existing owner when enrolling without a contractor.
    -- Assign only when the caller provides an entity and the address is free.
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

REVOKE ALL ON FUNCTION public.attach_legal_entity_to_building(uuid, uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.attach_legal_entity_to_building(uuid, uuid, uuid) TO authenticated;

COMMENT ON FUNCTION public.enroll_building_for_legal_entity(uuid, uuid, text, text, double precision, double precision, text) IS
  'Enroll a building into a module. p_legal_entity_id may be NULL for Cleaning/Serwis private addresses.';

COMMENT ON FUNCTION public.attach_legal_entity_to_building(uuid, uuid, uuid) IS
  'Optional later attach of a contractor to an address that was created without one.';
