-- Cleaning tickets are in-app only. Keep email ingest for serwis and administracja.

UPDATE public.org_inbound_mailboxes
SET is_enabled = false
WHERE module = 'cleaning'
  AND is_enabled = true;

CREATE OR REPLACE FUNCTION private.org_inbound_disable_cleaning_module()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public', 'private'
AS $$
BEGIN
  IF NEW.module = 'cleaning' THEN
    NEW.is_enabled := false;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS org_inbound_mailboxes_disable_cleaning ON public.org_inbound_mailboxes;
CREATE TRIGGER org_inbound_mailboxes_disable_cleaning
  BEFORE INSERT OR UPDATE ON public.org_inbound_mailboxes
  FOR EACH ROW
  EXECUTE FUNCTION private.org_inbound_disable_cleaning_module();

CREATE OR REPLACE FUNCTION public.ensure_org_inbound_mailboxes(p_org_id uuid)
RETURNS SETOF public.org_inbound_mailboxes
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private'
AS $$
DECLARE
  v_slug text;
  v_mod text;
  v_alias text;
BEGIN
  IF p_org_id IS NULL THEN
    RAISE EXCEPTION 'Brak organizacji.';
  END IF;

  IF NOT (SELECT public.is_platform_admin())
     AND NOT (SELECT public.is_org_management(p_org_id)) THEN
    RAISE EXCEPTION 'Brak uprawnień do konfiguracji skrzynek.';
  END IF;

  SELECT lower(regexp_replace(COALESCE(o.slug, ''), '[^a-z0-9]+', '', 'g'))
    INTO v_slug
  FROM public.organizations o
  WHERE o.id = p_org_id;

  IF v_slug IS NULL THEN
    RAISE EXCEPTION 'Nie znaleziono organizacji.';
  END IF;

  IF v_slug = '' OR length(v_slug) < 2 THEN
    v_slug := substr(replace(p_org_id::text, '-', ''), 1, 12);
  END IF;

  FOREACH v_mod IN ARRAY ARRAY['serwis', 'administracja'] LOOP
    v_alias := 'usterki+' || v_mod || '-' || v_slug;
    IF length(v_alias) > 64 THEN
      v_alias := left(v_alias, 64);
    END IF;
    BEGIN
      INSERT INTO public.org_inbound_mailboxes (org_id, module, alias_local_part)
      VALUES (p_org_id, v_mod, v_alias)
      ON CONFLICT (org_id, module) DO NOTHING;
    EXCEPTION
      WHEN unique_violation THEN
        INSERT INTO public.org_inbound_mailboxes (org_id, module, alias_local_part)
        VALUES (
          p_org_id,
          v_mod,
          left(
            'usterki+' || v_mod || '-' || v_slug || substr(replace(p_org_id::text, '-', ''), 1, 6),
            64
          )
        )
        ON CONFLICT (org_id, module) DO NOTHING;
    END;
  END LOOP;

  RETURN QUERY
  SELECT *
  FROM public.org_inbound_mailboxes
  WHERE org_id = p_org_id
    AND module IN ('serwis', 'administracja')
  ORDER BY module;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_org_inbound_mailbox_aliases(p_org_id uuid)
RETURNS SETOF public.org_inbound_mailboxes
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private'
AS $$
DECLARE
  v_slug text;
  v_mod text;
  v_alias text;
