-- ============================================================================
-- DOMIO Monetization: Integration Tests
-- ============================================================================
-- Run these tests after applying migrations to verify correct implementation
-- ============================================================================

BEGIN;

-- Set up test data cleanup
CREATE TEMPORARY TABLE IF NOT EXISTS test_cleanup (
  table_name text,
  record_id uuid
);

-- ---------------------------------------------------------------------------
-- TEST 1: Pricing Plans Creation
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_plan_id uuid;
  v_price numeric;
BEGIN
  RAISE NOTICE '=== TEST 1: Pricing Plans Creation ===';
  
  -- Create unit-based plan (home)
  INSERT INTO public.pricing_plans (
    module,
    display_name,
    description,
    is_global,
    is_unit_based,
    price_per_unit,
    min_price,
    features,
    is_active
  ) VALUES (
    'home',
    'Test Home Plan',
    'Test plan for home module',
    false,
    true,
    2.50,
    99.00,
    '["Feature 1", "Feature 2"]'::jsonb,
    true
  ) RETURNING id INTO v_plan_id;
  
  INSERT INTO test_cleanup VALUES ('pricing_plans', v_plan_id);
  
  -- Verify plan was created
  IF v_plan_id IS NULL THEN
    RAISE EXCEPTION 'TEST 1 FAILED: Plan was not created';
  END IF;
  
  -- Test price calculation with 20 units (should return min_price)
  v_price := public.calculate_unit_based_price(v_plan_id, 20);
  IF v_price != 99.00 THEN
    RAISE EXCEPTION 'TEST 1 FAILED: Expected 99.00, got %', v_price;
  END IF;
  
  -- Test price calculation with 100 units (should return 250.00)
  v_price := public.calculate_unit_based_price(v_plan_id, 100);
  IF v_price != 250.00 THEN
    RAISE EXCEPTION 'TEST 1 FAILED: Expected 250.00, got %', v_price;
  END IF;
  
  RAISE NOTICE '✓ TEST 1 PASSED: Pricing plans and calculations work correctly';
END $$;

-- ---------------------------------------------------------------------------
-- TEST 2: Count Residential Units Function
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_org_id uuid;
  v_community_id uuid;
  v_location_id uuid;
  v_unit_count integer;
BEGIN
  RAISE NOTICE '=== TEST 2: Count Residential Units ===';
  
  -- Create test org
  INSERT INTO public.organizations (name, slug)
  VALUES ('Test Org', 'test-org-' || gen_random_uuid())
  RETURNING id INTO v_org_id;
  
  INSERT INTO test_cleanup VALUES ('organizations', v_org_id);
  
  -- Create test community
  INSERT INTO public.communities (org_id, name)
  VALUES (v_org_id, 'Test Community')
  RETURNING id INTO v_community_id;
  
  INSERT INTO test_cleanup VALUES ('communities', v_community_id);
  
  -- Create test location
  INSERT INTO public.cleaning_locations (
    org_id,
    name,
    address,
    community_id
  ) VALUES (
    v_org_id,
    'Test Building',
    'Test Address 1',
    v_community_id
  ) RETURNING id INTO v_location_id;
  
  INSERT INTO test_cleanup VALUES ('cleaning_locations', v_location_id);
  
  -- Add residential units
  INSERT INTO public.community_units (
    org_id,
    community_id,
    location_id,
    unit_number,
    kind
  ) 
  SELECT 
    v_org_id,
    v_community_id,
    v_location_id,
    i::text,
    'residential'
  FROM generate_series(1, 5) i;
  
  -- Add technical rooms (should NOT be counted)
  INSERT INTO public.community_units (
    org_id,
    community_id,
    location_id,
    unit_number,
    kind
  )
  VALUES
    (v_org_id, v_community_id, v_location_id, 'tech-1', 'technical'),
    (v_org_id, v_community_id, v_location_id, 'tech-2', 'technical');
  
  -- Count residential units
  v_unit_count := public.count_residential_units_for_community(v_community_id);
  
  IF v_unit_count != 5 THEN
    RAISE EXCEPTION 'TEST 2 FAILED: Expected 5 residential units, got %', v_unit_count;
  END IF;
  
  RAISE NOTICE '✓ TEST 2 PASSED: Residential unit counting works (excluded % technical rooms)', 2;
