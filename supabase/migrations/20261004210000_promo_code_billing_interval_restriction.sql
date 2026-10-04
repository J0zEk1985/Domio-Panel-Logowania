BEGIN;

-- Dodanie kolumny allowed_billing_intervals do tabeli promo_codes
-- Określa czy kod może być użyty tylko do miesięcznych/rocznych/obu subskrypcji
ALTER TABLE public.promo_codes
  ADD COLUMN IF NOT EXISTS allowed_billing_intervals text[];

COMMENT ON COLUMN public.promo_codes.allowed_billing_intervals IS
  'Ograniczenie czasu trwania subskrypcji przy użyciu kodu. NULL = brak ograniczenia, [''monthly''] = tylko miesięczne, [''yearly''] = tylko roczne, [''monthly'',''yearly''] = oba.';

-- Aktualizacja funkcji preview_promo_code - dodanie sprawdzania allowed_billing_intervals
CREATE OR REPLACE FUNCTION public.preview_promo_code(p_code text, p_billing_interval text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.promo_codes%ROWTYPE;
  v_code text;
  v_interval text;
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

  -- Sprawdzenie ograniczenia okresu rozliczenia
  v_interval := lower(trim(COALESCE(p_billing_interval, '')));
  IF v_interval IN ('monthly', 'yearly')
     AND v_row.allowed_billing_intervals IS NOT NULL
     AND array_length(v_row.allowed_billing_intervals, 1) > 0 THEN
    IF NOT (v_interval = ANY(v_row.allowed_billing_intervals)) THEN
      RETURN jsonb_build_object('ok', false, 'error', 'INTERVAL_NOT_ALLOWED');
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'code', v_row.code,
    'discount_percent', v_row.discount_percent,
    'discount_amount', v_row.discount_amount,
    'allowed_billing_intervals', COALESCE(v_row.allowed_billing_intervals, '{}')
  );
END;
$$;

-- Aktualizacja funkcji redeem_promo_code - dodanie sprawdzania allowed_billing_intervals
CREATE OR REPLACE FUNCTION public.redeem_promo_code(p_code text, p_billing_interval text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.promo_codes%ROWTYPE;
  v_code text;
  v_interval text;
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

  -- Sprawdzenie ograniczenia okresu rozliczenia
  v_interval := lower(trim(COALESCE(p_billing_interval, '')));
  IF v_interval IN ('monthly', 'yearly')
     AND v_row.allowed_billing_intervals IS NOT NULL
     AND array_length(v_row.allowed_billing_intervals, 1) > 0 THEN
    IF NOT (v_interval = ANY(v_row.allowed_billing_intervals)) THEN
      RETURN jsonb_build_object('ok', false, 'error', 'INTERVAL_NOT_ALLOWED');
    END IF;
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
    'discount_amount', v_row.discount_amount,
    'allowed_billing_intervals', COALESCE(v_row.allowed_billing_intervals, '{}')
  );
END;
$$;

COMMIT;
