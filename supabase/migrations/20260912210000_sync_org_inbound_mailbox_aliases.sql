-- Keep inbound aliases in sync with organizations.slug after the owner edits company data.
-- Format stays OVH plus-addressing: usterki+{module}-{slug}@…

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

  FOREACH v_mod IN ARRAY ARRAY['serwis', 'cleaning', 'administracja'] LOOP
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
  ORDER BY module;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_org_inbound_mailbox_aliases(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sync_org_inbound_mailbox_aliases(uuid) TO authenticated;

-- Platform admin already edits orgs in /admin; SELECT-only policy was not enough to save.
DROP POLICY IF EXISTS organizations_update_platform_admin ON public.organizations;
CREATE POLICY organizations_update_platform_admin
  ON public.organizations
  FOR UPDATE
  TO authenticated
  USING ((SELECT public.is_platform_admin()))
  WITH CHECK ((SELECT public.is_platform_admin()));
