BEGIN;

-- =============================================================================
-- RLS initplan wrap + duplicate policy/index hygiene
-- Source: Supabase Performance Security Lints (dashboard) CSVs
-- Do not apply twice on an already-wrapped catalog; ALTER is idempotent for wrap.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) Wrap auth.uid() inside frequently used SECURITY DEFINER helpers
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.check_manager_access(target_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE org_id = target_org_id
      AND user_id = (SELECT auth.uid())
      AND role ILIKE ANY (ARRAY['owner', 'manager', 'admin', 'coordinator'])
  );
$$;

CREATE OR REPLACE FUNCTION public.is_org_manager(target_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = (SELECT auth.uid())
      AND org_id = target_org_id
      AND role IN ('owner', 'manager', 'admin', 'coordinator')
  );
$$;

CREATE OR REPLACE FUNCTION public.is_org_manager_safe(target_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = (SELECT auth.uid())
      AND org_id = target_org_id
      AND role ILIKE ANY (ARRAY['owner', 'manager', 'admin', 'coordinator'])
  );
$$;

CREATE OR REPLACE FUNCTION public.is_org_member(target_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = (SELECT auth.uid())
      AND org_id = target_org_id
  );
$$;

CREATE OR REPLACE FUNCTION public.is_platform_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = (SELECT auth.uid())
      AND platform_role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_cleaning_org_manager(p_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.memberships m
    WHERE m.org_id = p_org_id
      AND m.user_id = (SELECT auth.uid())
      AND m.role = ANY (ARRAY['owner'::text, 'coordinator'::text])
      AND COALESCE(m.is_active, true)
  );
$$;

-- -----------------------------------------------------------------------------
-- 2) Rewrite every public policy that still calls auth.uid()/auth.jwt() per-row
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pg_temp.wrap_auth_calls(expr text)
RETURNS text
LANGUAGE plpgsql
AS $fn$
BEGIN
  IF expr IS NULL THEN
    RETURN NULL;
  END IF;

  expr := replace(expr, '( SELECT auth.uid() AS uid)', chr(1) || 'UID' || chr(1));
  expr := replace(expr, '(SELECT auth.uid() AS uid)', chr(1) || 'UID' || chr(1));
  expr := replace(expr, '( SELECT auth.uid())', chr(1) || 'UID' || chr(1));
  expr := replace(expr, '(SELECT auth.uid())', chr(1) || 'UID' || chr(1));
  expr := replace(expr, 'auth.uid()', '(SELECT auth.uid())');
  expr := replace(expr, chr(1) || 'UID' || chr(1), '(SELECT auth.uid())');

  expr := replace(expr, '( SELECT auth.jwt())', chr(1) || 'JWT' || chr(1));
  expr := replace(expr, '(SELECT auth.jwt())', chr(1) || 'JWT' || chr(1));
  expr := replace(expr, 'auth.jwt()', '(SELECT auth.jwt())');
  expr := replace(expr, chr(1) || 'JWT' || chr(1), '(SELECT auth.jwt())');

  RETURN expr;
END;
$fn$;

DO $wrap$
DECLARE
  r record;
  new_using text;
  new_check text;
  sql text;
BEGIN
  FOR r IN
    SELECT schemaname, tablename, policyname, cmd, qual, with_check
    FROM pg_policies
    WHERE schemaname = 'public'
  LOOP
    new_using := pg_temp.wrap_auth_calls(r.qual);
    new_check := pg_temp.wrap_auth_calls(r.with_check);

    IF new_using IS NOT DISTINCT FROM r.qual AND new_check IS NOT DISTINCT FROM r.with_check THEN
      CONTINUE;
    END IF;

    IF r.cmd = 'INSERT' THEN
      sql := 'ALTER POLICY ' || quote_ident(r.policyname)
          || ' ON ' || quote_ident(r.schemaname) || '.' || quote_ident(r.tablename)
          || ' WITH CHECK (' || new_check || ')';
    ELSIF new_check IS NULL THEN
      sql := 'ALTER POLICY ' || quote_ident(r.policyname)
          || ' ON ' || quote_ident(r.schemaname) || '.' || quote_ident(r.tablename)
          || ' USING (' || new_using || ')';
    ELSE
      sql := 'ALTER POLICY ' || quote_ident(r.policyname)
          || ' ON ' || quote_ident(r.schemaname) || '.' || quote_ident(r.tablename)
          || ' USING (' || new_using || ') WITH CHECK (' || new_check || ')';
    END IF;

    EXECUTE sql;
  END LOOP;