END $$;

-- ---------------------------------------------------------------------------
-- TEST 3: Subscription Creation and Access Grant
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_org_id uuid;
  v_community_id uuid;
  v_plan_id uuid;
  v_subscription_id uuid;
  v_has_access boolean;
  v_grant_count integer;
BEGIN
  RAISE NOTICE '=== TEST 3: Subscription Creation and Access Grant ===';
  
  -- Reuse test data from TEST 2 or create new
  SELECT id INTO v_org_id FROM public.organizations WHERE name = 'Test Org' LIMIT 1;
  SELECT id INTO v_community_id FROM public.communities WHERE org_id = v_org_id LIMIT 1;
  SELECT id INTO v_plan_id FROM public.pricing_plans WHERE module = 'home' AND display_name = 'Test Home Plan' LIMIT 1;
  
  IF v_org_id IS NULL OR v_community_id IS NULL OR v_plan_id IS NULL THEN
    RAISE EXCEPTION 'TEST 3 SKIPPED: Missing test data from previous tests';
  END IF;
  
  -- Create active subscription
  INSERT INTO public.module_subscriptions (
    purchaser_org_id,
    beneficiary_community_id,
    plan_id,
    module,
    status,
    billing_interval,
    amount_paid,
    paid_unit_count,
    current_unit_count
  ) VALUES (
    v_org_id,
    v_community_id,
    v_plan_id,
    'home',
    'active',
    'yearly',
    250.00,
    100,
    5
  ) RETURNING id INTO v_subscription_id;
  
  INSERT INTO test_cleanup VALUES ('module_subscriptions', v_subscription_id);
  
  -- Wait for triggers to complete
  PERFORM pg_sleep(0.1);
  
  -- Check if access grant was created
  SELECT COUNT(*) INTO v_grant_count
  FROM public.module_access_grants
  WHERE granted_by_subscription_id = v_subscription_id
    AND module = 'home'
    AND is_granted = true;
  
  IF v_grant_count != 1 THEN
    RAISE EXCEPTION 'TEST 3 FAILED: Access grant was not created (found % grants)', v_grant_count;
  END IF;
  
  -- Test access check function
  v_has_access := public.has_module_access(v_org_id, v_community_id, 'home');
  
  IF NOT v_has_access THEN
    RAISE EXCEPTION 'TEST 3 FAILED: has_module_access returned false';
  END IF;
  
  RAISE NOTICE '✓ TEST 3 PASSED: Subscription creation and access grant work correctly';
END $$;

-- ---------------------------------------------------------------------------
-- TEST 4: Auto-blocking on Unit Threshold Exceeded
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_org_id uuid;
  v_community_id uuid;
  v_location_id uuid;
  v_subscription_id uuid;
  v_new_status text;
  v_blocked_reason text;
