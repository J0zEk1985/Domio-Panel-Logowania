-- Client checkout: create billing org on first purchase, preview/redeem promo codes
-- without exposing the promo_codes table (admin-only RLS).

CREATE OR REPLACE FUNCTION public.preview_promo_code(p_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.promo_codes%ROWTYPE;
  v_code text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Wymagane logowanie'
      USING ERRCODE = '42501';
  END IF;

  v_code := upper(trim(COALESCE(p_code, '')));
  IF v_code = '' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'EMPTY');
  END IF;

  SELECT * INTO v_row
  FROM public.promo_codes
  WHERE upper(code) = v_code
  LIMIT 1;

  IF NOT FOUND OR v_row.is_active IS NOT TRUE THEN
    RETURN jsonb_build_object('ok', false, 'error', 'INVALID');
  END IF;

  IF v_row.valid_until IS NOT NULL AND v_row.valid_until < now() THEN
    RETURN jsonb_build_object('ok', false, 'error', 'EXPIRED');
  END IF;

  IF v_row.max_uses IS NOT NULL AND COALESCE(v_row.used_count, 0) >= v_row.max_uses THEN
    RETURN jsonb_build_object('ok', false, 'error', 'LIMIT');
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'code', v_row.code,
    'discount_percent', v_row.discount_percent,
    'discount_amount', v_row.discount_amount
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.redeem_promo_code(p_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.promo_codes%ROWTYPE;
  v_code text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Wymagane logowanie'
      USING ERRCODE = '42501';
  END IF;

  v_code := upper(trim(COALESCE(p_code, '')));
  IF v_code = '' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'EMPTY');
  END IF;

  SELECT * INTO v_row
  FROM public.promo_codes
  WHERE upper(code) = v_code
  FOR UPDATE;

  IF NOT FOUND OR v_row.is_active IS NOT TRUE THEN
    RETURN jsonb_build_object('ok', false, 'error', 'INVALID');
  END IF;

  IF v_row.valid_until IS NOT NULL AND v_row.valid_until < now() THEN
    RETURN jsonb_build_object('ok', false, 'error', 'EXPIRED');
  END IF;

  IF v_row.max_uses IS NOT NULL AND COALESCE(v_row.used_count, 0) >= v_row.max_uses THEN
    RETURN jsonb_build_object('ok', false, 'error', 'LIMIT');
  END IF;

  UPDATE public.promo_codes
  SET used_count = COALESCE(used_count, 0) + 1
  WHERE id = v_row.id
    AND (max_uses IS NULL OR COALESCE(used_count, 0) < max_uses)
  RETURNING * INTO v_row;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'LIMIT');
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'code', v_row.code,
    'discount_percent', v_row.discount_percent,
    'discount_amount', v_row.discount_amount
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.ensure_my_billing_organization(
  p_name text,
  p_nip text DEFAULT NULL,
  p_address text DEFAULT NULL,
  p_city text DEFAULT NULL,
  p_postal_code text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid;
  v_org_id uuid;
  v_name text;
  v_nip text;
  v_slug text;
  v_base_slug text;
  v_attempt integer := 0;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Wymagane logowanie'
      USING ERRCODE = '42501';
  END IF;

  v_name := trim(COALESCE(p_name, ''));
  IF v_name = '' THEN
    RAISE EXCEPTION 'Nazwa firmy jest wymagana'
      USING ERRCODE = '22023';
  END IF;

  v_nip := regexp_replace(trim(COALESCE(p_nip, '')), '\s+', '', 'g');
  IF v_nip = '' THEN
    v_nip := NULL;
  ELSIF v_nip !~ '^[0-9]{10}$' THEN
    RAISE EXCEPTION 'NIP musi składać się z 10 cyfr'
      USING ERRCODE = '22023';
  END IF;

  SELECT m.org_id
    INTO v_org_id
  FROM public.memberships m
  WHERE m.user_id = v_uid
    AND COALESCE(m.is_active, true) = true
  ORDER BY
    CASE
      WHEN lower(trim(m.role)) IN ('owner', 'wlasciciel', 'admin', 'coordinator') THEN 0
      ELSE 1
    END,
    m.created_at NULLS LAST
  LIMIT 1;

  IF v_org_id IS NOT NULL THEN
    IF public.is_platform_admin() OR public.is_management_role(v_org_id) OR public.is_org_management(v_org_id) THEN
      UPDATE public.organizations
      SET
        name = CASE WHEN NULLIF(trim(COALESCE(name, '')), '') IS NULL THEN v_name ELSE name END,
        nip = COALESCE(v_nip, nip),
        address = COALESCE(NULLIF(trim(COALESCE(p_address, '')), ''), address),
        city = COALESCE(NULLIF(trim(COALESCE(p_city, '')), ''), city),
        postal_code = COALESCE(NULLIF(trim(COALESCE(p_postal_code, '')), ''), postal_code)
      WHERE id = v_org_id;
    END IF;
    RETURN v_org_id;
  END IF;

  v_slug := lower(v_name);
  v_slug := translate(v_slug, 'ąćęłńóśźżĄĆĘŁŃÓŚŹŻ', 'acelnoszzacelnoszz');
  v_slug := regexp_replace(v_slug, '[^a-z0-9]', '', 'g');
  v_slug := left(v_slug, 40);
  IF length(v_slug) < 2 THEN
    v_slug := 'firma' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
  END IF;
  v_base_slug := v_slug;

  LOOP
    BEGIN
      INSERT INTO public.organizations (name, slug, nip, address, city, postal_code, owner_id)
      VALUES (
        v_name,
        v_slug,
        v_nip,
        NULLIF(trim(COALESCE(p_address, '')), ''),
        NULLIF(trim(COALESCE(p_city, '')), ''),
        NULLIF(trim(COALESCE(p_postal_code, '')), ''),
        v_uid
      )
      RETURNING id INTO v_org_id;
      EXIT;
    EXCEPTION
      WHEN unique_violation THEN
        v_attempt := v_attempt + 1;
        IF v_attempt > 8 THEN
          RAISE EXCEPTION 'Nie udało się utworzyć unikalnego identyfikatora firmy'
            USING ERRCODE = '23505';
        END IF;
        v_slug := left(v_base_slug, 32) || v_attempt::text;
    END;
  END LOOP;

  INSERT INTO public.memberships (user_id, org_id, role)
  VALUES (v_uid, v_org_id, 'owner');

  RETURN v_org_id;
END;
$$;

REVOKE ALL ON FUNCTION public.preview_promo_code(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.redeem_promo_code(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.ensure_my_billing_organization(text, text, text, text, text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.preview_promo_code(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.redeem_promo_code(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_my_billing_organization(text, text, text, text, text) TO authenticated;
