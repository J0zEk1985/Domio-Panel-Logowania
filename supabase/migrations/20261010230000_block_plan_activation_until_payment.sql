BEGIN;

-- Self-service plan activation stays closed until an online payment gateway exists.
-- A complimentary activation is allowed only with a 100% promo code, redeemed
-- in the same transaction as the subscription write.

DROP FUNCTION IF EXISTS public.activate_org_subscription_plan(uuid, uuid, uuid, text);

CREATE OR REPLACE FUNCTION public.activate_org_subscription_plan(
  p_org_id uuid,
  p_app_id uuid,
  p_plan_id uuid,
  p_billing_interval text,
  p_promo_code text DEFAULT NULL
)
RETURNS public.org_subscriptions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_interval text;
  v_code text;
  v_app public.applications%ROWTYPE;
  v_plan public.pricing_plans%ROWTYPE;
  v_promo public.promo_codes%ROWTYPE;
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

  v_code := upper(trim(COALESCE(p_promo_code, '')));
  IF v_code = '' THEN
    RAISE EXCEPTION 'Płatność online nie jest jeszcze dostępna. Plan można aktywować tylko kodem rabatowym 100%%.'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT * INTO v_promo
  FROM public.promo_codes
  WHERE upper(code) = v_code
  FOR UPDATE;

  IF NOT FOUND OR v_promo.is_active IS NOT TRUE THEN
    RAISE EXCEPTION 'Nieprawidłowy kod promocyjny.'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_promo.valid_until IS NOT NULL AND v_promo.valid_until < now() THEN
    RAISE EXCEPTION 'Ten kod promocyjny wygasł.'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_promo.max_uses IS NOT NULL AND COALESCE(v_promo.used_count, 0) >= v_promo.max_uses THEN
    RAISE EXCEPTION 'Ten kod promocyjny został już wykorzystany.'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_promo.allowed_billing_intervals IS NOT NULL
     AND array_length(v_promo.allowed_billing_intervals, 1) > 0
     AND NOT (v_interval = ANY (v_promo.allowed_billing_intervals)) THEN
    RAISE EXCEPTION 'Ten kod promocyjny nie może być użyty dla wybranego okresu rozliczenia.'
      USING ERRCODE = 'P0001';
  END IF;

  IF COALESCE(v_promo.discount_percent, 0) < 100 THEN
    RAISE EXCEPTION 'Płatność online nie jest jeszcze dostępna. Plan można aktywować tylko kodem rabatowym 100%%.'
      USING ERRCODE = 'P0001';
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

  UPDATE public.promo_codes
  SET used_count = COALESCE(used_count, 0) + 1
  WHERE id = v_promo.id
    AND (max_uses IS NULL OR COALESCE(used_count, 0) < max_uses);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ten kod promocyjny został już wykorzystany.'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.activate_org_subscription_plan(uuid, uuid, uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.activate_org_subscription_plan(uuid, uuid, uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.activate_org_subscription_plan(uuid, uuid, uuid, text, text) TO service_role;

COMMENT ON FUNCTION public.activate_org_subscription_plan(uuid, uuid, uuid, text, text) IS
  'Activates an organisation plan only when a 100 percent promo code is redeemed. Paid checkout stays closed until the payment gateway is live.';

NOTIFY pgrst, 'reload schema';

COMMIT;