BEGIN
  RAISE NOTICE '=== TEST 4: Auto-blocking on Unit Threshold Exceeded ===';
  
  -- Get test data
  SELECT id INTO v_org_id FROM public.organizations WHERE name = 'Test Org' LIMIT 1;
  SELECT id INTO v_community_id FROM public.communities WHERE org_id = v_org_id LIMIT 1;
  SELECT id INTO v_location_id FROM public.cleaning_locations WHERE community_id = v_community_id LIMIT 1;
  SELECT id INTO v_subscription_id FROM public.module_subscriptions 
    WHERE beneficiary_community_id = v_community_id AND module = 'home' LIMIT 1;
  
  IF v_subscription_id IS NULL THEN
    RAISE EXCEPTION 'TEST 4 SKIPPED: No subscription found';
  END IF;
  
  -- Get current unit count
  DECLARE v_current_count integer;
  BEGIN
    SELECT current_unit_count INTO v_current_count
    FROM public.module_subscriptions
    WHERE id = v_subscription_id;
    
    RAISE NOTICE 'Current unit count before adding: %', v_current_count;
  END;
  
  -- Add units to exceed paid threshold (paid_unit_count is 100 from TEST 3)
  -- We'll add units from 6 to 101 to exceed the threshold
  INSERT INTO public.community_units (
    org_id,
    community_id,
    location_id,
    unit_number,
    kind
  )
  SELECT
    v_org_id,
    v_community_id,
    v_location_id,
    i::text,
    'residential'
  FROM generate_series(6, 101) i;
  
  -- Wait for trigger
  PERFORM pg_sleep(0.2);
  
  -- Check if subscription was blocked
  SELECT status, blocked_reason 
  INTO v_new_status, v_blocked_reason
  FROM public.module_subscriptions
  WHERE id = v_subscription_id;
  
  IF v_new_status != 'blocked_pending_payment' THEN
    RAISE EXCEPTION 'TEST 4 FAILED: Subscription was not blocked (status: %)', v_new_status;
  END IF;
  
  IF v_blocked_reason IS NULL THEN
    RAISE EXCEPTION 'TEST 4 FAILED: Blocked reason is NULL';
  END IF;
  
  -- Check if access grant was revoked
  DECLARE v_is_granted boolean;
  BEGIN
    SELECT is_granted INTO v_is_granted
    FROM public.module_access_grants
    WHERE granted_by_subscription_id = v_subscription_id;
    
    IF v_is_granted IS TRUE THEN
      RAISE EXCEPTION 'TEST 4 FAILED: Access grant was not revoked';
    END IF;
  END;
  
  -- Check if event was logged
  DECLARE v_event_count integer;
  BEGIN
    SELECT COUNT(*) INTO v_event_count
    FROM public.subscription_events
    WHERE subscription_id = v_subscription_id
      AND event_type = 'unit_threshold_exceeded';
    
    IF v_event_count < 1 THEN
      RAISE EXCEPTION 'TEST 4 FAILED: Event was not logged';
    END IF;
  END;
  
  RAISE NOTICE '✓ TEST 4 PASSED: Auto-blocking works correctly';
  RAISE NOTICE '  Blocked reason: %', v_blocked_reason;
END $$;

-- ---------------------------------------------------------------------------
-- TEST 5: Global Subscription (Developer Warranty)
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_org_id uuid;
  v_plan_id uuid;
  v_subscription_id uuid;
  v_has_access boolean;
BEGIN
  RAISE NOTICE '=== TEST 5: Global Subscription (Developer Warranty) ===';
  
  -- Get test org
  SELECT id INTO v_org_id FROM public.organizations WHERE name = 'Test Org' LIMIT 1;
  
  -- Create global plan
  INSERT INTO public.pricing_plans (
    module,
    display_name,
    is_global,
    is_unit_based,
    price_monthly,
    price_yearly,
    features,
    is_active
  ) VALUES (
    'developer_warranty',
    'Test Developer Warranty',
    true,
    false,
    199.00,
    1990.00,
    '["Global access"]'::jsonb,
    true
  ) RETURNING id INTO v_plan_id;
  
  INSERT INTO test_cleanup VALUES ('pricing_plans', v_plan_id);
  
  -- Create global subscription (no beneficiary_community_id)
  INSERT INTO public.module_subscriptions (
    purchaser_org_id,
    beneficiary_community_id,
    plan_id,
    module,
    status,
    billing_interval,
    amount_paid
  ) VALUES (
    v_org_id,
    NULL, -- global subscription
    v_plan_id,
    'developer_warranty',
    'active',
    'yearly',
    1990.00
  ) RETURNING id INTO v_subscription_id;
  
  INSERT INTO test_cleanup VALUES ('module_subscriptions', v_subscription_id);
  
  -- Wait for triggers
  PERFORM pg_sleep(0.1);
  
  -- Check access (should work with NULL community_id for global subscriptions)
  v_has_access := public.has_module_access(v_org_id, NULL, 'developer_warranty');
  
  IF NOT v_has_access THEN
    RAISE EXCEPTION 'TEST 5 FAILED: Global subscription access check failed';
  END IF;
  
  RAISE NOTICE '✓ TEST 5 PASSED: Global subscriptions work correctly';
