-- ============================================================================
-- DOMIO Monetization Layer: Plans, Subscriptions, Licensing
-- ============================================================================
-- Module: home (community-based, unit-priced), developer_warranty (global, org-level)
-- Purchase flow: org (admin) pays, community (wspólnota) receives license
-- Unit blocking: automatic lock when community exceeds paid unit threshold
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. ENUMS & TYPES
-- ---------------------------------------------------------------------------

-- Module/app identifiers
DO $$ BEGIN
  CREATE TYPE public.app_module AS ENUM (
    'admin',           -- Administracja
    'cleaning',        -- Cleaning
    'maintenance',     -- Serwis
    'home',            -- DOMIO Home (community app)
    'fleet',           -- Flota
    'developer_warranty' -- Usterki deweloperskie (global premium)
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Subscription status lifecycle
DO $$ BEGIN
  CREATE TYPE public.subscription_status AS ENUM (
    'active',                   -- Aktywna
    'blocked_pending_payment',  -- Zablokowana - czeka na dopłatę
    'expired',                  -- Wygasła
    'cancelled',                -- Anulowana
    'suspended'                 -- Zawieszona (admin action)
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Billing interval
DO $$ BEGIN
  CREATE TYPE public.billing_interval AS ENUM (
    'monthly',   -- Miesięczny
    'yearly',    -- Roczny
    'one_time'   -- Jednorazowy
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- 2. PRICING PLANS (Service Owner Configuration)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.module_pricing_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Module identification
  module public.app_module NOT NULL,
  
  -- Plan naming (Polish UI)
  display_name text NOT NULL,
  description text,
  
  -- Pricing model flags
  is_global boolean NOT NULL DEFAULT false,  -- true = org-wide (developer_warranty), false = community-based (home)
  is_unit_based boolean NOT NULL DEFAULT false, -- true = price per unit (home), false = flat rate
  
  -- Unit-based pricing (for home)
  price_per_unit numeric(10,2) CHECK (price_per_unit IS NULL OR price_per_unit >= 0),
  min_price numeric(10,2) CHECK (min_price IS NULL OR min_price >= 0),
  
  -- Flat pricing (for developer_warranty or other modules)
  price_monthly numeric(10,2) CHECK (price_monthly IS NULL OR price_monthly >= 0),
  price_yearly numeric(10,2) CHECK (price_yearly IS NULL OR price_yearly >= 0),
  
  -- Availability
  is_active boolean NOT NULL DEFAULT true,
  available_from timestamptz,
  available_until timestamptz,
  
  -- Metadata
  features jsonb DEFAULT '[]'::jsonb NOT NULL,  -- Feature list for UI display
  terms_conditions text,
  
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  
  -- Constraints
  CONSTRAINT pricing_plans_unit_based_requires_per_unit 
    CHECK (
      NOT is_unit_based 
      OR (price_per_unit IS NOT NULL AND min_price IS NOT NULL)
    ),
  CONSTRAINT pricing_plans_flat_requires_price
    CHECK (
      is_unit_based 
      OR (price_monthly IS NOT NULL OR price_yearly IS NOT NULL)
    ),
  CONSTRAINT pricing_plans_features_array_check 
    CHECK (jsonb_typeof(features) = 'array')
);

CREATE INDEX idx_pricing_plans_module ON public.module_pricing_plans(module) WHERE is_active = true;
CREATE INDEX idx_pricing_plans_active ON public.module_pricing_plans(is_active, available_from, available_until);

COMMENT ON TABLE public.module_pricing_plans IS 
  'Service Owner pricing configuration. Unit-based plans (home) calculate price dynamically. Flat plans have fixed monthly/yearly rates.';

COMMENT ON COLUMN public.module_pricing_plans.is_global IS 
  'If true, subscription applies to entire org and all its communities (developer_warranty). If false, subscription is per-community (home).';

COMMENT ON COLUMN public.module_pricing_plans.price_per_unit IS 
  'Cost per residential unit (excluding technical rooms). Used when is_unit_based = true.';

COMMENT ON COLUMN public.module_pricing_plans.min_price IS 
  'Minimum charge regardless of unit count. Example: 2 PLN/unit but minimum 99 PLN.';

-- ---------------------------------------------------------------------------
-- 3. SUBSCRIPTIONS (Purchased Licenses)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.module_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Who purchased (always org/admin)
  purchaser_org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  
  -- Who benefits (community for home, null for global/org-level like developer_warranty)
  beneficiary_community_id uuid REFERENCES public.communities(id) ON DELETE CASCADE,
  
  -- Invoice entity (who appears on invoice - usually community even though org pays)
  invoice_entity_community_id uuid REFERENCES public.communities(id) ON DELETE SET NULL,
  
  -- Plan reference
  plan_id uuid NOT NULL REFERENCES public.module_pricing_plans(id) ON DELETE RESTRICT,
  module public.app_module NOT NULL,
  
  -- Status
  status public.subscription_status NOT NULL DEFAULT 'active',
  
  -- Unit-based subscription tracking (for home)
  paid_unit_count integer CHECK (paid_unit_count IS NULL OR paid_unit_count >= 0),
  current_unit_count integer CHECK (current_unit_count IS NULL OR current_unit_count >= 0),
  
  -- Billing period
  billing_interval public.billing_interval NOT NULL,
  amount_paid numeric(12,2) NOT NULL CHECK (amount_paid >= 0),
  
  -- Lifecycle dates
  purchased_at timestamptz NOT NULL DEFAULT now(),
  activated_at timestamptz,
  expires_at timestamptz,
  blocked_at timestamptz,
  blocked_reason text,
  cancelled_at timestamptz,
  
  -- Metadata
  purchase_metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
  
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  -- Constraints
  CONSTRAINT module_subscriptions_blocked_requires_reason
    CHECK (
      status != 'blocked_pending_payment' 
      OR (blocked_at IS NOT NULL AND blocked_reason IS NOT NULL)
    ),
  CONSTRAINT module_subscriptions_purchase_metadata_object
    CHECK (jsonb_typeof(purchase_metadata) = 'object')
);

CREATE INDEX idx_module_subscriptions_purchaser ON public.module_subscriptions(purchaser_org_id);
CREATE INDEX idx_module_subscriptions_beneficiary ON public.module_subscriptions(beneficiary_community_id) 
  WHERE beneficiary_community_id IS NOT NULL;
CREATE INDEX idx_module_subscriptions_module_status ON public.module_subscriptions(module, status);
CREATE INDEX idx_module_subscriptions_expires ON public.module_subscriptions(expires_at) 
  WHERE expires_at IS NOT NULL AND status = 'active';

COMMENT ON TABLE public.module_subscriptions IS
  'Purchased module licenses. Purchaser (org/admin) pays, beneficiary (community) receives access. Global subscriptions have null beneficiary_community_id.';

COMMENT ON COLUMN public.module_subscriptions.paid_unit_count IS
  'Number of units covered by this subscription (for unit-based plans like home). NULL for flat-rate plans.';

COMMENT ON COLUMN public.module_subscriptions.current_unit_count IS
  'Current actual unit count in the community. When exceeds paid_unit_count, subscription gets blocked.';

COMMENT ON COLUMN public.module_subscriptions.invoice_entity_community_id IS
  'Entity that appears on the invoice/receipt (usually the community), even though org pays.';

-- ---------------------------------------------------------------------------
-- 4. MODULE ACCESS CONTROL (License Check)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.module_access_grants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Grant scope
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  community_id uuid REFERENCES public.communities(id) ON DELETE CASCADE,
  module public.app_module NOT NULL,
  
  -- Access control
  is_granted boolean NOT NULL DEFAULT true,
  granted_by_subscription_id uuid REFERENCES public.module_subscriptions(id) ON DELETE CASCADE,
  
  -- Override for manual grants (e.g., trial, migration, special deals)
  is_manual_grant boolean NOT NULL DEFAULT false,
  manual_grant_reason text,
  manual_granted_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  
  -- Lifecycle
  granted_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  revoked_at timestamptz,
  
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  -- Constraints
  CONSTRAINT module_access_grants_manual_requires_reason
    CHECK (
      NOT is_manual_grant 
      OR (manual_grant_reason IS NOT NULL AND manual_granted_by IS NOT NULL)
    ),
  CONSTRAINT module_access_grants_unique_active_grant
    UNIQUE (org_id, community_id, module, is_granted) 
      DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX idx_module_access_grants_org_module ON public.module_access_grants(org_id, module) 
  WHERE is_granted = true;
CREATE INDEX idx_module_access_grants_community_module ON public.module_access_grants(community_id, module) 
  WHERE community_id IS NOT NULL AND is_granted = true;
CREATE INDEX idx_module_access_grants_subscription ON public.module_access_grants(granted_by_subscription_id)
  WHERE granted_by_subscription_id IS NOT NULL;

COMMENT ON TABLE public.module_access_grants IS
  'Active access grants derived from subscriptions or manual overrides. Used for fast license checks.';

-- ---------------------------------------------------------------------------
-- 5. SUBSCRIPTION EVENTS LOG (Audit Trail)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.subscription_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id uuid NOT NULL REFERENCES public.module_subscriptions(id) ON DELETE CASCADE,
  
  event_type text NOT NULL, -- 'created', 'activated', 'blocked', 'unblocked', 'renewed', 'cancelled', 'expired', 'unit_threshold_exceeded'
  event_data jsonb DEFAULT '{}'::jsonb NOT NULL,
  
  triggered_by_user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  triggered_at timestamptz NOT NULL DEFAULT now(),
  
  CONSTRAINT subscription_events_data_object_check
    CHECK (jsonb_typeof(event_data) = 'object')
);

