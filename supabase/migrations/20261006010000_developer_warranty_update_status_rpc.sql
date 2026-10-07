BEGIN;

-- =============================================================================
-- Developer Warranty: RPC for developer to update issue status
-- =============================================================================

-- Function for developer to update issue status
CREATE OR REPLACE FUNCTION public.developer_update_warranty_issue_status(
  p_access_token uuid,
  p_pin text,
  p_issue_id uuid,
  p_new_status developer_warranty_issue_status,
  p_rejection_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_access public.developer_accesses%ROWTYPE;
  v_issue public.developer_warranty_issues%ROWTYPE;
  v_pin_valid boolean;
BEGIN
  -- Validate parameters
  IF p_access_token IS NULL OR p_pin IS NULL OR p_issue_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_parameters');
  END IF;
  
  -- Verify developer credentials
  SELECT * INTO v_access
  FROM public.developer_accesses
  WHERE access_token = p_access_token
    AND activated_at IS NOT NULL
    AND deactivated_at IS NULL;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_credentials');
  END IF;
  
  -- Verify PIN
  v_pin_valid := (v_access.pin_hash = crypt(p_pin, v_access.pin_hash));
  
  IF NOT v_pin_valid THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_credentials');
  END IF;
  
  -- Get issue and verify it belongs to this community
  SELECT * INTO v_issue
  FROM public.developer_warranty_issues
  WHERE id = p_issue_id
    AND community_id = v_access.community_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'issue_not_found');
  END IF;
  
  -- Validate status transition
  IF v_issue.status = 'draft' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'cannot_update_draft');
  END IF;
  
  IF v_issue.status = 'completed' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'issue_already_completed');
  END IF;
  
  -- Validate rejection reason
  IF p_new_status = 'rejected' AND (p_rejection_reason IS NULL OR trim(p_rejection_reason) = '') THEN
    RETURN jsonb_build_object('ok', false, 'error', 'rejection_reason_required');
  END IF;
  
  -- Update issue
  UPDATE public.developer_warranty_issues
  SET 
    status = p_new_status,
    acknowledged_at = CASE 
      WHEN p_new_status = 'acknowledged' THEN now()
      WHEN p_new_status = 'in_progress' AND acknowledged_at IS NULL THEN now()
      ELSE acknowledged_at
    END,
    completed_at = CASE WHEN p_new_status = 'completed' THEN now() ELSE completed_at END,
    rejected_at = CASE WHEN p_new_status = 'rejected' THEN now() ELSE rejected_at END,
    rejection_reason = CASE WHEN p_new_status = 'rejected' THEN p_rejection_reason ELSE rejection_reason END,
    updated_at = now()
  WHERE id = p_issue_id;
  
  RETURN jsonb_build_object('ok', true, 'message', 'status_updated');
END;
$$;

COMMENT ON FUNCTION public.developer_update_warranty_issue_status IS
  'Allows developer to update issue status with PIN authentication';

REVOKE ALL ON FUNCTION public.developer_update_warranty_issue_status FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.developer_update_warranty_issue_status TO anon, authenticated;

-- Function for developer to add comment
CREATE OR REPLACE FUNCTION public.developer_add_warranty_issue_comment(
  p_access_token uuid,
  p_pin text,
  p_issue_id uuid,
  p_comment_text text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_access public.developer_accesses%ROWTYPE;
  v_issue public.developer_warranty_issues%ROWTYPE;
  v_pin_valid boolean;
  v_comment_id uuid;
BEGIN
  -- Validate parameters
  IF p_access_token IS NULL OR p_pin IS NULL OR p_issue_id IS NULL OR trim(p_comment_text) = '' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_parameters');
  END IF;
  
  -- Verify developer credentials
  SELECT * INTO v_access
  FROM public.developer_accesses
  WHERE access_token = p_access_token
    AND activated_at IS NOT NULL
    AND deactivated_at IS NULL;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_credentials');
  END IF;
  
  -- Verify PIN
  v_pin_valid := (v_access.pin_hash = crypt(p_pin, v_access.pin_hash));
  
  IF NOT v_pin_valid THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_credentials');
  END IF;
  
  -- Get issue and verify it belongs to this community
  SELECT * INTO v_issue
  FROM public.developer_warranty_issues
  WHERE id = p_issue_id
    AND community_id = v_access.community_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'issue_not_found');
  END IF;
  
  -- Insert comment
  INSERT INTO public.developer_warranty_issue_comments (
    issue_id,
    author_type,
    author_name,
    comment_text,
    attachments
  ) VALUES (
    p_issue_id,
    'developer',
    v_access.developer_name,
    p_comment_text,
    '{}'
  )
  RETURNING id INTO v_comment_id;
  
  RETURN jsonb_build_object('ok', true, 'comment_id', v_comment_id);
END;
$$;

COMMENT ON FUNCTION public.developer_add_warranty_issue_comment IS
  'Allows developer to add comment to issue with PIN authentication';

REVOKE ALL ON FUNCTION public.developer_add_warranty_issue_comment FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.developer_add_warranty_issue_comment TO anon, authenticated;

COMMIT;
