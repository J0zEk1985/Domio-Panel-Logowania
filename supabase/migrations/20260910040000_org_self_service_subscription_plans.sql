-- Org billing managers can view, upgrade to a more expensive plan, or cancel.
-- Writes go through RPCs so cleaners cannot change subscriptions via the Data API.

ALTER TABLE public.org_subscriptions
  ADD COLUMN IF NOT EXISTS billing_interval text,
  ADD COLUMN IF NOT EXISTS cancelled_at timestamptz;

ALTER TABLE public.org_subscriptions
  DROP CONSTRAINT IF EXISTS org_subscriptions_billing_interval_check;

ALTER TABLE public.org_subscriptions
  ADD CONSTRAINT org_subscriptions_billing_interval_check
  CHECK (billing_interval IS NULL OR billing_interval IN ('monthly', 'yearly'));

COMMENT ON COLUMN public.org_subscriptions.billing_interval IS
  'monthly or yearly; used to compute expiry when the organisation activates a plan.';
COMMENT ON COLUMN public.org_subscriptions.cancelled_at IS
  'Set when the organisation cancels the subscription.';

DROP POLICY IF EXISTS "org_subscriptions_org_all" ON public.org_subscriptions;
DROP POLICY IF EXISTS org_subscriptions_org_select ON public.org_subscriptions;

CREATE POLICY org_subscriptions_org_select
  ON public.org_subscriptions
  FOR SELECT
  TO authenticated
  USING (public.is_org_member(org_id) OR public.is_platform_admin());

CREATE OR REPLACE FUNCTION public.activate_org_subscription_plan(
  p_org_id uuid,
  p_app_id uuid,
  p_plan_id uuid,
  p_billing_interval text
)
RETURNS public.org_subscriptions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_interval text;
  v_app public.applications%ROWTYPE;
  v_plan public.pricing_plans%ROWTYPE;
  v_existing public.org_subscriptions%ROWTYPE;
  v_current_plan public.pricing_plans%ROWTYPE;
  v_has_row boolean;
  v_existing_active boolean;
  v_expires timestamptz;
  v_row public.org_subscriptions%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Wymagane logowanie'
      USING ERRCODE = '42501';
  END IF;

  v_interval := lower(trim(COALESCE(p_billing_interval, '')));
  IF v_interval NOT IN ('monthly', 'yearly') THEN
    RAISE EXCEPTION 'Nieprawidłowy okres rozliczenia'
      USING ERRCODE = '22023';
  END IF;

  IF NOT (public.is_platform_admin() OR public.is_management_role(p_org_id)) THEN
    RAISE EXCEPTION 'Brak uprawnień do zarządzania planem organizacji'
      USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_app
  FROM public.applications
  WHERE id = p_app_id
  LIMIT 1;

  IF NOT FOUND OR COALESCE(v_app.is_active, true) = false THEN
    RAISE EXCEPTION 'Aplikacja jest niedostępna'
      USING ERRCODE = 'P0002';
  END IF;

  IF COALESCE(v_app.is_free, false) THEN
    RAISE EXCEPTION 'Moduł bezpłatny nie wymaga planu'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT * INTO v_plan
  FROM public.pricing_plans
  WHERE id = p_plan_id
    AND app_id = p_app_id
    AND is_active = true
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wybrany plan jest niedostępny'
      USING ERRCODE = 'P0002';
  END IF;

  SELECT * INTO v_existing
  FROM public.org_subscriptions
  WHERE org_id = p_org_id
    AND app_id = p_app_id
  FOR UPDATE;

  v_has_row := FOUND;
  v_existing_active := v_has_row
    AND lower(trim(COALESCE(v_existing.status, ''))) = 'active'
    AND (v_existing.expires_at IS NULL OR v_existing.expires_at > now());

  IF v_existing_active AND v_existing.plan_id IS NOT NULL THEN
    IF v_existing.plan_id = p_plan_id THEN
      RAISE EXCEPTION 'Ten plan jest już aktywny'
        USING ERRCODE = 'P0001';
    END IF;

    SELECT * INTO v_current_plan
    FROM public.pricing_plans
    WHERE id = v_existing.plan_id
    LIMIT 1;

    IF FOUND AND COALESCE(v_plan.price_monthly, 0) <= COALESCE(v_current_plan.price_monthly, 0) THEN
      RAISE EXCEPTION 'Możesz aktywować tylko droższy plan niż aktualny'
        USING ERRCODE = 'P0001';
    END IF;
  END IF;

  IF v_interval = 'yearly' THEN
    v_expires := now() + interval '1 year';
  ELSE
    v_expires := now() + interval '30 days';
  END IF;

  IF v_has_row THEN
    UPDATE public.org_subscriptions
    SET
      status = 'active',
      plan_id = p_plan_id,
      billing_interval = v_interval,
      expires_at = v_expires,
      cancelled_at = NULL
    WHERE id = v_existing.id
    RETURNING * INTO v_row;
  ELSE
    INSERT INTO public.org_subscriptions (
      org_id,
      app_id,
      status,
      plan_id,
      billing_interval,
      expires_at,
      cancelled_at
    )
    VALUES (
      p_org_id,
      p_app_id,
      'active',
      p_plan_id,
      v_interval,
      v_expires,
      NULL
    )
    RETURNING * INTO v_row;
  END IF;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_org_subscription(
  p_org_id uuid,
  p_app_id uuid
)
RETURNS public.org_subscriptions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing public.org_subscriptions%ROWTYPE;
  v_row public.org_subscriptions%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Wymagane logowanie'
      USING ERRCODE = '42501';
  END IF;

  IF NOT (public.is_platform_admin() OR public.is_management_role(p_org_id)) THEN
    RAISE EXCEPTION 'Brak uprawnień do zarządzania planem organizacji'
      USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_existing
  FROM public.org_subscriptions
  WHERE org_id = p_org_id
    AND app_id = p_app_id
  FOR UPDATE;

  IF NOT FOUND
     OR lower(trim(COALESCE(v_existing.status, ''))) <> 'active'
     OR (v_existing.expires_at IS NOT NULL AND v_existing.expires_at <= now()) THEN
    RAISE EXCEPTION 'Brak aktywnej subskrypcji do rezygnacji'
      USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.org_subscriptions
  SET
    status = 'cancelled',
    cancelled_at = now()
  WHERE id = v_existing.id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.activate_org_subscription_plan(uuid, uuid, uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.cancel_org_subscription(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.activate_org_subscription_plan(uuid, uuid, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_org_subscription(uuid, uuid) TO authenticated;