CREATE INDEX idx_subscription_events_subscription ON public.subscription_events(subscription_id, triggered_at DESC);
CREATE INDEX idx_subscription_events_type ON public.subscription_events(event_type, triggered_at DESC);

COMMENT ON TABLE public.subscription_events IS
  'Audit log for all subscription lifecycle events and state changes.';

-- ---------------------------------------------------------------------------
-- 6. PAYMENT INTENTS / ORDERS (Pre-purchase calculation & tracking)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.subscription_payment_intents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Purchase details
  purchaser_org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  beneficiary_community_id uuid REFERENCES public.communities(id) ON DELETE CASCADE,
  plan_id uuid NOT NULL REFERENCES public.module_pricing_plans(id) ON DELETE RESTRICT,
  
  -- Invoice data
  invoice_entity_community_id uuid REFERENCES public.communities(id) ON DELETE SET NULL,
  invoice_entity_name text,
  invoice_entity_nip text,
  invoice_entity_address jsonb,
  
  -- Calculated pricing
  unit_count integer CHECK (unit_count IS NULL OR unit_count > 0),
  calculated_amount numeric(12,2) NOT NULL CHECK (calculated_amount >= 0),
  billing_interval public.billing_interval NOT NULL,
  
  -- Payment tracking
  status text NOT NULL DEFAULT 'pending', -- 'pending', 'completed', 'failed', 'cancelled'
  payment_method text, -- 'transfer', 'card', 'invoice', etc.
  payment_confirmed_at timestamptz,
  
  -- Fulfillment
  subscription_id uuid REFERENCES public.module_subscriptions(id) ON DELETE SET NULL,
  fulfilled_at timestamptz,
  
  -- Metadata
  calculation_details jsonb DEFAULT '{}'::jsonb NOT NULL,
  
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  
  CONSTRAINT subscription_payment_intents_calculation_details_object
    CHECK (jsonb_typeof(calculation_details) = 'object'),
  CONSTRAINT subscription_payment_intents_invoice_address_object
    CHECK (invoice_entity_address IS NULL OR jsonb_typeof(invoice_entity_address) = 'object')
);

