BEGIN;

-- =============================================================================
-- Developer Warranty: Webhook notifications for n8n
-- =============================================================================

-- Function to notify about developer access creation (for n8n email)
CREATE OR REPLACE FUNCTION private.notify_developer_access_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_community public.communities%ROWTYPE;
  v_webhook_payload jsonb;
BEGIN
  -- Get community details
  SELECT * INTO v_community
  FROM public.communities
  WHERE id = NEW.community_id;
  
  -- Build webhook payload
  v_webhook_payload := jsonb_build_object(
    'event', 'developer_access_created',
    'timestamp', now(),
    'data', jsonb_build_object(
      'access_id', NEW.id,
      'developer_email', NEW.developer_email,
      'developer_name', NEW.developer_name,
      'activation_token', NEW.activation_token,
      'activation_url', format('https://admin.domio.com.pl/deweloper/aktywacja/%s', NEW.activation_token),
      'community', jsonb_build_object(
        'id', v_community.id,
        'name', v_community.name,
        'legal_name', v_community.legal_name
      )
    )
  );
  
  -- Insert into webhooks table for n8n to pick up
  INSERT INTO public.webhooks (
    org_id,
    event_type,
    payload,
    status
  ) VALUES (
    NEW.org_id,
    'developer_warranty.access_created',
    v_webhook_payload,
    'pending'
  );
  
  RETURN NEW;
END;
$$;

-- Trigger to notify when developer access is created
CREATE TRIGGER trg_notify_developer_access_created
  AFTER INSERT ON public.developer_accesses
  FOR EACH ROW
  EXECUTE FUNCTION private.notify_developer_access_created();

-- Function to notify about issue status changes
CREATE OR REPLACE FUNCTION private.notify_warranty_issue_status_changed()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_community public.communities%ROWTYPE;
  v_developer_access public.developer_accesses%ROWTYPE;
  v_webhook_payload jsonb;
BEGIN
  -- Only notify if status actually changed and it's published
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status != 'draft' THEN
    
    -- Get community details
    SELECT * INTO v_community
    FROM public.communities
    WHERE id = NEW.community_id;
    
    -- Get developer access
    SELECT * INTO v_developer_access
    FROM public.developer_accesses
    WHERE community_id = NEW.community_id
      AND deactivated_at IS NULL;
    
    -- Build webhook payload
    v_webhook_payload := jsonb_build_object(
      'event', 'warranty_issue_status_changed',
      'timestamp', now(),
      'data', jsonb_build_object(
        'issue_id', NEW.id,
        'title', NEW.title,
        'old_status', OLD.status,
        'new_status', NEW.status,
        'developer_email', v_developer_access.developer_email,
        'developer_name', v_developer_access.developer_name,
        'community', jsonb_build_object(
          'id', v_community.id,
          'name', v_community.name,
          'legal_name', v_community.legal_name
        )
      )
    );
    
    -- Insert into webhooks table
    INSERT INTO public.webhooks (
      org_id,
      event_type,
      payload,
      status
    ) VALUES (
      NEW.org_id,
      'developer_warranty.status_changed',
      v_webhook_payload,
      'pending'
    );
    
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger to notify when issue status changes
CREATE TRIGGER trg_notify_warranty_issue_status_changed
  AFTER UPDATE ON public.developer_warranty_issues
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION private.notify_warranty_issue_status_changed();

-- Function to notify about new comments
CREATE OR REPLACE FUNCTION private.notify_warranty_issue_comment_added()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_issue public.developer_warranty_issues%ROWTYPE;
  v_community public.communities%ROWTYPE;
  v_developer_access public.developer_accesses%ROWTYPE;
  v_webhook_payload jsonb;
  v_notify_email text;
BEGIN
  -- Get issue details
  SELECT * INTO v_issue
  FROM public.developer_warranty_issues
  WHERE id = NEW.issue_id;
  
  -- Get community details
  SELECT * INTO v_community
  FROM public.communities
  WHERE id = v_issue.community_id;
  
  -- Get developer access
  SELECT * INTO v_developer_access
  FROM public.developer_accesses
  WHERE community_id = v_issue.community_id
    AND deactivated_at IS NULL;
  
  -- Determine who to notify based on comment author
  IF NEW.author_type = 'admin' THEN
    -- Admin commented -> notify developer
    v_notify_email := v_developer_access.developer_email;
  ELSIF NEW.author_type = 'developer' THEN
    -- Developer commented -> notify admin (org support email or default)
    v_notify_email := v_community.board_email;
  END IF;
  
  -- Only send if we have an email to notify
  IF v_notify_email IS NOT NULL THEN
    -- Build webhook payload
    v_webhook_payload := jsonb_build_object(
      'event', 'warranty_issue_comment_added',
      'timestamp', now(),
      'data', jsonb_build_object(
        'issue_id', v_issue.id,
        'issue_title', v_issue.title,
        'comment_id', NEW.id,
        'comment_text', NEW.comment_text,
        'author_type', NEW.author_type,
        'author_name', NEW.author_name,
        'notify_email', v_notify_email,
        'community', jsonb_build_object(
          'id', v_community.id,
          'name', v_community.name,
          'legal_name', v_community.legal_name
        )
      )
    );
    
    -- Insert into webhooks table
    INSERT INTO public.webhooks (
      org_id,
      event_type,
      payload,
      status
    ) VALUES (
      v_issue.org_id,
      'developer_warranty.comment_added',
      v_webhook_payload,
      'pending'
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger to notify when comment is added
CREATE TRIGGER trg_notify_warranty_issue_comment_added
  AFTER INSERT ON public.developer_warranty_issue_comments
  FOR EACH ROW
  EXECUTE FUNCTION private.notify_warranty_issue_comment_added();

COMMIT;
