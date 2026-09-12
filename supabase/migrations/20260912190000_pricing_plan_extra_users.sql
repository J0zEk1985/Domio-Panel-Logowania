-- Extra billed seats per module plan.
-- Catalog: extra_user_price_monthly / extra_user_price_yearly on pricing_plans.
-- Entitlement: extra_users on org_subscriptions. Writes only via SECURITY DEFINER RPC
-- (column UPDATE revoked from authenticated). Org owner or platform admin may call it.

ALTER TABLE public.pricing_plans
  ADD COLUMN IF NOT EXISTS extra_user_price_monthly numeric(12, 2),
  ADD COLUMN IF NOT EXISTS extra_user_price_yearly numeric(12, 2);

ALTER TABLE public.pricing_plans
  DROP CONSTRAINT IF EXISTS pricing_plans_extra_user_price_monthly_chk,
  DROP CONSTRAINT IF EXISTS pricing_plans_extra_user_price_yearly_chk;

ALTER TABLE public.pricing_plans
  ADD CONSTRAINT pricing_plans_extra_user_price_monthly_chk
    CHECK (extra_user_price_monthly IS NULL OR extra_user_price_monthly >= 0),
  ADD CONSTRAINT pricing_plans_extra_user_price_yearly_chk
    CHECK (extra_user_price_yearly IS NULL OR extra_user_price_yearly >= 0);

COMMENT ON COLUMN public.pricing_plans.extra_user_price_monthly IS
  'Price in PLN for +1 user / month. NULL = extra seats cannot be purchased on monthly billing.';
COMMENT ON COLUMN public.pricing_plans.extra_user_price_yearly IS
  'Price in PLN for +1 user / year. NULL = extra seats cannot be purchased on yearly billing.';

ALTER TABLE public.org_subscriptions
  ADD COLUMN IF NOT EXISTS extra_users integer NOT NULL DEFAULT 0;

ALTER TABLE public.org_subscriptions
  DROP CONSTRAINT IF EXISTS org_subscriptions_extra_users_chk;

ALTER TABLE public.org_subscriptions
  ADD CONSTRAINT org_subscriptions_extra_users_chk
    CHECK (extra_users >= 0);

COMMENT ON COLUMN public.org_subscriptions.extra_users IS
  'Purchased extra user seats on top of pricing_plans.max_users. Mutated only via set_org_subscription_extra_users.';

REVOKE UPDATE ON TABLE public.org_subscriptions FROM anon, authenticated;
GRANT UPDATE (
  id,
  org_id,
  app_id,
  status,
  created_at,
  expires_at,
  plan_id,
  billing_interval,
  cancelled_at
) ON public.org_subscriptions TO authenticated;

CREATE OR REPLACE FUNCTION public.is_org_billing_owner(p_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.organizations o
    WHERE o.id = p_org_id
      AND o.owner_id = (SELECT auth.uid())
  )
  OR EXISTS (
    SELECT 1
    FROM public.memberships m
    WHERE m.org_id = p_org_id
      AND m.user_id = (SELECT auth.uid())
      AND COALESCE(m.is_active, true) = true
      AND m.role ILIKE ANY (ARRAY['owner', 'wlasciciel'])
  );
$$;

COMMENT ON FUNCTION public.is_org_billing_owner(uuid) IS
  'True when the current user is the organisation owner (membership role or organizations.owner_id).';