END;
$wrap$;

-- -----------------------------------------------------------------------------
-- 3) Safe duplicate-policy merges (identical or subset OR)
-- Intentional multi-policy RBAC on property_issues / community_board is kept.
-- -----------------------------------------------------------------------------

-- Identical ALL policies on cleaning_tasks
DROP POLICY IF EXISTS worker_tasks_master_policy ON public.cleaning_tasks;

-- applications: one public catalog SELECT; platform admin writes only (no SELECT overlap)
DROP POLICY IF EXISTS "Public apps are viewable by everyone" ON public.applications;
DROP POLICY IF EXISTS "Public can read active applications" ON public.applications;
DROP POLICY IF EXISTS "Platform admin full access applications" ON public.applications;

CREATE POLICY applications_select_catalog
  ON public.applications
  FOR SELECT
  TO anon, authenticated
  USING (
    COALESCE(is_active, true) = true
    OR public.is_platform_admin()
  );

CREATE POLICY applications_insert_platform_admin
  ON public.applications
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_platform_admin());

CREATE POLICY applications_update_platform_admin
  ON public.applications
  FOR UPDATE
  TO authenticated
  USING (public.is_platform_admin())
  WITH CHECK (public.is_platform_admin());

CREATE POLICY applications_delete_platform_admin
  ON public.applications
  FOR DELETE
  TO authenticated
  USING (public.is_platform_admin());

-- extra_jobs: manager OR worker is the original permissive union
DROP POLICY IF EXISTS extra_jobs_insert_manager ON public.cleaning_extra_jobs;
DROP POLICY IF EXISTS extra_jobs_insert_worker ON public.cleaning_extra_jobs;
DROP POLICY IF EXISTS extra_jobs_update_manager ON public.cleaning_extra_jobs;
DROP POLICY IF EXISTS extra_jobs_update_worker ON public.cleaning_extra_jobs;

CREATE POLICY extra_jobs_insert
  ON public.cleaning_extra_jobs
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_cleaning_org_manager(org_id)
    OR (
      origin = 'employee'
      AND created_by = (SELECT auth.uid())
      AND assigned_staff_id = (SELECT auth.uid())
      AND public.is_org_member(org_id)
    )
  );

CREATE POLICY extra_jobs_update
  ON public.cleaning_extra_jobs
  FOR UPDATE
  TO authenticated
  USING (
    public.is_cleaning_org_manager(org_id)
    OR assigned_staff_id = (SELECT auth.uid())
    OR created_by = (SELECT auth.uid())
  )
  WITH CHECK (
    public.is_cleaning_org_manager(org_id)
    OR assigned_staff_id = (SELECT auth.uid())
    OR created_by = (SELECT auth.uid())
  );

-- inventory: two manager ALL policies were near-duplicates (is_org_manager vs ILIKE helper).
-- Recreate as authenticated-only to drop public-role fan-out (anon / authenticator / dashboard_user).
DROP POLICY IF EXISTS "Inventory_Manager_Access" ON public.cleaning_inventory;
DROP POLICY IF EXISTS "Manager Inventory Access" ON public.cleaning_inventory;
DROP POLICY IF EXISTS "Inventory_Staff_View" ON public.cleaning_inventory;

CREATE POLICY cleaning_inventory_select
  ON public.cleaning_inventory
  FOR SELECT
  TO authenticated
  USING (
    public.has_location_access(location_id)
    OR public.check_manager_access(org_id)
  );

CREATE POLICY cleaning_inventory_insert_manager
  ON public.cleaning_inventory
  FOR INSERT
  TO authenticated
  WITH CHECK (public.check_manager_access(org_id));

CREATE POLICY cleaning_inventory_update_manager
  ON public.cleaning_inventory
  FOR UPDATE
  TO authenticated
  USING (public.check_manager_access(org_id))
  WITH CHECK (public.check_manager_access(org_id));

CREATE POLICY cleaning_inventory_delete_manager
  ON public.cleaning_inventory
  FOR DELETE
  TO authenticated
  USING (public.check_manager_access(org_id));

