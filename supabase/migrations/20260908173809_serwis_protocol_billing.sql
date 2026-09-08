-- Serwis protocol numbering, billing snapshot, org rates, on-call/urgent surcharge.
-- Layers 1–3: schema, RLS, triggers, RPCs. Protocol format: 0001/2026/{ORGCODE}.

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_serwis_dispatcher_or_owner(target_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.memberships
    WHERE org_id = target_org_id
      AND user_id = auth.uid()
      AND role IN (
        'owner',
        'wlasciciel',
        'admin',
        'administrator',
        'manager',
        'coordinator',
        'koordynator'
      )
  );
$$;

COMMENT ON FUNCTION public.is_serwis_dispatcher_or_owner(uuid) IS
  'True when the current user is a Serwis dispatcher or owner in the given org.';

REVOKE ALL ON FUNCTION public.is_serwis_dispatcher_or_owner(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_serwis_dispatcher_or_owner(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.ceil_started_hours(p_hours numeric)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT CASE
    WHEN p_hours IS NULL THEN NULL
    WHEN p_hours <= 0 THEN 0
    ELSE CEIL(p_hours)
  END;
$$;

COMMENT ON FUNCTION public.ceil_started_hours(numeric) IS
  'Every started hour counts as a full hour: 0.25 -> 1, 1.25 -> 2.';

REVOKE ALL ON FUNCTION public.ceil_started_hours(numeric) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.suggested_labor_hours_from_range(
  p_started_at timestamptz,
  p_ended_at timestamptz
)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT CASE
    WHEN p_started_at IS NULL OR p_ended_at IS NULL THEN NULL
    WHEN p_ended_at <= p_started_at THEN 0
    ELSE public.ceil_started_hours(
      EXTRACT(EPOCH FROM (p_ended_at - p_started_at)) / 3600.0
    )
  END;
$$;

REVOKE ALL ON FUNCTION public.suggested_labor_hours_from_range(timestamptz, timestamptz) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.materials_used_total(p_materials jsonb)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT COALESCE(
    (
      SELECT ROUND(SUM(
        COALESCE((item ->> 'quantity')::numeric, 0)
        * COALESCE((item ->> 'unit_cost')::numeric, 0)
      ), 2)
      FROM jsonb_array_elements(
        CASE WHEN jsonb_typeof(p_materials) = 'array' THEN p_materials ELSE '[]'::jsonb END
      ) AS item
    ),
    0
  );
$$;

REVOKE ALL ON FUNCTION public.materials_used_total(jsonb) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.suggested_invoice_amount(
  p_material_cost numeric,
  p_labor_cost numeric,
  p_surcharge_amount numeric
)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT ROUND(
    COALESCE(p_material_cost, 0)
    + COALESCE(p_labor_cost, 0)
    + COALESCE(p_surcharge_amount, 0),
    2
  );
$$;

REVOKE ALL ON FUNCTION public.suggested_invoice_amount(numeric, numeric, numeric) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.normalize_protocol_org_code(p_raw text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
AS $$
DECLARE
  v text;
BEGIN
  v := upper(regexp_replace(COALESCE(p_raw, ''), '[^a-zA-Z0-9]', '', 'g'));
  IF length(v) > 12 THEN
    v := left(v, 12);
  END IF;
  IF length(v) < 2 THEN
    v := rpad(v, 2, 'X');
  END IF;
  RETURN v;
END;
$$;

REVOKE ALL ON FUNCTION public.normalize_protocol_org_code(text) FROM PUBLIC;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.org_serwis_billing_settings (
  org_id uuid PRIMARY KEY REFERENCES public.organizations(id) ON DELETE CASCADE,
  default_hourly_rate numeric(10,2) NOT NULL DEFAULT 0
    CHECK (default_hourly_rate >= 0),
  on_call_surcharge numeric(10,2) NOT NULL DEFAULT 0
    CHECK (on_call_surcharge >= 0),
  urgent_surcharge numeric(10,2) NOT NULL DEFAULT 0
    CHECK (urgent_surcharge >= 0),
  protocol_org_code text NOT NULL
    CHECK (protocol_org_code ~ '^[A-Z0-9]{2,12}$'),
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES public.profiles(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS org_serwis_billing_settings_protocol_org_code_uidx
  ON public.org_serwis_billing_settings (protocol_org_code);

COMMENT ON TABLE public.org_serwis_billing_settings IS
  'Per-org Serwis rates and protocol distinguisher (KSeF / protocol number suffix).';

CREATE TABLE IF NOT EXISTS public.org_serwis_protocol_counters (
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  year integer NOT NULL CHECK (year >= 2020 AND year <= 2100),
  last_number integer NOT NULL DEFAULT 0 CHECK (last_number >= 0),
  PRIMARY KEY (org_id, year)
);

COMMENT ON TABLE public.org_serwis_protocol_counters IS
  'Yearly protocol sequence per organization. Written only by SECURITY DEFINER helpers.';

CREATE TABLE IF NOT EXISTS public.property_issue_billing (
  issue_id uuid PRIMARY KEY REFERENCES public.property_issues(id) ON DELETE CASCADE,
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  invoice_amount numeric(12,2)
    CHECK (invoice_amount IS NULL OR invoice_amount >= 0),
  original jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now(),
  captured_by uuid REFERENCES public.profiles(id),
  adjusted_at timestamptz,
  adjusted_by uuid REFERENCES public.profiles(id)
);

CREATE INDEX IF NOT EXISTS property_issue_billing_org_id_idx
  ON public.property_issue_billing (org_id);

COMMENT ON TABLE public.property_issue_billing IS
  'Invoice amount and frozen original financials. Dispatcher/owner only.';

ALTER TABLE public.property_issues
  ADD COLUMN IF NOT EXISTS protocol_number text,
  ADD COLUMN IF NOT EXISTS surcharge_kind text,
  ADD COLUMN IF NOT EXISTS surcharge_amount numeric(12,2),
  ADD COLUMN IF NOT EXISTS hourly_rate_applied numeric(10,2);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'property_issues_surcharge_kind_check'
      AND conrelid = 'public.property_issues'::regclass
  ) THEN
    ALTER TABLE public.property_issues
      ADD CONSTRAINT property_issues_surcharge_kind_check
      CHECK (surcharge_kind IS NULL OR surcharge_kind IN ('on_call', 'urgent'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'property_issues_surcharge_amount_check'
      AND conrelid = 'public.property_issues'::regclass
  ) THEN
    ALTER TABLE public.property_issues
      ADD CONSTRAINT property_issues_surcharge_amount_check
      CHECK (surcharge_amount IS NULL OR surcharge_amount >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'property_issues_hourly_rate_applied_check'
      AND conrelid = 'public.property_issues'::regclass
  ) THEN
    ALTER TABLE public.property_issues
      ADD CONSTRAINT property_issues_hourly_rate_applied_check
      CHECK (hourly_rate_applied IS NULL OR hourly_rate_applied >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'property_issues_protocol_number_format_check'
      AND conrelid = 'public.property_issues'::regclass
  ) THEN
    ALTER TABLE public.property_issues
      ADD CONSTRAINT property_issues_protocol_number_format_check
      CHECK (
        protocol_number IS NULL
        OR protocol_number ~ '^[0-9]{4,}/[0-9]{4}/[A-Z0-9]{2,12}$'
      );
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS property_issues_org_protocol_number_uidx
  ON public.property_issues (org_id, protocol_number)
  WHERE protocol_number IS NOT NULL;

COMMENT ON COLUMN public.property_issues.protocol_number IS
  'Immutable protocol id, format NNNN/YYYY/ORGCODE, unique per organization.';
COMMENT ON COLUMN public.property_issues.surcharge_kind IS
  'Optional billing surcharge: on_call, urgent, or null (standard).';
COMMENT ON COLUMN public.property_issues.surcharge_amount IS
  'Extra compensation for on-call or urgent dispatch.';
COMMENT ON COLUMN public.property_issues.hourly_rate_applied IS
  'Hourly rate used when suggesting labor_cost.';

-- ---------------------------------------------------------------------------
-- Settings + protocol number internals
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.ensure_org_serwis_billing_settings(p_org_id uuid)
RETURNS public.org_serwis_billing_settings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.org_serwis_billing_settings;
  v_slug text;
  v_base text;
  v_code text;
  v_i integer := 0;
  v_suffix text;
BEGIN
  SELECT * INTO v_row
  FROM public.org_serwis_billing_settings
  WHERE org_id = p_org_id;

  IF FOUND THEN
    RETURN v_row;
  END IF;

  SELECT slug INTO v_slug
  FROM public.organizations
  WHERE id = p_org_id;

  IF v_slug IS NULL THEN
    RAISE EXCEPTION 'ISSUE_PROTOCOL_ORG_REQUIRED';
  END IF;

  v_base := public.normalize_protocol_org_code(v_slug);
  v_code := v_base;

  WHILE EXISTS (
    SELECT 1
    FROM public.org_serwis_billing_settings s
    WHERE s.protocol_org_code = v_code
  )
  LOOP
    v_i := v_i + 1;
    IF v_i > 99 THEN
      RAISE EXCEPTION 'PROTOCOL_ORG_CODE_TAKEN';
    END IF;
    v_suffix := v_i::text;
    v_code := left(v_base, GREATEST(2, 12 - length(v_suffix))) || v_suffix;
  END LOOP;

  INSERT INTO public.org_serwis_billing_settings (
    org_id,
    protocol_org_code
  )
  VALUES (p_org_id, v_code)
  ON CONFLICT (org_id) DO UPDATE
    SET protocol_org_code = public.org_serwis_billing_settings.protocol_org_code
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_org_serwis_billing_settings(uuid) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.assign_next_protocol_number(
  p_org_id uuid,
  p_at timestamptz
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_year integer;
  v_code text;
  v_next integer;
  v_settings public.org_serwis_billing_settings;
BEGIN
  IF p_org_id IS NULL THEN
    RAISE EXCEPTION 'ISSUE_PROTOCOL_ORG_REQUIRED';
  END IF;

  v_settings := public.ensure_org_serwis_billing_settings(p_org_id);
  v_code := v_settings.protocol_org_code;
  v_year := EXTRACT(YEAR FROM timezone('Europe/Warsaw', COALESCE(p_at, now())))::integer;

  INSERT INTO public.org_serwis_protocol_counters (org_id, year, last_number)
  VALUES (p_org_id, v_year, 1)
  ON CONFLICT (org_id, year) DO UPDATE
    SET last_number = public.org_serwis_protocol_counters.last_number + 1
  RETURNING last_number INTO v_next;

  RETURN lpad(v_next::text, 4, '0') || '/' || v_year::text || '/' || v_code;
END;
$$;

REVOKE ALL ON FUNCTION public.assign_next_protocol_number(uuid, timestamptz) FROM PUBLIC;

-- ---------------------------------------------------------------------------
-- Billing snapshot + column guards
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.capture_property_issue_billing()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_invoice numeric;
BEGIN
  IF NEW.status IS DISTINCT FROM 'resolved' THEN
    RETURN NEW;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.property_issue_billing b WHERE b.issue_id = NEW.id
  ) THEN
    RETURN NEW;
  END IF;

  v_invoice := public.suggested_invoice_amount(
    NEW.total_material_cost,
    NEW.labor_cost,
    NEW.surcharge_amount
  );

  INSERT INTO public.property_issue_billing (
    issue_id,
    org_id,
    invoice_amount,
    original,
    captured_at,
    captured_by
  )
  VALUES (
    NEW.id,
    NEW.org_id,
    v_invoice,
    jsonb_build_object(
      'labor_hours', NEW.labor_hours,
      'labor_cost', NEW.labor_cost,
      'hourly_rate_applied', NEW.hourly_rate_applied,
      'materials_used', COALESCE(NEW.materials_used, '[]'::jsonb),
      'total_material_cost', COALESCE(NEW.total_material_cost, 0),
      'surcharge_amount', NEW.surcharge_amount,
      'surcharge_kind', NEW.surcharge_kind,
      'invoice_amount', v_invoice
    ),
    now(),
    auth.uid()
  )
  ON CONFLICT (issue_id) DO NOTHING;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.capture_property_issue_billing() FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.enforce_property_issue_billing()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_settings public.org_serwis_billing_settings;
  v_mgmt boolean;
  v_tech boolean;
  v_resolving boolean;
  v_financial_changed boolean;
BEGIN
  v_mgmt := NEW.org_id IS NOT NULL AND public.is_serwis_dispatcher_or_owner(NEW.org_id);
  v_tech := NEW.org_id IS NOT NULL AND public.is_serwis_technician_role(NEW.org_id);
  v_resolving := NEW.status = 'resolved' AND OLD.status IS DISTINCT FROM 'resolved';

  v_financial_changed :=
    NEW.labor_hours IS DISTINCT FROM OLD.labor_hours
    OR NEW.labor_cost IS DISTINCT FROM OLD.labor_cost
    OR NEW.materials_used IS DISTINCT FROM OLD.materials_used
    OR NEW.total_material_cost IS DISTINCT FROM OLD.total_material_cost
    OR NEW.surcharge_kind IS DISTINCT FROM OLD.surcharge_kind
    OR NEW.surcharge_amount IS DISTINCT FROM OLD.surcharge_amount
    OR NEW.hourly_rate_applied IS DISTINCT FROM OLD.hourly_rate_applied;

  IF OLD.is_invoiced IS TRUE AND v_financial_changed THEN
    RAISE EXCEPTION 'ISSUE_BILLING_LOCKED'
      USING HINT = 'Financial fields cannot change after the issue is invoiced.';
  END IF;

  IF OLD.protocol_number IS NOT NULL THEN
    NEW.protocol_number := OLD.protocol_number;
  ELSIF NEW.status = 'resolved' AND NEW.protocol_number IS NULL AND NEW.org_id IS NOT NULL THEN
    NEW.protocol_number := public.assign_next_protocol_number(
      NEW.org_id,
      COALESCE(NEW.resolved_at, now())
    );
  ELSIF NEW.status IS DISTINCT FROM 'resolved' THEN
    NEW.protocol_number := NULL;
  END IF;

  IF NEW.surcharge_kind IS NULL THEN
    IF NOT v_mgmt THEN
      NEW.surcharge_amount := COALESCE(NEW.surcharge_amount, 0);
    END IF;
  END IF;

  IF v_resolving THEN
    v_settings := public.ensure_org_serwis_billing_settings(NEW.org_id);
    NEW.hourly_rate_applied := COALESCE(NEW.hourly_rate_applied, v_settings.default_hourly_rate);

    IF NEW.labor_hours IS NULL THEN
      NEW.labor_hours := public.suggested_labor_hours_from_range(
        NEW.started_at,
        COALESCE(NEW.resolved_at, now())
      );
    ELSE
      NEW.labor_hours := public.ceil_started_hours(NEW.labor_hours);
    END IF;

    IF NEW.surcharge_kind = 'on_call' THEN
      NEW.surcharge_amount := COALESCE(NEW.surcharge_amount, v_settings.on_call_surcharge);
    ELSIF NEW.surcharge_kind = 'urgent' THEN
      NEW.surcharge_amount := COALESCE(NEW.surcharge_amount, v_settings.urgent_surcharge);
    ELSE
      NEW.surcharge_amount := COALESCE(NEW.surcharge_amount, 0);
    END IF;

    IF NEW.labor_cost IS NULL OR NEW.labor_cost = 0 THEN
      NEW.labor_cost := ROUND(
        COALESCE(NEW.labor_hours, 0) * COALESCE(NEW.hourly_rate_applied, 0),
        2
      );
    END IF;

    NEW.total_material_cost := public.materials_used_total(NEW.materials_used);
    NEW.resolved_at := COALESCE(NEW.resolved_at, now());
  ELSIF NEW.labor_hours IS NOT NULL AND NEW.labor_hours IS DISTINCT FROM OLD.labor_hours THEN
    NEW.labor_hours := public.ceil_started_hours(NEW.labor_hours);
  END IF;

  IF NOT v_mgmt AND v_tech AND NEW.protocol_number IS DISTINCT FROM OLD.protocol_number
     AND OLD.protocol_number IS NOT NULL THEN
    RAISE EXCEPTION 'ISSUE_PROTOCOL_LOCKED';
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_property_issue_billing() FROM PUBLIC;

DROP TRIGGER IF EXISTS trg_property_issue_billing_guard ON public.property_issues;
CREATE TRIGGER trg_property_issue_billing_guard
  BEFORE UPDATE ON public.property_issues
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_property_issue_billing();

DROP TRIGGER IF EXISTS trg_property_issue_billing_capture ON public.property_issues;
CREATE TRIGGER trg_property_issue_billing_capture
  AFTER UPDATE ON public.property_issues
  FOR EACH ROW
  EXECUTE FUNCTION public.capture_property_issue_billing();

CREATE OR REPLACE FUNCTION public.enforce_property_issue_billing_row()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_invoiced boolean;
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF NEW.issue_id IS DISTINCT FROM OLD.issue_id
       OR NEW.org_id IS DISTINCT FROM OLD.org_id
       OR NEW.original IS DISTINCT FROM OLD.original
       OR NEW.captured_at IS DISTINCT FROM OLD.captured_at
       OR NEW.captured_by IS DISTINCT FROM OLD.captured_by THEN
      RAISE EXCEPTION 'ISSUE_BILLING_ORIGINAL_LOCKED';
    END IF;

    SELECT COALESCE(is_invoiced, false) INTO v_invoiced
    FROM public.property_issues
    WHERE id = NEW.issue_id;

    IF v_invoiced THEN
      RAISE EXCEPTION 'ISSUE_BILLING_LOCKED';
    END IF;

    IF NEW.invoice_amount IS DISTINCT FROM OLD.invoice_amount THEN
      NEW.adjusted_at := now();
      NEW.adjusted_by := auth.uid();
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_property_issue_billing_row() FROM PUBLIC;

DROP TRIGGER IF EXISTS trg_property_issue_billing_row_guard ON public.property_issue_billing;
CREATE TRIGGER trg_property_issue_billing_row_guard
  BEFORE UPDATE ON public.property_issue_billing
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_property_issue_billing_row();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE public.org_serwis_billing_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.org_serwis_protocol_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_issue_billing ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS org_serwis_billing_settings_select ON public.org_serwis_billing_settings;
CREATE POLICY org_serwis_billing_settings_select
  ON public.org_serwis_billing_settings
  FOR SELECT
  TO authenticated
  USING (
    public.is_serwis_dispatcher_or_owner(org_id)
    OR public.is_serwis_technician_role(org_id)
  );

DROP POLICY IF EXISTS org_serwis_billing_settings_insert ON public.org_serwis_billing_settings;
CREATE POLICY org_serwis_billing_settings_insert
  ON public.org_serwis_billing_settings
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_serwis_dispatcher_or_owner(org_id));

DROP POLICY IF EXISTS org_serwis_billing_settings_update ON public.org_serwis_billing_settings;
CREATE POLICY org_serwis_billing_settings_update
  ON public.org_serwis_billing_settings
  FOR UPDATE
  TO authenticated
  USING (public.is_serwis_dispatcher_or_owner(org_id))
  WITH CHECK (public.is_serwis_dispatcher_or_owner(org_id));

DROP POLICY IF EXISTS property_issue_billing_select ON public.property_issue_billing;
CREATE POLICY property_issue_billing_select
  ON public.property_issue_billing
  FOR SELECT
  TO authenticated
  USING (public.is_serwis_dispatcher_or_owner(org_id));

DROP POLICY IF EXISTS property_issue_billing_update ON public.property_issue_billing;
CREATE POLICY property_issue_billing_update
  ON public.property_issue_billing
  FOR UPDATE
  TO authenticated
  USING (public.is_serwis_dispatcher_or_owner(org_id))
  WITH CHECK (public.is_serwis_dispatcher_or_owner(org_id));

REVOKE ALL ON TABLE public.org_serwis_protocol_counters FROM PUBLIC;
REVOKE ALL ON TABLE public.org_serwis_protocol_counters FROM anon, authenticated;

GRANT SELECT, INSERT, UPDATE ON TABLE public.org_serwis_billing_settings TO authenticated;
GRANT SELECT, UPDATE ON TABLE public.property_issue_billing TO authenticated;
GRANT ALL ON TABLE public.org_serwis_billing_settings TO service_role;
GRANT ALL ON TABLE public.org_serwis_protocol_counters TO service_role;
GRANT ALL ON TABLE public.property_issue_billing TO service_role;

-- ---------------------------------------------------------------------------
-- Client RPCs
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_org_serwis_billing_settings(p_org_id uuid)
RETURNS public.org_serwis_billing_settings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'ISSUE_AUTH_REQUIRED';
  END IF;
  IF p_org_id IS NULL THEN
    RAISE EXCEPTION 'ISSUE_PROTOCOL_ORG_REQUIRED';
  END IF;
  IF NOT (
    public.is_serwis_dispatcher_or_owner(p_org_id)
    OR public.is_serwis_technician_role(p_org_id)
  ) THEN
    RAISE EXCEPTION 'ISSUE_BILLING_FORBIDDEN';
  END IF;

  RETURN public.ensure_org_serwis_billing_settings(p_org_id);
END;
$$;

REVOKE ALL ON FUNCTION public.get_org_serwis_billing_settings(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_org_serwis_billing_settings(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.upsert_org_serwis_billing_settings(
  p_org_id uuid,
  p_default_hourly_rate numeric,
  p_on_call_surcharge numeric,
  p_urgent_surcharge numeric,
  p_protocol_org_code text
)
RETURNS public.org_serwis_billing_settings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_code text;
  v_row public.org_serwis_billing_settings;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'ISSUE_AUTH_REQUIRED';
  END IF;
  IF p_org_id IS NULL OR NOT public.is_serwis_dispatcher_or_owner(p_org_id) THEN
    RAISE EXCEPTION 'ISSUE_BILLING_FORBIDDEN';
  END IF;
  IF COALESCE(p_default_hourly_rate, -1) < 0
     OR COALESCE(p_on_call_surcharge, -1) < 0
     OR COALESCE(p_urgent_surcharge, -1) < 0 THEN
    RAISE EXCEPTION 'ISSUE_BILLING_INVALID_AMOUNT';
  END IF;

  v_code := public.normalize_protocol_org_code(p_protocol_org_code);

  IF EXISTS (
    SELECT 1
    FROM public.org_serwis_billing_settings s
    WHERE s.protocol_org_code = v_code
      AND s.org_id IS DISTINCT FROM p_org_id
  ) THEN
    RAISE EXCEPTION 'PROTOCOL_ORG_CODE_TAKEN';
  END IF;

  INSERT INTO public.org_serwis_billing_settings (
    org_id,
    default_hourly_rate,
    on_call_surcharge,
    urgent_surcharge,
    protocol_org_code,
    updated_at,
    updated_by
  )
  VALUES (
    p_org_id,
    ROUND(p_default_hourly_rate, 2),
    ROUND(p_on_call_surcharge, 2),
    ROUND(p_urgent_surcharge, 2),
    v_code,
    now(),
    auth.uid()
  )
  ON CONFLICT (org_id) DO UPDATE
    SET default_hourly_rate = EXCLUDED.default_hourly_rate,
        on_call_surcharge = EXCLUDED.on_call_surcharge,
        urgent_surcharge = EXCLUDED.urgent_surcharge,
        protocol_org_code = EXCLUDED.protocol_org_code,
        updated_at = now(),
        updated_by = auth.uid()
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_org_serwis_billing_settings(uuid, numeric, numeric, numeric, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_org_serwis_billing_settings(uuid, numeric, numeric, numeric, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_property_issue_billing(p_issue_id uuid)
RETURNS SETOF public.property_issue_billing
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path TO 'public'
AS $$
  SELECT *
  FROM public.property_issue_billing
  WHERE issue_id = p_issue_id;
$$;

REVOKE ALL ON FUNCTION public.get_property_issue_billing(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_property_issue_billing(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.adjust_property_issue_billing(
  p_issue_id uuid,
  p_labor_hours numeric,
  p_labor_cost numeric,
  p_materials jsonb,
  p_surcharge_kind text,
  p_surcharge_amount numeric,
  p_invoice_amount numeric
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_issue public.property_issues%ROWTYPE;
  v_hours numeric;
  v_kind text;
  v_surcharge numeric;
  v_materials jsonb;
  v_material_total numeric;
  v_labor numeric;
  v_invoice numeric;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'ISSUE_AUTH_REQUIRED';
  END IF;

  SELECT * INTO v_issue
  FROM public.property_issues
  WHERE id = p_issue_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ISSUE_NOT_FOUND';
  END IF;

  IF NOT public.is_serwis_dispatcher_or_owner(v_issue.org_id) THEN
    RAISE EXCEPTION 'ISSUE_BILLING_FORBIDDEN';
  END IF;

  IF v_issue.status IS DISTINCT FROM 'resolved' THEN
    RAISE EXCEPTION 'ISSUE_NOT_FOUND';
  END IF;

  IF v_issue.is_invoiced IS TRUE THEN
    RAISE EXCEPTION 'ISSUE_BILLING_LOCKED';
  END IF;

  IF p_surcharge_kind IS NOT NULL AND p_surcharge_kind NOT IN ('on_call', 'urgent') THEN
    RAISE EXCEPTION 'ISSUE_BILLING_INVALID_SURCHARGE';
  END IF;

  v_hours := public.ceil_started_hours(p_labor_hours);
  v_kind := p_surcharge_kind;
  v_surcharge := ROUND(COALESCE(p_surcharge_amount, 0), 2);
  IF v_surcharge < 0 OR COALESCE(p_labor_cost, 0) < 0 OR COALESCE(p_invoice_amount, 0) < 0 THEN
    RAISE EXCEPTION 'ISSUE_BILLING_INVALID_AMOUNT';
  END IF;

  v_materials := CASE WHEN jsonb_typeof(p_materials) = 'array' THEN p_materials ELSE '[]'::jsonb END;
  v_material_total := public.materials_used_total(v_materials);
  v_labor := ROUND(COALESCE(p_labor_cost, 0), 2);
  v_invoice := COALESCE(
    CASE WHEN p_invoice_amount IS NULL THEN NULL ELSE ROUND(p_invoice_amount, 2) END,
    public.suggested_invoice_amount(v_material_total, v_labor, v_surcharge)
  );

  UPDATE public.property_issues
  SET
    labor_hours = v_hours,
    labor_cost = v_labor,
    materials_used = v_materials,
    total_material_cost = v_material_total,
    surcharge_kind = v_kind,
    surcharge_amount = v_surcharge
  WHERE id = p_issue_id;

  INSERT INTO public.property_issue_billing (
    issue_id,
    org_id,
    invoice_amount,
    original,
    captured_at,
    captured_by,
    adjusted_at,
    adjusted_by
  )
  VALUES (
    p_issue_id,
    v_issue.org_id,
    v_invoice,
    jsonb_build_object(
      'labor_hours', v_issue.labor_hours,
      'labor_cost', v_issue.labor_cost,
      'hourly_rate_applied', v_issue.hourly_rate_applied,
      'materials_used', COALESCE(v_issue.materials_used, '[]'::jsonb),
      'total_material_cost', COALESCE(v_issue.total_material_cost, 0),
      'surcharge_amount', v_issue.surcharge_amount,
      'surcharge_kind', v_issue.surcharge_kind,
      'invoice_amount', v_invoice
    ),
    now(),
    auth.uid(),
    now(),
    auth.uid()
  )
  ON CONFLICT (issue_id) DO UPDATE
    SET invoice_amount = EXCLUDED.invoice_amount,
        adjusted_at = now(),
        adjusted_by = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.adjust_property_issue_billing(uuid, numeric, numeric, jsonb, text, numeric, numeric) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.adjust_property_issue_billing(uuid, numeric, numeric, jsonb, text, numeric, numeric) TO authenticated;

-- ---------------------------------------------------------------------------
-- Backfill protocol numbers + billing snapshot for already resolved issues
-- ---------------------------------------------------------------------------

UPDATE public.property_issues
SET protocol_number = protocol_number
WHERE status = 'resolved'
  AND protocol_number IS NULL;
