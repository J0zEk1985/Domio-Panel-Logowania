BEGIN;

-- The warranty notify triggers inserted into public.webhooks (url, secret, headers),
-- which is a destination registry and has no payload/status columns.
-- That rolled back developer access creation with:
--   column "payload" of relation "webhooks" does not exist
-- Queue the same events in an outbox n8n can poll.

CREATE TABLE IF NOT EXISTS public.integration_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  event_type text NOT NULL,
  payload jsonb NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  error_detail text,
  CONSTRAINT integration_events_status_check
    CHECK (status IN ('pending', 'processing', 'sent', 'failed')),
  CONSTRAINT integration_events_payload_object
    CHECK (jsonb_typeof(payload) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_integration_events_pending
  ON public.integration_events (created_at)
  WHERE status = 'pending';

COMMENT ON TABLE public.integration_events IS
  'Outbound integration outbox. n8n polls rows with status = pending.';

ALTER TABLE public.integration_events ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.integration_events FROM PUBLIC, anon, authenticated;
GRANT SELECT, UPDATE ON TABLE public.integration_events TO service_role;

CREATE OR REPLACE FUNCTION private.notify_developer_access_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_community public.communities%ROWTYPE;
  v_webhook_payload jsonb;
BEGIN
  SELECT * INTO v_community
  FROM public.communities
  WHERE id = NEW.community_id;

  v_webhook_payload := jsonb_build_object(
    'event', 'developer_access_created',
    'timestamp', now(),
    'data', jsonb_build_object(
      'access_id', NEW.id,
      'developer_email', NEW.developer_email,
      'developer_name', NEW.developer_name,
      'activation_token', NEW.activation_token,
      'activation_url', format('https://adm.domio.com.pl/deweloper/aktywacja/%s', NEW.activation_token),
      'community', jsonb_build_object(
        'id', v_community.id,
        'name', v_community.name,
        'legal_name', v_community.legal_name
      )
    )
  );

  BEGIN
    INSERT INTO public.integration_events (org_id, event_type, payload, status)
    VALUES (NEW.org_id, 'developer_warranty.access_created', v_webhook_payload, 'pending');
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'developer access event enqueue failed: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION private.notify_warranty_issue_status_changed()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_community public.communities%ROWTYPE;
  v_developer_access public.developer_accesses%ROWTYPE;
  v_webhook_payload jsonb;
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status != 'draft' THEN
    SELECT * INTO v_community
    FROM public.communities
    WHERE id = NEW.community_id;

    SELECT * INTO v_developer_access
    FROM public.developer_accesses
    WHERE community_id = NEW.community_id
      AND deactivated_at IS NULL;

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

    BEGIN
      INSERT INTO public.integration_events (org_id, event_type, payload, status)
      VALUES (NEW.org_id, 'developer_warranty.status_changed', v_webhook_payload, 'pending');
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'warranty status event enqueue failed: %', SQLERRM;
    END;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION private.notify_warranty_issue_comment_added()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_issue public.developer_warranty_issues%ROWTYPE;
  v_community public.communities%ROWTYPE;
  v_developer_access public.developer_accesses%ROWTYPE;
  v_webhook_payload jsonb;
  v_notify_email text;
BEGIN
  SELECT * INTO v_issue
  FROM public.developer_warranty_issues
  WHERE id = NEW.issue_id;

  SELECT * INTO v_community
  FROM public.communities
  WHERE id = v_issue.community_id;

  SELECT * INTO v_developer_access
  FROM public.developer_accesses
  WHERE community_id = v_issue.community_id
    AND deactivated_at IS NULL;

  IF NEW.author_type = 'admin' THEN
    v_notify_email := v_developer_access.developer_email;
  ELSIF NEW.author_type = 'developer' THEN
    v_notify_email := v_community.board_email;
  END IF;

  IF v_notify_email IS NOT NULL THEN
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

    BEGIN
      INSERT INTO public.integration_events (org_id, event_type, payload, status)
      VALUES (v_issue.org_id, 'developer_warranty.comment_added', v_webhook_payload, 'pending');
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'warranty comment event enqueue failed: %', SQLERRM;
    END;
  END IF;

  RETURN NEW;
END;
$$;

COMMIT;
