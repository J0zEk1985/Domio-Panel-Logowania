BEGIN;

ALTER TABLE public.community_board
  ADD COLUMN IF NOT EXISTS moderation_hold text;

ALTER TABLE public.community_board
  DROP CONSTRAINT IF EXISTS community_board_moderation_hold_check;

ALTER TABLE public.community_board
  ADD CONSTRAINT community_board_moderation_hold_check
  CHECK (moderation_hold IS NULL OR moderation_hold IN ('uncertain', 'jev_unavailable'));

COMMENT ON COLUMN public.community_board.moderation_hold IS
  'Why a pending_review post is waiting: uncertain Jev decision or Jev unavailable.';

-- Neighbors can read published posts. Pending posts stay with the author and org management.
DROP POLICY IF EXISTS community_board_select_resident ON public.community_board;
CREATE POLICY community_board_select_resident
  ON public.community_board
  FOR SELECT
  TO authenticated
  USING (
    public.can_read_community_board_row(location_id, estate_id)
    AND (
      status IS DISTINCT FROM 'pending_review'::public.community_post_status
      OR author_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "community_board_select_member" ON public.community_board;
CREATE POLICY "community_board_select_member"
  ON public.community_board
  FOR SELECT
  TO authenticated
  USING (
    public.is_org_member(org_id)
    AND (
      status IS DISTINCT FROM 'pending_review'::public.community_post_status
      OR author_id = (SELECT auth.uid())
      OR public.is_org_management(org_id)
    )
  );

CREATE OR REPLACE FUNCTION public.moderate_community_announcement(
  p_community_id uuid,
  p_post_id uuid,
  p_action text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_org uuid;
  v_post public.community_board%ROWTYPE;
  v_status public.community_post_status;
BEGIN
  IF p_action NOT IN ('publish', 'reject') THEN
    RAISE EXCEPTION 'Nieprawidłowa akcja.';
  END IF;

  v_org := private.estate_require_community_management(p_community_id);

  SELECT * INTO v_post
  FROM public.community_board
  WHERE id = p_post_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Nie znaleziono ogłoszenia.';
  END IF;

  IF v_post.status IS DISTINCT FROM 'pending_review'::public.community_post_status THEN
    RAISE EXCEPTION 'Ogłoszenie nie oczekuje na decyzję.';
  END IF;

  IF v_post.org_id IS DISTINCT FROM v_org THEN
    RAISE EXCEPTION 'Ogłoszenie nie należy do tej wspólnoty.';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.cleaning_locations l
    WHERE l.id = v_post.location_id
      AND l.community_id = p_community_id
  ) THEN
    RAISE EXCEPTION 'Ogłoszenie nie należy do tej wspólnoty.';
  END IF;

  v_status := CASE
    WHEN p_action = 'publish' THEN 'active'::public.community_post_status
    ELSE 'cancelled'::public.community_post_status
  END;

  UPDATE public.community_board
  SET
    status = v_status,
    moderation_hold = NULL
  WHERE id = p_post_id;

  RETURN jsonb_build_object('ok', true, 'status', v_status);
END;
$$;

REVOKE ALL ON FUNCTION public.moderate_community_announcement(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.moderate_community_announcement(uuid, uuid, text) TO authenticated;

COMMIT;