END $$;

-- ---------------------------------------------------------------------------
-- TEST 6: Subscription Events Logging
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_subscription_id uuid;
  v_event_types text[];
  v_expected_types text[] := ARRAY['created', 'activated'];
BEGIN
  RAISE NOTICE '=== TEST 6: Subscription Events Logging ===';
  
  -- Get any active subscription
  SELECT id INTO v_subscription_id
  FROM public.module_subscriptions
  WHERE status = 'active'
  LIMIT 1;
  
  IF v_subscription_id IS NULL THEN
    RAISE EXCEPTION 'TEST 6 SKIPPED: No active subscription found';
  END IF;
  
  -- Get logged events
  SELECT ARRAY_AGG(event_type ORDER BY triggered_at)
  INTO v_event_types
  FROM public.subscription_events
  WHERE subscription_id = v_subscription_id;
  
  IF v_event_types IS NULL OR NOT v_event_types @> v_expected_types THEN
    RAISE EXCEPTION 'TEST 6 FAILED: Expected events % not found, got %', v_expected_types, v_event_types;
  END IF;
  
  RAISE NOTICE '✓ TEST 6 PASSED: Event logging works correctly';
  RAISE NOTICE '  Logged events: %', v_event_types;
END $$;

-- ---------------------------------------------------------------------------
-- CLEANUP TEST DATA
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_cleanup_record record;
BEGIN
  RAISE NOTICE '=== CLEANING UP TEST DATA ===';
  
  -- Delete in reverse order of creation (respecting foreign keys)
  FOR v_cleanup_record IN 
    SELECT DISTINCT table_name FROM test_cleanup 
    ORDER BY 
      CASE table_name
        WHEN 'module_subscriptions' THEN 1
        WHEN 'pricing_plans' THEN 2
        WHEN 'cleaning_locations' THEN 3
        WHEN 'communities' THEN 4
        WHEN 'organizations' THEN 5
        ELSE 99
      END
  LOOP
    EXECUTE format('DELETE FROM public.%I WHERE id IN (SELECT record_id FROM test_cleanup WHERE table_name = %L)',
      v_cleanup_record.table_name,
      v_cleanup_record.table_name
    );
    
    RAISE NOTICE '  Cleaned up table: %', v_cleanup_record.table_name;
  END LOOP;
  
  RAISE NOTICE '✓ CLEANUP COMPLETE';
END $$;

-- ---------------------------------------------------------------------------
-- TEST SUMMARY
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '╔════════════════════════════════════════╗';
  RAISE NOTICE '║   ALL TESTS PASSED SUCCESSFULLY! ✓     ║';
  RAISE NOTICE '╚════════════════════════════════════════╝';
  RAISE NOTICE '';
  RAISE NOTICE 'Summary:';
  RAISE NOTICE '  ✓ TEST 1: Pricing Plans Creation';
  RAISE NOTICE '  ✓ TEST 2: Count Residential Units';
  RAISE NOTICE '  ✓ TEST 3: Subscription Creation and Access Grant';
  RAISE NOTICE '  ✓ TEST 4: Auto-blocking on Unit Threshold';
  RAISE NOTICE '  ✓ TEST 5: Global Subscription';
  RAISE NOTICE '  ✓ TEST 6: Subscription Events Logging';
  RAISE NOTICE '';
  RAISE NOTICE 'Next Steps:';
  RAISE NOTICE '  → Apply seed data: supabase/seed/monetization_seed_data.sql';
  RAISE NOTICE '  → Proceed to STEP 2: Business Logic Layer';
END $$;

COMMIT;

-- Note: Run this file with:
-- psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/monetization_tests.sql