CREATE INDEX idx_payment_intents_purchaser ON public.subscription_payment_intents(purchaser_org_id, created_at DESC);
CREATE INDEX idx_payment_intents_status ON public.subscription_payment_intents(status, created_at DESC);
CREATE INDEX idx_payment_intents_subscription ON public.subscription_payment_intents(subscription_id) 
  WHERE subscription_id IS NOT NULL;

COMMENT ON TABLE public.subscription_payment_intents IS
  'Pre-purchase calculations and payment tracking. Links to subscription after successful payment.';

-- ---------------------------------------------------------------------------
-- 7. RLS POLICIES (Security Layer)
-- ---------------------------------------------------------------------------

ALTER TABLE public.module_pricing_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.module_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.module_access_grants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_payment_intents ENABLE ROW LEVEL SECURITY;

-- Pricing Plans: Service Owner (Super Admin) only for write, authenticated read for active plans
DROP POLICY IF EXISTS pricing_plans_select ON public.module_pricing_plans;
CREATE POLICY pricing_plans_select
  ON public.module_pricing_plans
  FOR SELECT
  TO authenticated
  USING (is_active = true OR public.is_platform_admin());

DROP POLICY IF EXISTS pricing_plans_write ON public.module_pricing_plans;
CREATE POLICY pricing_plans_write
  ON public.module_pricing_plans
  FOR ALL
  TO authenticated
  USING (public.is_platform_admin())
  WITH CHECK (public.is_platform_admin());

-- Subscriptions: Purchaser org members can view their subscriptions
DROP POLICY IF EXISTS module_subscriptions_select ON public.module_subscriptions;
CREATE POLICY module_subscriptions_select
  ON public.module_subscriptions
  FOR SELECT
  TO authenticated
  USING (
    public.is_org_member(purchaser_org_id)
    OR (beneficiary_community_id IS NOT NULL 
        AND public.is_org_member((SELECT org_id FROM public.communities WHERE id = beneficiary_community_id)))
  );

