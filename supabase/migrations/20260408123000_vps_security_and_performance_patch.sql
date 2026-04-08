BEGIN;

ALTER TABLE IF EXISTS public.cleaning_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.cleaning_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.cleaning_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.cleaning_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.cleaning_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.community_board ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.inspections_hybrid ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.internal_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.material_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.partner_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.property_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.property_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.property_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.resident_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.task_execution_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.task_step_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.vendor_partners ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS profiles_final ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

CREATE POLICY profiles_select_own
ON public.profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

CREATE POLICY profiles_update_own
ON public.profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS logs_master_policy ON public.task_step_logs;
DROP POLICY IF EXISTS task_step_logs_policy_final ON public.task_step_logs;
DROP POLICY IF EXISTS step_logs_insert ON public.task_step_logs;

CREATE POLICY task_step_logs_select_own
ON public.task_step_logs
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY task_step_logs_insert_own
ON public.task_step_logs
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS execution_logs_insert ON public.task_execution_logs;

CREATE POLICY task_execution_logs_select_own
ON public.task_execution_logs
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY task_execution_logs_insert_own
ON public.task_execution_logs
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_property_checklists_loc_active
ON public.property_checklists (location_id, is_active);

CREATE INDEX IF NOT EXISTS idx_memberships_org_user_active_vps
ON public.memberships (org_id, user_id, is_active);

CREATE INDEX IF NOT EXISTS idx_cleaning_locations_org_community_vps
ON public.cleaning_locations (org_id, community_id);

CREATE INDEX IF NOT EXISTS idx_cleaning_staff_org_vps
ON public.cleaning_staff (org_id);

CREATE INDEX IF NOT EXISTS idx_cleaning_tasks_org_assigned_sched_vps
ON public.cleaning_tasks (org_id, assigned_staff_id, scheduled_at);

CREATE INDEX IF NOT EXISTS idx_cleaning_tasks_actual_performer_vps
ON public.cleaning_tasks (actual_performer_id);

CREATE INDEX IF NOT EXISTS idx_property_sections_location_assigned_vps
ON public.property_sections (location_id, assigned_staff_id);

CREATE INDEX IF NOT EXISTS idx_property_issues_org_status_created_vps
ON public.property_issues (org_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_property_issues_assigned_staff_vps
ON public.property_issues (assigned_staff_id);

CREATE INDEX IF NOT EXISTS idx_location_access_user_location_type_vps
ON public.location_access (user_id, location_id, access_type);

CREATE INDEX IF NOT EXISTS idx_task_execution_logs_user_created_vps
ON public.task_execution_logs (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_task_step_logs_user_created_vps
ON public.task_step_logs (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_partner_offers_org_active_vps
ON public.partner_offers (org_id, is_active);

COMMIT;
