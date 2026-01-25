-- Migration: indexes + split admin_manage + memberships_admin_select (Cleaning)
-- Creates indexes on memberships(user_id), cleaning_tasks(assigned_staff_id).
-- Replaces admin_manage with separate INSERT/UPDATE/DELETE policies.
-- Adds SELECT policy for admins so Owner sees all workers.

-- 1. Indexes
CREATE INDEX IF NOT EXISTS idx_memberships_user_id ON public.memberships (user_id);
CREATE INDEX IF NOT EXISTS idx_cleaning_tasks_assigned_staff_id ON public.cleaning_tasks (assigned_staff_id);

-- 2. Drop existing admin_manage policy (if any)
DROP POLICY IF EXISTS "admin_manage" ON public.memberships;

-- 3. Split into separate policies (no commas in FOR)
CREATE POLICY "memberships_admin_insert"
  ON public.memberships
  FOR INSERT
  TO authenticated
  WITH CHECK (public.check_is_admin());

CREATE POLICY "memberships_admin_update"
  ON public.memberships
  FOR UPDATE
  TO authenticated
  USING (public.check_is_admin());

CREATE POLICY "memberships_admin_delete"
  ON public.memberships
  FOR DELETE
  TO authenticated
  USING (public.check_is_admin());

-- 4. SELECT for admins (Owner sees all workers)
CREATE POLICY "memberships_admin_select"
  ON public.memberships
  FOR SELECT
  TO authenticated
  USING (public.check_is_admin());
