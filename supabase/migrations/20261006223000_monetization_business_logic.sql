-- ============================================================================
-- DOMIO Monetization: Business Logic & Auto-blocking
-- ============================================================================
-- Unit-count tracking, automatic subscription blocking on threshold breach
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. HELPER: Count residential units in community (excluding technical)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.count_residential_units_for_community(p_community_id uuid)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT COUNT(*)::integer
  FROM public.community_units
  WHERE community_id = p_community_id
    AND kind = 'residential'
    AND EXISTS (
      SELECT 1 FROM public.communities c
      WHERE c.id = p_community_id
    );
$$;

COMMENT ON FUNCTION public.count_residential_units_for_community(uuid) IS
  'Returns count of residential units (excluding technical rooms) for a given community.';

REVOKE ALL ON FUNCTION public.count_residential_units_for_community(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.count_residential_units_for_community(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 2. HELPER: Calculate unit-based price (home module)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.calculate_unit_based_price(
  p_plan_id uuid,
  p_unit_count integer
)
RETURNS numeric
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_plan public.pricing_plans%ROWTYPE;
  v_calculated numeric;
BEGIN
  IF p_unit_count IS NULL OR p_unit_count < 0 THEN
    RAISE EXCEPTION 'INVALID_UNIT_COUNT' USING HINT = 'Unit count must be a positive integer.';
  END IF;

  SELECT * INTO v_plan
  FROM public.pricing_plans
  WHERE id = p_plan_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PLAN_NOT_FOUND';
  END IF;

  IF NOT v_plan.is_unit_based THEN
    RAISE EXCEPTION 'PLAN_NOT_UNIT_BASED' USING HINT = 'This plan does not use unit-based pricing.';
  END IF;

  IF v_plan.price_per_unit IS NULL OR v_plan.min_price IS NULL THEN
    RAISE EXCEPTION 'PLAN_INCOMPLETE' USING HINT = 'Plan missing price_per_unit or min_price.';
  END IF;

  v_calculated := GREATEST(
    v_plan.min_price,
    v_plan.price_per_unit * p_unit_count
  );

  RETURN ROUND(v_calculated, 2);
END;
$$;

COMMENT ON FUNCTION public.calculate_unit_based_price(uuid, integer) IS
  'Calculates price for unit-based plan: MAX(min_price, price_per_unit * unit_count).';

REVOKE ALL ON FUNCTION public.calculate_unit_based_price(uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.calculate_unit_based_price(uuid, integer) TO authenticated;

-- ---------------------------------------------------------------------------
-- 3. HELPER: Check if module access is granted
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.has_module_access(
  p_org_id uuid,
  p_community_id uuid,
  p_module public.app_module
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.module_access_grants g
    WHERE g.org_id = p_org_id
      AND (g.community_id = p_community_id OR g.community_id IS NULL)
      AND g.module = p_module
      AND g.is_granted = true
      AND (g.expires_at IS NULL OR g.expires_at > now())
      AND g.revoked_at IS NULL
  );
$$;

COMMENT ON FUNCTION public.has_module_access(uuid, uuid, public.app_module) IS
  'Fast access check: returns true if org/community has active grant for module.';

REVOKE ALL ON FUNCTION public.has_module_access(uuid, uuid, public.app_module) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_module_access(uuid, uuid, public.app_module) TO authenticated;

-- ---------------------------------------------------------------------------
-- 4. TRIGGER: Auto-block subscription when unit count exceeds paid threshold
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.check_home_subscription_unit_threshold()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_sub record;
  v_current_units integer;
  v_event_id uuid;
BEGIN
  -- Only process residential units
  IF NEW.kind != 'residential' THEN
    RETURN NEW;
  END IF;

  -- Only on INSERT (new unit added)
  IF TG_OP != 'INSERT' THEN
    RETURN NEW;
  END IF;

  -- Find active home subscriptions for this community
  FOR v_sub IN
    SELECT 
      s.id,
      s.paid_unit_count,
      s.current_unit_count,
      s.status
    FROM public.module_subscriptions s
    WHERE s.beneficiary_community_id = NEW.community_id
      AND s.module = 'home'
      AND s.status = 'active'
  LOOP
    -- Count current residential units
    v_current_units := public.count_residential_units_for_community(NEW.community_id);

    -- Update current_unit_count
    UPDATE public.module_subscriptions
    SET current_unit_count = v_current_units
    WHERE id = v_sub.id;

    -- Check if threshold exceeded
    IF v_sub.paid_unit_count IS NOT NULL AND v_current_units > v_sub.paid_unit_count THEN
      -- Block subscription
      UPDATE public.module_subscriptions
      SET 
        status = 'blocked_pending_payment',
        blocked_at = now(),
        blocked_reason = format(
          'Przekroczono próg opłaconych lokali: %s/%s. Dodano nowy lokal: %s',
          v_sub.paid_unit_count,
          v_current_units,
          NEW.unit_number
        )
      WHERE id = v_sub.id;

      -- Revoke access grant
      UPDATE public.module_access_grants
      SET 
        is_granted = false,
        revoked_at = now()
      WHERE granted_by_subscription_id = v_sub.id
        AND module = 'home'
        AND community_id = NEW.community_id;

      -- Log event
      INSERT INTO public.subscription_events (
        subscription_id,
        event_type,
        event_data,
        triggered_at
      )
      VALUES (
        v_sub.id,
        'unit_threshold_exceeded',
        jsonb_build_object(
          'paid_unit_count', v_sub.paid_unit_count,
          'current_unit_count', v_current_units,
          'new_unit_id', NEW.id,
          'new_unit_number', NEW.unit_number,
          'blocked_reason', format(
            'Przekroczono próg opłaconych lokali: %s/%s',
            v_sub.paid_unit_count,
            v_current_units
          )
        ),
        now()
      );

      -- TODO: Send notification to org admins
      -- This can be implemented later with notification system
      
      RAISE NOTICE 'Subscription % blocked: unit count % exceeds paid threshold %', 
        v_sub.id, v_current_units, v_sub.paid_unit_count;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.check_home_subscription_unit_threshold() IS
  'Auto-blocks home subscriptions when residential unit count exceeds paid threshold.';

DROP TRIGGER IF EXISTS trg_check_home_subscription_threshold ON public.community_units;
CREATE TRIGGER trg_check_home_subscription_threshold
  AFTER INSERT ON public.community_units
  FOR EACH ROW
  EXECUTE FUNCTION public.check_home_subscription_unit_threshold();

-- ---------------------------------------------------------------------------
-- 5. TRIGGER: Sync current_unit_count on subscription activation
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.sync_subscription_unit_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_unit_count integer;
BEGIN
  -- Only for unit-based subscriptions (home module)
  IF NEW.module != 'home' OR NEW.beneficiary_community_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- On INSERT or when activating
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.status = 'active' AND OLD.status IS DISTINCT FROM 'active') THEN
    -- Count current residential units
    v_unit_count := public.count_residential_units_for_community(NEW.beneficiary_community_id);
    
    -- Update current_unit_count if not manually set
    IF NEW.current_unit_count IS NULL OR NEW.current_unit_count != v_unit_count THEN
      NEW.current_unit_count := v_unit_count;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.sync_subscription_unit_count() IS
  'Automatically syncs current_unit_count when subscription is created or activated.';

DROP TRIGGER IF EXISTS trg_sync_subscription_unit_count ON public.module_subscriptions;
CREATE TRIGGER trg_sync_subscription_unit_count
  BEFORE INSERT OR UPDATE ON public.module_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_subscription_unit_count();

-- ---------------------------------------------------------------------------
-- 6. TRIGGER: Auto-create access grant when subscription is activated
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.grant_module_access_on_activation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_plan public.pricing_plans%ROWTYPE;
BEGIN
  -- Only when subscription becomes active
  IF NEW.status != 'active' THEN
    RETURN NEW;
  END IF;

  -- Only process once (not already activated)
  IF OLD.activated_at IS NOT NULL AND NEW.activated_at = OLD.activated_at THEN
    RETURN NEW;
  END IF;

  -- Get plan details
  SELECT * INTO v_plan
  FROM public.pricing_plans
  WHERE id = NEW.plan_id;

  IF NOT FOUND THEN
    RAISE WARNING 'Plan % not found for subscription %', NEW.plan_id, NEW.id;
    RETURN NEW;
  END IF;

  -- Set activation timestamp
  IF NEW.activated_at IS NULL THEN
    NEW.activated_at := now();
  END IF;

  -- Create or update access grant
  INSERT INTO public.module_access_grants (
    org_id,
    community_id,
    module,
    is_granted,
    granted_by_subscription_id,
    granted_at,
    expires_at
  )
  VALUES (
    NEW.purchaser_org_id,
    NEW.beneficiary_community_id, -- NULL for global subscriptions
    NEW.module,
    true,
    NEW.id,
    now(),
    NEW.expires_at
  )
  ON CONFLICT (org_id, community_id, module, is_granted) 
  DO UPDATE SET
    granted_by_subscription_id = EXCLUDED.granted_by_subscription_id,
    granted_at = EXCLUDED.granted_at,
    expires_at = EXCLUDED.expires_at,
    revoked_at = NULL;

  -- Log event
  INSERT INTO public.subscription_events (
    subscription_id,
    event_type,
    event_data,
    triggered_by_user_id,
    triggered_at
  )
  VALUES (
    NEW.id,
    'activated',
    jsonb_build_object(
      'module', NEW.module,
      'beneficiary_community_id', NEW.beneficiary_community_id,
      'expires_at', NEW.expires_at
    ),
    auth.uid(),
    now()
  );

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.grant_module_access_on_activation() IS
  'Auto-creates module_access_grants record when subscription is activated.';

DROP TRIGGER IF EXISTS trg_grant_module_access ON public.module_subscriptions;
CREATE TRIGGER trg_grant_module_access
  BEFORE UPDATE ON public.module_subscriptions
  FOR EACH ROW
  WHEN (NEW.status = 'active' AND OLD.status IS DISTINCT FROM 'active')
  EXECUTE FUNCTION public.grant_module_access_on_activation();

-- ---------------------------------------------------------------------------
-- 7. TRIGGER: Log subscription events
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.log_subscription_status_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Only log status changes
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.subscription_events (
      subscription_id,
      event_type,
      event_data,
      triggered_by_user_id
    )
    VALUES (
      NEW.id,
      'created',
      jsonb_build_object(
        'module', NEW.module,
        'status', NEW.status,
        'amount_paid', NEW.amount_paid,
        'billing_interval', NEW.billing_interval
      ),
      auth.uid()
    );
  ELSIF TG_OP = 'UPDATE' AND NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO public.subscription_events (
      subscription_id,
      event_type,
      event_data,
      triggered_by_user_id
    )
    VALUES (
      NEW.id,
      CASE NEW.status
        WHEN 'active' THEN 'activated'
        WHEN 'blocked_pending_payment' THEN 'blocked'
        WHEN 'expired' THEN 'expired'
        WHEN 'cancelled' THEN 'cancelled'
        WHEN 'suspended' THEN 'suspended'
        ELSE 'status_changed'
      END,
      jsonb_build_object(
        'old_status', OLD.status,
        'new_status', NEW.status,
        'blocked_reason', NEW.blocked_reason
      ),
      auth.uid()
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_log_subscription_events ON public.module_subscriptions;
CREATE TRIGGER trg_log_subscription_events
  AFTER INSERT OR UPDATE ON public.module_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.log_subscription_status_change();

COMMIT;