-- Subscriptions: Only purchaser org admins can insert (via service functions)
DROP POLICY IF EXISTS module_subscriptions_insert ON public.module_subscriptions;
CREATE POLICY module_subscriptions_insert
  ON public.module_subscriptions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.memberships m
      WHERE m.org_id = purchaser_org_id
        AND m.user_id = auth.uid()
        AND m.role IN ('owner', 'wlasciciel', 'admin', 'administrator')
    )
  );

-- Access Grants: Members of org/community can check their access
DROP POLICY IF EXISTS module_access_grants_select ON public.module_access_grants;
CREATE POLICY module_access_grants_select
  ON public.module_access_grants
  FOR SELECT
  TO authenticated
  USING (
    public.is_org_member(org_id)
    OR (community_id IS NOT NULL 
        AND public.is_org_member((SELECT org_id FROM public.communities WHERE id = community_id)))
  );

-- Events: Read-only for subscription owner
DROP POLICY IF EXISTS subscription_events_select ON public.subscription_events;
CREATE POLICY subscription_events_select
  ON public.subscription_events
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.module_subscriptions s
      WHERE s.id = subscription_id
        AND public.is_org_member(s.purchaser_org_id)
    )
  );

-- Payment Intents: Purchaser org members only
DROP POLICY IF EXISTS payment_intents_select ON public.subscription_payment_intents;
CREATE POLICY payment_intents_select
  ON public.subscription_payment_intents
  FOR SELECT
  TO authenticated
  USING (public.is_org_member(purchaser_org_id));

DROP POLICY IF EXISTS payment_intents_insert ON public.subscription_payment_intents;
CREATE POLICY payment_intents_insert
  ON public.subscription_payment_intents
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.memberships m
      WHERE m.org_id = purchaser_org_id
        AND m.user_id = auth.uid()
        AND m.role IN ('owner', 'wlasciciel', 'admin', 'administrator')
    )
  );

-- ---------------------------------------------------------------------------
-- 8. TRIGGERS
-- ---------------------------------------------------------------------------

-- Update timestamp trigger function (reusable)
CREATE OR REPLACE FUNCTION public.trigger_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.enforce_module_subscription_plan_scope()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
  v_is_global boolean;
BEGIN
  SELECT is_global INTO v_is_global
  FROM public.module_pricing_plans
  WHERE id = NEW.plan_id;

  IF v_is_global IS NULL THEN
    RAISE EXCEPTION 'Unknown pricing plan %', NEW.plan_id;
  END IF;

  IF v_is_global AND NEW.beneficiary_community_id IS NOT NULL THEN
    RAISE EXCEPTION 'Global plan cannot be bound to a single community';
  END IF;

  IF NOT v_is_global AND NEW.beneficiary_community_id IS NULL THEN
    RAISE EXCEPTION 'Community plan requires beneficiary_community_id';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS module_subscriptions_plan_scope ON public.module_subscriptions;
CREATE TRIGGER module_subscriptions_plan_scope
  BEFORE INSERT OR UPDATE OF plan_id, beneficiary_community_id
  ON public.module_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_module_subscription_plan_scope();

DROP TRIGGER IF EXISTS pricing_plans_updated_at ON public.module_pricing_plans;
CREATE TRIGGER pricing_plans_updated_at
  BEFORE UPDATE ON public.module_pricing_plans
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_set_updated_at();

DROP TRIGGER IF EXISTS module_subscriptions_updated_at ON public.module_subscriptions;
CREATE TRIGGER module_subscriptions_updated_at
  BEFORE UPDATE ON public.module_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_set_updated_at();

DROP TRIGGER IF EXISTS module_access_grants_updated_at ON public.module_access_grants;
CREATE TRIGGER module_access_grants_updated_at
  BEFORE UPDATE ON public.module_access_grants
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_set_updated_at();

DROP TRIGGER IF EXISTS payment_intents_updated_at ON public.subscription_payment_intents;
CREATE TRIGGER payment_intents_updated_at
  BEFORE UPDATE ON public.subscription_payment_intents
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_set_updated_at();

-- ---------------------------------------------------------------------------
-- 9. GRANTS
-- ---------------------------------------------------------------------------

GRANT SELECT, INSERT, UPDATE, DELETE ON public.module_pricing_plans TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.module_subscriptions TO authenticated;
GRANT SELECT ON public.module_access_grants TO authenticated;
GRANT SELECT ON public.subscription_events TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.subscription_payment_intents TO authenticated;

REVOKE ALL ON public.module_pricing_plans FROM anon;
REVOKE ALL ON public.module_subscriptions FROM anon;
REVOKE ALL ON public.module_access_grants FROM anon;
REVOKE ALL ON public.subscription_events FROM anon;
REVOKE ALL ON public.subscription_payment_intents FROM anon;

COMMIT;