-- locations: owner ALL was a subset of manager ALL; manager ALL overlapped member SELECT
DROP POLICY IF EXISTS "Org isolation ALL for owners locations" ON public.locations;
DROP POLICY IF EXISTS "Manager_Full_Access_Master_Locations" ON public.locations;

CREATE POLICY locations_insert_management
  ON public.locations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.memberships m
      WHERE m.org_id = locations.org_id
        AND m.user_id = (SELECT auth.uid())
        AND m.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text, 'coordinator'::text])
    )
  );

CREATE POLICY locations_update_management
  ON public.locations
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.memberships m
      WHERE m.org_id = locations.org_id
        AND m.user_id = (SELECT auth.uid())
        AND m.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text, 'coordinator'::text])
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.memberships m
      WHERE m.org_id = locations.org_id
        AND m.user_id = (SELECT auth.uid())
        AND m.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text, 'coordinator'::text])
    )
  );

CREATE POLICY locations_delete_management
  ON public.locations
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.memberships m
      WHERE m.org_id = locations.org_id
        AND m.user_id = (SELECT auth.uid())
        AND m.role = ANY (ARRAY['owner'::text, 'manager'::text, 'admin'::text, 'coordinator'::text])
    )
  );

-- profiles_select_own is a subset of profiles_select_same_org
DROP POLICY IF EXISTS profiles_select_own ON public.profiles;

-- "Users see own adjustments" is a subset of staff_financial_adjustments_manage_financials
DROP POLICY IF EXISTS "Users see own adjustments" ON public.staff_financial_adjustments;

-- vehicles: assigned driver SELECT OR org member SELECT
DROP POLICY IF EXISTS vehicles_select_assigned_driver ON public.vehicles;
DROP POLICY IF EXISTS vehicles_select_org_member ON public.vehicles;

CREATE POLICY vehicles_select
  ON public.vehicles
  FOR SELECT
  TO authenticated
  USING (
    public.is_org_member(org_id)
    OR assigned_driver_id = (SELECT auth.uid())
  );

-- Management ALL overlapped SELECT with vehicles_select (managers are org members).
DROP POLICY IF EXISTS vehicles_write_management ON public.vehicles;

CREATE POLICY vehicles_insert_management
  ON public.vehicles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.memberships m
      WHERE m.org_id = vehicles.org_id
        AND m.user_id = (SELECT auth.uid())
        AND COALESCE(m.is_active, true) = true
        AND lower(COALESCE(m.role, ''::text)) = ANY (ARRAY['owner'::text, 'admin'::text, 'coordinator'::text, 'manager'::text])
    )
  );

CREATE POLICY vehicles_update_management
  ON public.vehicles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.memberships m
      WHERE m.org_id = vehicles.org_id
        AND m.user_id = (SELECT auth.uid())
        AND COALESCE(m.is_active, true) = true
        AND lower(COALESCE(m.role, ''::text)) = ANY (ARRAY['owner'::text, 'admin'::text, 'coordinator'::text, 'manager'::text])
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.memberships m
      WHERE m.org_id = vehicles.org_id
        AND m.user_id = (SELECT auth.uid())
        AND COALESCE(m.is_active, true) = true
        AND lower(COALESCE(m.role, ''::text)) = ANY (ARRAY['owner'::text, 'admin'::text, 'coordinator'::text, 'manager'::text])
    )
  );

CREATE POLICY vehicles_delete_management
  ON public.vehicles
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.memberships m
      WHERE m.org_id = vehicles.org_id
        AND m.user_id = (SELECT auth.uid())
        AND COALESCE(m.is_active, true) = true
        AND lower(COALESCE(m.role, ''::text)) = ANY (ARRAY['owner'::text, 'admin'::text, 'coordinator'::text, 'manager'::text])
    )
  );

-- -----------------------------------------------------------------------------
-- 4) Duplicate index: both btree(org_id) on cleaning_tasks
-- Keep idx_cleaning_tasks_org_id (canonical name). App filters tasks by org_id.
-- -----------------------------------------------------------------------------

DROP INDEX IF EXISTS public.idx_domio_tasks_org_user;

-- -----------------------------------------------------------------------------
-- 5) Covering indexes for hot FKs used in JOINs / list filters / CASCADE
-- Skip audit-only FKs (*_created_by, *_updated_by, *_approved_by, ...).
-- -----------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS admin_contracts_vendor_id_idx
  ON public.admin_contracts (vendor_id);

