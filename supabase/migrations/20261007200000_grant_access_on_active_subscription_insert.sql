BEGIN;

-- Purchase inserts module_subscriptions already as status = active.
-- The previous trigger ran only BEFORE UPDATE when status changed to active,
-- so a completed purchase never created module_access_grants.

CREATE OR REPLACE FUNCTION public.stamp_subscription_activated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.status = 'active' AND NEW.activated_at IS NULL THEN
    IF TG_OP = 'INSERT' THEN
      NEW.activated_at := now();
    ELSIF OLD.status IS DISTINCT FROM 'active' THEN
      NEW.activated_at := now();
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.stamp_subscription_activated_at() IS
  'Sets activated_at when a subscription is inserted as active or later becomes active.';

DROP TRIGGER IF EXISTS trg_stamp_subscription_activated_at ON public.module_subscriptions;
CREATE TRIGGER trg_stamp_subscription_activated_at
  BEFORE INSERT OR UPDATE ON public.module_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.stamp_subscription_activated_at();

CREATE OR REPLACE FUNCTION public.grant_module_access_on_activation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_is_new_activation boolean := false;
BEGIN
  IF NEW.status IS DISTINCT FROM 'active' THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    v_is_new_activation := true;
  ELSIF OLD.status IS DISTINCT FROM 'active' THEN
    v_is_new_activation := true;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.module_pricing_plans
    WHERE id = NEW.plan_id
  ) THEN
    RAISE WARNING 'Plan % not found for subscription %', NEW.plan_id, NEW.id;
    RETURN NEW;
  END IF;

  UPDATE public.module_access_grants g
  SET
    granted_by_subscription_id = NEW.id,
    granted_at = CASE WHEN v_is_new_activation THEN now() ELSE g.granted_at END,
    expires_at = NEW.expires_at,
    revoked_at = NULL,
    is_granted = true
  WHERE g.org_id = NEW.purchaser_org_id
    AND g.module = NEW.module
    AND g.community_id IS NOT DISTINCT FROM NEW.beneficiary_community_id
    AND g.is_granted = true
    AND g.revoked_at IS NULL;

  IF NOT FOUND THEN
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
      NEW.beneficiary_community_id,
      NEW.module,
      true,
      NEW.id,
      now(),
      NEW.expires_at
    );
  END IF;

  IF v_is_new_activation THEN
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
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.grant_module_access_on_activation() IS
  'Creates or refreshes module_access_grants when a subscription is inserted as active or later becomes active.';

DROP TRIGGER IF EXISTS trg_grant_module_access ON public.module_subscriptions;
CREATE TRIGGER trg_grant_module_access
  AFTER INSERT OR UPDATE OF status, expires_at ON public.module_subscriptions
  FOR EACH ROW
  WHEN (NEW.status = 'active')
  EXECUTE FUNCTION public.grant_module_access_on_activation();

UPDATE public.module_subscriptions
SET activated_at = COALESCE(activated_at, purchased_at, now())
WHERE status = 'active'
  AND activated_at IS NULL;

INSERT INTO public.module_access_grants (
  org_id,
  community_id,
  module,
  is_granted,
  granted_by_subscription_id,
  granted_at,
  expires_at
)
SELECT
  s.purchaser_org_id,
  s.beneficiary_community_id,
  s.module,
  true,
  s.id,
  COALESCE(s.activated_at, s.purchased_at, now()),
  s.expires_at
FROM public.module_subscriptions s
WHERE s.status = 'active'
  AND NOT EXISTS (
    SELECT 1
    FROM public.module_access_grants g
    WHERE g.org_id = s.purchaser_org_id
      AND g.module = s.module
      AND g.community_id IS NOT DISTINCT FROM s.beneficiary_community_id
      AND g.is_granted = true
      AND g.revoked_at IS NULL
  );

COMMIT;
