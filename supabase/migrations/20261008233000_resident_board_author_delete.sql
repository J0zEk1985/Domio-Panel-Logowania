BEGIN;

-- The author removes their own listing from the resident board.
-- Edits stay on verify-announcement (service role) so the classifier still runs.
-- Org managers already update and delete every row through community_board_write_admin_team.

DROP POLICY IF EXISTS community_board_delete_author ON public.community_board;
CREATE POLICY community_board_delete_author
  ON public.community_board
  FOR DELETE
  TO authenticated
  USING (author_id = (SELECT auth.uid()));

-- Comments the classifier missed: the admin team can rewrite or hide them.
-- "Admins manage community_comments" stays for owner/admin/coordinator.
DROP POLICY IF EXISTS community_comments_write_admin_team ON public.community_comments;
CREATE POLICY community_comments_write_admin_team
  ON public.community_comments
  FOR ALL
  TO authenticated
  USING (public.is_org_admin_team(org_id))
  WITH CHECK (public.is_org_admin_team(org_id));

COMMIT;