CREATE INDEX IF NOT EXISTS building_cooperation_links_cleaning_org_id_idx
  ON public.building_cooperation_links (cleaning_org_id);

CREATE INDEX IF NOT EXISTS building_cooperation_links_maintenance_org_id_idx
  ON public.building_cooperation_links (maintenance_org_id);

CREATE INDEX IF NOT EXISTS cleaning_extra_job_photos_org_id_idx
  ON public.cleaning_extra_job_photos (org_id);

CREATE INDEX IF NOT EXISTS cleaning_locations_location_master_id_idx
  ON public.cleaning_locations (location_master_id);

CREATE INDEX IF NOT EXISTS cleaning_tasks_section_id_idx
  ON public.cleaning_tasks (section_id);

CREATE INDEX IF NOT EXISTS cleaning_work_sessions_location_id_idx
  ON public.cleaning_work_sessions (location_id);

CREATE INDEX IF NOT EXISTS cleaning_work_sessions_task_id_idx
  ON public.cleaning_work_sessions (task_id);

CREATE INDEX IF NOT EXISTS communities_legal_entity_id_idx
  ON public.communities (legal_entity_id);

CREATE INDEX IF NOT EXISTS community_board_org_id_idx
  ON public.community_board (org_id);

CREATE INDEX IF NOT EXISTS community_comments_author_id_idx
  ON public.community_comments (author_id);

CREATE INDEX IF NOT EXISTS community_comments_org_id_idx
  ON public.community_comments (org_id);

CREATE INDEX IF NOT EXISTS community_emergency_providers_location_id_idx
  ON public.community_emergency_providers (location_id);

CREATE INDEX IF NOT EXISTS companies_org_id_idx
  ON public.companies (org_id);

CREATE INDEX IF NOT EXISTS equipment_protocols_worker_id_idx
  ON public.equipment_protocols (worker_id);

CREATE INDEX IF NOT EXISTS estate_members_invited_by_org_id_idx
  ON public.estate_members (invited_by_org_id);

CREATE INDEX IF NOT EXISTS fuel_logs_org_id_idx
  ON public.fuel_logs (org_id);

CREATE INDEX IF NOT EXISTS inbound_email_ingest_issue_id_idx
  ON public.inbound_email_ingest (issue_id);

CREATE INDEX IF NOT EXISTS inbound_email_ingest_matched_location_id_idx
  ON public.inbound_email_ingest (matched_location_id);

CREATE INDEX IF NOT EXISTS inspection_campaigns_org_id_idx
  ON public.inspection_campaigns (org_id);

CREATE INDEX IF NOT EXISTS inspection_campaigns_origin_org_id_idx
  ON public.inspection_campaigns (origin_org_id);

CREATE INDEX IF NOT EXISTS inspection_campaigns_vendor_id_idx
  ON public.inspection_campaigns (vendor_id);

CREATE INDEX IF NOT EXISTS inspections_location_id_idx
  ON public.inspections (location_id);

CREATE INDEX IF NOT EXISTS inspections_hybrid_location_id_idx
  ON public.inspections_hybrid (location_id);

CREATE INDEX IF NOT EXISTS inspections_hybrid_assigned_vendor_id_idx
  ON public.inspections_hybrid (assigned_vendor_id);

CREATE INDEX IF NOT EXISTS internal_tasks_location_id_idx
  ON public.internal_tasks (location_id);

CREATE INDEX IF NOT EXISTS legal_entities_created_by_org_id_idx
  ON public.legal_entities (created_by_org_id);

CREATE INDEX IF NOT EXISTS location_vendor_routing_vendor_id_idx
  ON public.location_vendor_routing (vendor_id);

CREATE INDEX IF NOT EXISTS offer_interactions_offer_id_idx
  ON public.offer_interactions (offer_id);

CREATE INDEX IF NOT EXISTS offer_interactions_location_id_idx
  ON public.offer_interactions (location_id);

-- -----------------------------------------------------------------------------
-- unused_index (INFO): do not drop. Many *_vps / org_id indexes are recent or
-- needed for RLS membership lookups; pg_stat_user_indexes "unused" is often a
-- stats-reset / low-traffic artifact. Re-check after 30 days of production load.
-- -----------------------------------------------------------------------------

COMMIT;