BEGIN
  IF p_org_id IS NULL THEN
    RAISE EXCEPTION 'Brak organizacji.';
  END IF;

  IF NOT (SELECT public.is_platform_admin())
     AND NOT (SELECT public.is_org_management(p_org_id)) THEN
    RAISE EXCEPTION 'Brak uprawnień do konfiguracji skrzynek.';
  END IF;

  SELECT lower(regexp_replace(COALESCE(o.slug, ''), '[^a-z0-9]+', '', 'g'))
    INTO v_slug
  FROM public.organizations o
  WHERE o.id = p_org_id;

  IF v_slug IS NULL THEN
    RAISE EXCEPTION 'Nie znaleziono organizacji.';
  END IF;

  IF v_slug = '' OR length(v_slug) < 2 THEN
    v_slug := substr(replace(p_org_id::text, '-', ''), 1, 12);
  END IF;

  FOREACH v_mod IN ARRAY ARRAY['serwis', 'administracja'] LOOP
    v_alias := 'usterki+' || v_mod || '-' || v_slug;
    IF length(v_alias) > 64 THEN
      v_alias := left(v_alias, 64);
    END IF;

    BEGIN
      UPDATE public.org_inbound_mailboxes
      SET alias_local_part = v_alias
      WHERE org_id = p_org_id
        AND module = v_mod
        AND alias_local_part IS DISTINCT FROM v_alias;
    EXCEPTION
      WHEN unique_violation THEN
        v_alias := left(
          'usterki+' || v_mod || '-' || v_slug || substr(replace(p_org_id::text, '-', ''), 1, 6),
          64
        );
        UPDATE public.org_inbound_mailboxes
        SET alias_local_part = v_alias
        WHERE org_id = p_org_id
          AND module = v_mod
          AND alias_local_part IS DISTINCT FROM v_alias;
    END;
  END LOOP;

  RETURN QUERY
  SELECT *
  FROM public.org_inbound_mailboxes
  WHERE org_id = p_org_id
    AND module IN ('serwis', 'administracja')
  ORDER BY module;
END;
$$;

CREATE OR REPLACE FUNCTION public.resolve_inbound_mailbox(p_to_address text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private'
AS $$
DECLARE
  v_alias text := private.inbound_normalize_alias(p_to_address);
  v_box public.org_inbound_mailboxes%ROWTYPE;
  v_limit integer;
  v_used integer;
  v_month date := private.inbound_month_start();
  v_looks boolean;
  v_enabled boolean;
  v_reject text;
BEGIN
  v_looks := private.inbound_looks_like_org_alias(v_alias);

  IF v_alias IS NULL THEN
    RETURN jsonb_build_object(
      'found', false,
      'looks_like_org_alias', false,
      'reject_reason', 'unrecognized_recipient'
    );
  END IF;

  SELECT * INTO v_box
  FROM public.org_inbound_mailboxes
  WHERE alias_local_part = v_alias
  LIMIT 1;

  IF v_box.id IS NULL THEN
    RETURN jsonb_build_object(
      'found', false,
      'alias_local_part', v_alias,
      'looks_like_org_alias', v_looks,
      'reject_reason', CASE WHEN v_looks THEN 'unknown_alias' ELSE 'unrecognized_recipient' END
    );
  END IF;

  IF v_box.module = 'cleaning' THEN
    v_enabled := false;
    v_reject := 'cleaning_app_only';
  ELSIF v_box.is_enabled THEN
    v_enabled := true;
    v_reject := NULL;
  ELSE
    v_enabled := false;
    v_reject := 'mailbox_disabled';
  END IF;

  v_limit := private.inbound_ai_monthly_limit(v_box.org_id);

  SELECT COALESCE(u.parse_count, 0)
    INTO v_used
  FROM public.org_ai_usage_monthly u
  WHERE u.org_id = v_box.org_id
    AND u.year_month = v_month;

  v_used := COALESCE(v_used, 0);

  RETURN jsonb_build_object(
    'found', true,
    'mailbox_id', v_box.id,
    'org_id', v_box.org_id,
    'module', v_box.module,
    'alias_local_part', v_box.alias_local_part,
    'ingest_mode', v_box.ingest_mode,
    'is_enabled', v_enabled,
    'auto_create_threshold', v_box.auto_create_threshold,
    'has_ai_auto', private.inbound_has_ai_auto(v_box.org_id),
    'ai_parses_limit', v_limit,
    'ai_parses_used', v_used,
    'ai_parses_remaining', GREATEST(v_limit - v_used, 0),
    'allow_ai_parse', (v_enabled AND GREATEST(v_limit - v_used, 0) > 0),
    'looks_like_org_alias', v_looks,
    'reject_reason', v_reject
  );
END;
$$;