REVOKE ALL ON FUNCTION public.is_org_billing_owner(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_org_billing_owner(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.org_effective_user_limit(p_org_id uuid)
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_limit integer;
BEGIN
  IF p_org_id IS NULL THEN
    RETURN NULL;
  END IF;

  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'Wymagane logowanie'
      USING ERRCODE = '42501';
  END IF;

  IF NOT (public.is_platform_admin() OR public.is_org_member(p_org_id)) THEN
    RAISE EXCEPTION 'Brak uprawnień do podglądu limitu użytkowników'
      USING ERRCODE = '42501';
  END IF;

  SELECT MIN(pp.max_users + COALESCE(os.extra_users, 0))
    INTO v_limit
  FROM public.org_subscriptions os
  JOIN public.pricing_plans pp ON pp.id = os.plan_id
  WHERE os.org_id = p_org_id
    AND lower(trim(COALESCE(os.status, ''))) = 'active'
    AND (os.expires_at IS NULL OR os.expires_at > now())
    AND pp.max_users IS NOT NULL;

  RETURN v_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.org_effective_user_limit(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.org_effective_user_limit(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.enforce_membership_user_limit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  current_count integer;
  plan_limit integer;
BEGIN
  IF (SELECT public.is_platform_admin()) THEN
    RETURN NEW;
  END IF;

  PERFORM 1
  FROM public.org_subscriptions
  WHERE org_id = NEW.org_id
  FOR UPDATE;

  SELECT MIN(pp.max_users + COALESCE(os.extra_users, 0))
    INTO plan_limit
  FROM public.org_subscriptions os
  JOIN public.pricing_plans pp ON pp.id = os.plan_id
  WHERE os.org_id = NEW.org_id
    AND os.status = 'active'
    AND (os.expires_at IS NULL OR os.expires_at > now())
    AND pp.max_users IS NOT NULL;

  IF plan_limit IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT COUNT(*)::integer
    INTO current_count
  FROM public.memberships
  WHERE org_id = NEW.org_id;

  IF TG_OP = 'INSERT' AND current_count >= plan_limit THEN
    RAISE EXCEPTION 'Limit użytkowników planu (%) został osiągnięty dla tej organizacji', plan_limit
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_org_subscription_extra_users(
  p_org_id uuid,
  p_app_id uuid,
  p_extra_users integer
)
RETURNS public.org_subscriptions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_is_platform_admin boolean;
  v_existing public.org_subscriptions%ROWTYPE;
  v_plan public.pricing_plans%ROWTYPE;
  v_interval text;
  v_unit_price numeric;
  v_member_count integer;
  v_new_limit integer;
  v_row public.org_subscriptions%ROWTYPE;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'Wymagane logowanie'
      USING ERRCODE = '42501';
  END IF;

  IF p_extra_users IS NULL OR p_extra_users < 0 THEN
    RAISE EXCEPTION 'Liczba dodatkowych użytkowników musi być liczbą całkowitą ≥ 0'
      USING ERRCODE = '22023';
  END IF;

  v_is_platform_admin := public.is_platform_admin();

  IF NOT (v_is_platform_admin OR public.is_org_billing_owner(p_org_id)) THEN
    RAISE EXCEPTION 'Tylko właściciel firmy może dokupić dodatkowych użytkowników'
      USING ERRCODE = '42501';
  END IF;

  SELECT *
    INTO v_existing
  FROM public.org_subscriptions
  WHERE org_id = p_org_id
    AND app_id = p_app_id
  FOR UPDATE;

  IF NOT FOUND
     OR lower(trim(COALESCE(v_existing.status, ''))) <> 'active'
     OR (v_existing.expires_at IS NOT NULL AND v_existing.expires_at <= now()) THEN
    RAISE EXCEPTION 'Brak aktywnej subskrypcji tego modułu'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_existing.plan_id IS NULL THEN
    RAISE EXCEPTION 'Brak przypisanego planu — nie można dokupić użytkowników'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT *
    INTO v_plan
  FROM public.pricing_plans
  WHERE id = v_existing.plan_id
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Przypisany plan jest niedostępny'
      USING ERRCODE = 'P0002';
  END IF;

  IF p_extra_users > 0 AND v_plan.max_users IS NULL THEN
    RAISE EXCEPTION 'Ten plan nie ma limitu użytkowników, dodatkowe miejsca nie są dostępne'
      USING ERRCODE = 'P0001';
  END IF;

  v_interval := lower(trim(COALESCE(v_existing.billing_interval, 'monthly')));
  IF v_interval = 'yearly' THEN
    v_unit_price := v_plan.extra_user_price_yearly;
  ELSE
    v_unit_price := v_plan.extra_user_price_monthly;
  END IF;

  IF p_extra_users > 0 AND NOT v_is_platform_admin AND v_unit_price IS NULL THEN
    IF v_interval = 'yearly' THEN
      RAISE EXCEPTION 'Plan nie ma ceny dodatkowego użytkownika w rozliczeniu rocznym'
        USING ERRCODE = 'P0001';
    END IF;
    RAISE EXCEPTION 'Plan nie ma ceny dodatkowego użytkownika w rozliczeniu miesięcznym'
      USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.org_subscriptions
  SET extra_users = p_extra_users
  WHERE id = v_existing.id
  RETURNING * INTO v_row;

  SELECT MIN(pp.max_users + COALESCE(os.extra_users, 0))
    INTO v_new_limit
  FROM public.org_subscriptions os
  JOIN public.pricing_plans pp ON pp.id = os.plan_id
  WHERE os.org_id = p_org_id
    AND os.status = 'active'
    AND (os.expires_at IS NULL OR os.expires_at > now())
    AND pp.max_users IS NOT NULL;

  SELECT COUNT(*)::integer
    INTO v_member_count
  FROM public.memberships
  WHERE org_id = p_org_id;

  IF v_new_limit IS NOT NULL AND v_member_count > v_new_limit THEN
    RAISE EXCEPTION 'Nie można zmniejszyć liczby miejsc poniżej liczby użytkowników w organizacji (%)', v_member_count
      USING ERRCODE = 'P0001';
  END IF;

  RETURN v_row;
END;
$$;

COMMENT ON FUNCTION public.set_org_subscription_extra_users(uuid, uuid, integer) IS
  'Sets purchased extra user seats for an org module subscription. Owner or platform admin only.';

REVOKE ALL ON FUNCTION public.set_org_subscription_extra_users(uuid, uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_org_subscription_extra_users(uuid, uuid, integer) TO authenticated;
