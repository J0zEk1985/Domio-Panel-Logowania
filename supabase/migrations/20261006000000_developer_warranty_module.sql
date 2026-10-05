BEGIN;

-- =============================================================================
-- DEVELOPER WARRANTY MODULE
-- =============================================================================
-- Moduł zarządzania usterkami deweloperskimi objętymi rękojmią.
-- Poziom: Wspólnota (nie pojedynczy budynek)
-- Bezpieczeństwo: Deweloper sam ustala PIN, Admin nie ma do niego dostępu
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. TYPES
-- -----------------------------------------------------------------------------

CREATE TYPE developer_warranty_issue_status AS ENUM (
  'draft',        -- Szkic (AI lub Admin, nieopublikowany)
  'reported',     -- Zgłoszone przez Admina (widoczne dla Dewelopera)
  'acknowledged', -- Potwierdzone przez Dewelopera
  'in_progress',  -- W trakcie naprawy
  'completed',    -- Usunięte przez Dewelopera
  'rejected',     -- Odrzucone przez Dewelopera
  'appealed'      -- Odwołanie Admina po odrzuceniu
);

COMMENT ON TYPE developer_warranty_issue_status IS 
  'Status lifecycle for developer warranty defects';

-- -----------------------------------------------------------------------------
-- 2. TABLES
-- -----------------------------------------------------------------------------

-- 2.1 Developer Accesses (One per Community)
CREATE TABLE public.developer_accesses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id uuid NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  developer_email text NOT NULL,
  developer_name text NOT NULL,
  
  -- Activation & PIN
  activation_token uuid NOT NULL DEFAULT gen_random_uuid(),
  activation_token_expires_at timestamptz,
  activated_at timestamptz,
  pin_hash text, -- bcrypt hash (set by developer during activation)
  
  -- Stable access token for portal
  access_token uuid NOT NULL DEFAULT gen_random_uuid(),
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  deactivated_at timestamptz,
  deactivated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  last_login_at timestamptz,
  
  CONSTRAINT developer_accesses_community_uidx UNIQUE (community_id),
  CONSTRAINT developer_accesses_activation_token_uidx UNIQUE (activation_token),
  CONSTRAINT developer_accesses_access_token_uidx UNIQUE (access_token),
  CONSTRAINT developer_accesses_email_fmt CHECK (developer_email ~ '^[^@]+@[^@]+\.[^@]+$'),
  CONSTRAINT developer_accesses_pin_hash_when_activated CHECK (
    activated_at IS NULL OR pin_hash IS NOT NULL
  )
);

CREATE INDEX idx_developer_accesses_org ON public.developer_accesses(org_id);
CREATE INDEX idx_developer_accesses_community ON public.developer_accesses(community_id);
CREATE INDEX idx_developer_accesses_activation_token ON public.developer_accesses(activation_token) 
  WHERE activated_at IS NULL;
CREATE INDEX idx_developer_accesses_access_token ON public.developer_accesses(access_token)
  WHERE deactivated_at IS NULL;

COMMENT ON TABLE public.developer_accesses IS 
  'Developer portal access per Community. Developer self-sets PIN after email activation. Admin never sees the PIN.';

-- 2.2 Warranty Issues
CREATE TABLE public.developer_warranty_issues (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id uuid NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  location_master_id uuid REFERENCES public.locations(id) ON DELETE SET NULL,
  
  -- Issue Details
  title text NOT NULL,
  description text,
  category text,
  location_detail text,
  priority text NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  
  -- Photos
  photos_reported text[] NOT NULL DEFAULT '{}',
  photos_completion text[] NOT NULL DEFAULT '{}',
  
  -- Status & Lifecycle Dates
  status developer_warranty_issue_status NOT NULL DEFAULT 'draft',
  reported_at timestamptz,
  acknowledged_at timestamptz,
  completed_at timestamptz,
  rejected_at timestamptz,
  appealed_at timestamptz,
  
  -- Rejection & Appeal
  rejection_reason text,
  appeal_notes text,
  
  -- Source tracking (future AI integration)
  source_type text NOT NULL DEFAULT 'manual' CHECK (source_type IN ('manual', 'ai_protocol')),
  source_metadata jsonb NOT NULL DEFAULT '{}',
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  
  CONSTRAINT warranty_issue_reported_at_when_published CHECK (
    status = 'draft' OR reported_at IS NOT NULL
  ),
  CONSTRAINT warranty_issue_rejection_reason_when_rejected CHECK (
    status != 'rejected' OR rejection_reason IS NOT NULL
  ),
  CONSTRAINT warranty_issue_appeal_notes_when_appealed CHECK (
    status != 'appealed' OR appeal_notes IS NOT NULL
  )
);

CREATE INDEX idx_warranty_issues_community ON public.developer_warranty_issues(community_id);
CREATE INDEX idx_warranty_issues_org ON public.developer_warranty_issues(org_id);
CREATE INDEX idx_warranty_issues_status ON public.developer_warranty_issues(status);
CREATE INDEX idx_warranty_issues_created ON public.developer_warranty_issues(created_at DESC);
CREATE INDEX idx_warranty_issues_location_master ON public.developer_warranty_issues(location_master_id) 
  WHERE location_master_id IS NOT NULL;
CREATE INDEX idx_warranty_issues_community_status ON public.developer_warranty_issues(community_id, status);

COMMENT ON TABLE public.developer_warranty_issues IS 
  'Developer warranty defects at Community level. Tracked from report through resolution or appeal.';

-- 2.3 Issue Comments (Admin ↔ Developer communication)
CREATE TABLE public.developer_warranty_issue_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id uuid NOT NULL REFERENCES public.developer_warranty_issues(id) ON DELETE CASCADE,
  
  -- Author
  author_type text NOT NULL CHECK (author_type IN ('admin', 'developer')),
  author_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  author_name text,
  
  -- Content
  comment_text text NOT NULL,
  attachments text[] NOT NULL DEFAULT '{}',
  
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  
  CONSTRAINT warranty_comment_author_user_when_admin CHECK (
    author_type != 'admin' OR author_user_id IS NOT NULL
  )
);

CREATE INDEX idx_warranty_comments_issue ON public.developer_warranty_issue_comments(issue_id, created_at);
CREATE INDEX idx_warranty_comments_created ON public.developer_warranty_issue_comments(created_at DESC);

COMMENT ON TABLE public.developer_warranty_issue_comments IS 
  'Communication thread between Property Admin and Developer on warranty defects.';

-- 2.4 Issue Events (Audit Trail)
CREATE TABLE public.developer_warranty_issue_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id uuid NOT NULL REFERENCES public.developer_warranty_issues(id) ON DELETE CASCADE,
  
  -- Event
  event_type text NOT NULL,
  old_status developer_warranty_issue_status,
  new_status developer_warranty_issue_status,
  
  -- Actor
  actor_type text NOT NULL CHECK (actor_type IN ('admin', 'developer', 'system')),
  actor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  actor_name text,
  
  -- Details
  event_metadata jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_warranty_events_issue ON public.developer_warranty_issue_events(issue_id, created_at DESC);
CREATE INDEX idx_warranty_events_created ON public.developer_warranty_issue_events(created_at DESC);

COMMENT ON TABLE public.developer_warranty_issue_events IS 
  'Complete audit trail for warranty issue lifecycle.';

-- 2.5 Community Warranty Settings
CREATE TABLE public.community_warranty_settings (
  community_id uuid PRIMARY KEY REFERENCES public.communities(id) ON DELETE CASCADE,
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  
  -- Visibility for residents in Home app
  resident_visibility_enabled boolean NOT NULL DEFAULT false,
  
  -- Audit
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE INDEX idx_community_warranty_settings_org ON public.community_warranty_settings(org_id);

COMMENT ON TABLE public.community_warranty_settings IS 
  'Per-community settings for developer warranty module visibility.';

-- -----------------------------------------------------------------------------
-- 3. ROW LEVEL SECURITY (RLS)
-- -----------------------------------------------------------------------------

-- Enable RLS
ALTER TABLE public.developer_accesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.developer_warranty_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.developer_warranty_issue_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.developer_warranty_issue_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_warranty_settings ENABLE ROW LEVEL SECURITY;

-- 3.1 developer_accesses RLS
-- Admin (owner/manager/admin) can manage developer accesses for their org
CREATE POLICY developer_accesses_select_admin
  ON public.developer_accesses
  FOR SELECT
  TO authenticated
  USING (
    org_id IN (
      SELECT m.org_id 
      FROM public.memberships m 
      WHERE m.user_id = auth.uid() 
        AND m.role IN ('owner', 'manager', 'admin')
    )
  );

CREATE POLICY developer_accesses_insert_admin
  ON public.developer_accesses
  FOR INSERT
  TO authenticated
  WITH CHECK (
    org_id IN (
      SELECT m.org_id 
      FROM public.memberships m 
      WHERE m.user_id = auth.uid() 
        AND m.role IN ('owner', 'manager', 'admin')
    )
  );

CREATE POLICY developer_accesses_update_admin
  ON public.developer_accesses
  FOR UPDATE
  TO authenticated
  USING (
    org_id IN (
      SELECT m.org_id 
      FROM public.memberships m 
      WHERE m.user_id = auth.uid() 
        AND m.role IN ('owner', 'manager', 'admin')
    )
  )
  WITH CHECK (
    org_id IN (
      SELECT m.org_id 
      FROM public.memberships m 
      WHERE m.user_id = auth.uid() 
        AND m.role IN ('owner', 'manager', 'admin')
    )
  );

-- Anonymous can read activation token for activation page (via RPC)
-- No direct SELECT policy for anon - access controlled via RPC

-- 3.2 developer_warranty_issues RLS
-- Admin can CRUD issues for their org
CREATE POLICY warranty_issues_select_admin
  ON public.developer_warranty_issues
  FOR SELECT
  TO authenticated
  USING (
    org_id IN (
      SELECT m.org_id 
      FROM public.memberships m 
      WHERE m.user_id = auth.uid() 
        AND m.role IN ('owner', 'manager', 'admin', 'coordinator')
    )
  );

CREATE POLICY warranty_issues_insert_admin
  ON public.developer_warranty_issues
  FOR INSERT
  TO authenticated
  WITH CHECK (
    org_id IN (
      SELECT m.org_id 
      FROM public.memberships m 
      WHERE m.user_id = auth.uid() 
        AND m.role IN ('owner', 'manager', 'admin', 'coordinator')
    )
  );

CREATE POLICY warranty_issues_update_admin
  ON public.developer_warranty_issues
  FOR UPDATE
  TO authenticated
  USING (
    org_id IN (
      SELECT m.org_id 
      FROM public.memberships m 
      WHERE m.user_id = auth.uid() 
        AND m.role IN ('owner', 'manager', 'admin', 'coordinator')
    )
  )
  WITH CHECK (
    org_id IN (
      SELECT m.org_id 
      FROM public.memberships m 
      WHERE m.user_id = auth.uid() 
        AND m.role IN ('owner', 'manager', 'admin', 'coordinator')
    )
  );

CREATE POLICY warranty_issues_delete_admin
  ON public.developer_warranty_issues
  FOR DELETE
  TO authenticated
  USING (
    org_id IN (
      SELECT m.org_id 
      FROM public.memberships m 
      WHERE m.user_id = auth.uid() 
        AND m.role IN ('owner', 'manager', 'admin')
    )
  );

-- Residents can SELECT issues if visibility is enabled (via RPC or special policy)
CREATE POLICY warranty_issues_select_residents
  ON public.developer_warranty_issues
  FOR SELECT
  TO authenticated
  USING (
    status != 'draft' 
    AND community_id IN (
      SELECT cu.community_id
      FROM public.community_units cu
      INNER JOIN public.community_unit_occupants cuo ON cuo.unit_id = cu.id
      WHERE cuo.user_id = auth.uid()
    )
    AND EXISTS (
      SELECT 1
      FROM public.community_warranty_settings cws
      WHERE cws.community_id = developer_warranty_issues.community_id
        AND cws.resident_visibility_enabled = true
    )
  );

-- 3.3 developer_warranty_issue_comments RLS
CREATE POLICY warranty_comments_select_admin
  ON public.developer_warranty_issue_comments
  FOR SELECT
  TO authenticated
  USING (
    issue_id IN (
      SELECT dwi.id
      FROM public.developer_warranty_issues dwi
      WHERE dwi.org_id IN (
        SELECT m.org_id 
        FROM public.memberships m 
        WHERE m.user_id = auth.uid() 
          AND m.role IN ('owner', 'manager', 'admin', 'coordinator')
      )
    )
  );

CREATE POLICY warranty_comments_insert_admin
  ON public.developer_warranty_issue_comments
  FOR INSERT
  TO authenticated
  WITH CHECK (
    author_type = 'admin'
    AND author_user_id = auth.uid()
    AND issue_id IN (
      SELECT dwi.id
      FROM public.developer_warranty_issues dwi
      WHERE dwi.org_id IN (
        SELECT m.org_id 
        FROM public.memberships m 
        WHERE m.user_id = auth.uid() 
          AND m.role IN ('owner', 'manager', 'admin', 'coordinator')
      )
    )
  );

-- Residents can SELECT comments if visibility is enabled
CREATE POLICY warranty_comments_select_residents
  ON public.developer_warranty_issue_comments
  FOR SELECT
  TO authenticated
  USING (
    issue_id IN (
      SELECT dwi.id
      FROM public.developer_warranty_issues dwi
      INNER JOIN public.community_units cu ON cu.community_id = dwi.community_id
      INNER JOIN public.community_unit_occupants cuo ON cuo.unit_id = cu.id
      INNER JOIN public.community_warranty_settings cws ON cws.community_id = dwi.community_id
      WHERE cuo.user_id = auth.uid()
        AND cws.resident_visibility_enabled = true
        AND dwi.status != 'draft'
    )
  );

-- 3.4 developer_warranty_issue_events RLS (read-only audit trail)
CREATE POLICY warranty_events_select_admin
  ON public.developer_warranty_issue_events
  FOR SELECT
  TO authenticated
  USING (
    issue_id IN (
      SELECT dwi.id
      FROM public.developer_warranty_issues dwi
      WHERE dwi.org_id IN (
        SELECT m.org_id 
        FROM public.memberships m 
        WHERE m.user_id = auth.uid() 
          AND m.role IN ('owner', 'manager', 'admin', 'coordinator')
      )
    )
  );

-- 3.5 community_warranty_settings RLS
CREATE POLICY warranty_settings_select_admin
  ON public.community_warranty_settings
  FOR SELECT
  TO authenticated
  USING (
    org_id IN (
      SELECT m.org_id 
      FROM public.memberships m 
      WHERE m.user_id = auth.uid() 
        AND m.role IN ('owner', 'manager', 'admin', 'coordinator')
    )
  );

CREATE POLICY warranty_settings_insert_admin
  ON public.community_warranty_settings
  FOR INSERT
  TO authenticated
  WITH CHECK (
    org_id IN (
      SELECT m.org_id 
      FROM public.memberships m 
      WHERE m.user_id = auth.uid() 
        AND m.role IN ('owner', 'manager', 'admin')
    )
  );

CREATE POLICY warranty_settings_update_admin
  ON public.community_warranty_settings
  FOR UPDATE
  TO authenticated
  USING (
    org_id IN (
      SELECT m.org_id 
      FROM public.memberships m 
      WHERE m.user_id = auth.uid() 
        AND m.role IN ('owner', 'manager', 'admin')
    )
  )
  WITH CHECK (
    org_id IN (
      SELECT m.org_id 
      FROM public.memberships m 
      WHERE m.user_id = auth.uid() 
        AND m.role IN ('owner', 'manager', 'admin')
    )
  );

-- -----------------------------------------------------------------------------
-- 4. RPC FUNCTIONS (SECURITY DEFINER)
-- -----------------------------------------------------------------------------

-- 4.1 Send Developer Activation Email (triggers n8n webhook)
-- This is a placeholder - actual email sending will be done via n8n
CREATE OR REPLACE FUNCTION public.create_developer_access_and_send_invite(
  p_community_id uuid,
  p_developer_email text,
  p_developer_name text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_org_id uuid;
  v_access_id uuid;
  v_activation_token uuid;
  v_existing_access public.developer_accesses%ROWTYPE;
BEGIN
  -- Verify caller is admin of the community's org
  SELECT c.org_id INTO v_org_id
  FROM public.communities c
  WHERE c.id = p_community_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'community_not_found');
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM public.memberships m
    WHERE m.org_id = v_org_id
      AND m.user_id = auth.uid()
      AND m.role IN ('owner', 'manager', 'admin')
  ) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'unauthorized');
  END IF;
  
  -- Check if developer access already exists for this community
  SELECT * INTO v_existing_access
  FROM public.developer_accesses
  WHERE community_id = p_community_id;
  
  IF FOUND THEN
    RETURN jsonb_build_object(
      'ok', false, 
      'error', 'developer_access_already_exists',
      'existing_email', v_existing_access.developer_email
    );
  END IF;
  
  -- Insert developer access
  INSERT INTO public.developer_accesses (
    community_id,
    org_id,
    developer_email,
    developer_name,
    activation_token_expires_at,
    created_by
  ) VALUES (
    p_community_id,
    v_org_id,
    p_developer_email,
    p_developer_name,
    now() + interval '7 days', -- Token expires in 7 days
    auth.uid()
  )
  RETURNING id, activation_token INTO v_access_id, v_activation_token;
  
  -- TODO: Trigger n8n webhook for email sending
  -- For now, return activation URL
  
  RETURN jsonb_build_object(
    'ok', true,
    'access_id', v_access_id,
    'activation_token', v_activation_token,
    'activation_url', format('/deweloper/aktywacja/%s', v_activation_token::text)
  );
END;
$$;

COMMENT ON FUNCTION public.create_developer_access_and_send_invite IS
  'Creates developer access and returns activation token. Admin only. Triggers email via n8n.';

REVOKE ALL ON FUNCTION public.create_developer_access_and_send_invite FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_developer_access_and_send_invite TO authenticated;

-- 4.2 Get Developer Access Info by Activation Token (anonymous)
CREATE OR REPLACE FUNCTION public.get_developer_activation_info(
  p_activation_token uuid
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_access public.developer_accesses%ROWTYPE;
  v_community public.communities%ROWTYPE;
BEGIN
  IF p_activation_token IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_token');
  END IF;
  
  SELECT * INTO v_access
  FROM public.developer_accesses
  WHERE activation_token = p_activation_token
    AND activated_at IS NULL
    AND (activation_token_expires_at IS NULL OR activation_token_expires_at > now())
    AND deactivated_at IS NULL;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'token_invalid_or_expired');
  END IF;
  
  SELECT * INTO v_community
  FROM public.communities
  WHERE id = v_access.community_id;
  
  RETURN jsonb_build_object(
    'ok', true,
    'developer_name', v_access.developer_name,
    'developer_email', v_access.developer_email,
    'community_name', v_community.name,
    'community_legal_name', v_community.legal_name
  );
END;
$$;

COMMENT ON FUNCTION public.get_developer_activation_info IS
  'Anonymous function to get developer info during activation flow.';

REVOKE ALL ON FUNCTION public.get_developer_activation_info FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_developer_activation_info TO anon, authenticated;

-- 4.3 Activate Developer Access with PIN (anonymous)
CREATE OR REPLACE FUNCTION public.activate_developer_access(
  p_activation_token uuid,
  p_pin text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_access_id uuid;
  v_pin_hash text;
BEGIN
  IF p_activation_token IS NULL OR p_pin IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_parameters');
  END IF;
  
  -- Validate PIN format (4-6 digits)
  IF p_pin !~ '^\d{4,6}$' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'pin_must_be_4_to_6_digits');
  END IF;
  
  -- Check if token exists and is not activated
  SELECT id INTO v_access_id
  FROM public.developer_accesses
  WHERE activation_token = p_activation_token
    AND activated_at IS NULL
    AND (activation_token_expires_at IS NULL OR activation_token_expires_at > now())
    AND deactivated_at IS NULL;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'token_invalid_or_expired');
  END IF;
  
  -- Hash PIN using pgcrypto (bcrypt)
  v_pin_hash := crypt(p_pin, gen_salt('bf', 10));
  
  -- Activate access
  UPDATE public.developer_accesses
  SET 
    activated_at = now(),
    pin_hash = v_pin_hash,
    activation_token_expires_at = now() -- Expire token immediately after use
  WHERE id = v_access_id;
  
  RETURN jsonb_build_object('ok', true, 'message', 'activation_successful');
END;
$$;

COMMENT ON FUNCTION public.activate_developer_access IS
  'Anonymous function to activate developer access by setting PIN. Token becomes invalid after activation.';

REVOKE ALL ON FUNCTION public.activate_developer_access FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.activate_developer_access TO anon, authenticated;

-- 4.4 Developer Login with Access Token and PIN (anonymous)
CREATE OR REPLACE FUNCTION public.developer_portal_login(
  p_access_token uuid,
  p_pin text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_access public.developer_accesses%ROWTYPE;
  v_pin_valid boolean;
BEGIN
  IF p_access_token IS NULL OR p_pin IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_credentials');
  END IF;
  
  -- Get access record
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
  
  -- Update last login
  UPDATE public.developer_accesses
  SET last_login_at = now()
  WHERE id = v_access.id;
  
  RETURN jsonb_build_object(
    'ok', true,
    'access_id', v_access.id,
    'community_id', v_access.community_id,
    'developer_name', v_access.developer_name,
    'developer_email', v_access.developer_email
  );
END;
$$;

COMMENT ON FUNCTION public.developer_portal_login IS
  'Anonymous function for developer portal login. Validates PIN and returns session data.';

REVOKE ALL ON FUNCTION public.developer_portal_login FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.developer_portal_login TO anon, authenticated;

-- 4.5 Get Developer Portal Data (issues, comments for community)
CREATE OR REPLACE FUNCTION public.get_developer_portal_data(
  p_access_token uuid,
  p_pin text
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_access public.developer_accesses%ROWTYPE;
  v_pin_valid boolean;
  v_issues jsonb;
  v_community jsonb;
BEGIN
  IF p_access_token IS NULL OR p_pin IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_credentials');
  END IF;
  
  -- Verify credentials
  SELECT * INTO v_access
  FROM public.developer_accesses
  WHERE access_token = p_access_token
    AND activated_at IS NOT NULL
    AND deactivated_at IS NULL;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_credentials');
  END IF;
  
  v_pin_valid := (v_access.pin_hash = crypt(p_pin, v_access.pin_hash));
  
  IF NOT v_pin_valid THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_credentials');
  END IF;
  
  -- Get community data
  SELECT jsonb_build_object(
    'id', c.id,
    'name', c.name,
    'legal_name', c.legal_name
  ) INTO v_community
  FROM public.communities c
  WHERE c.id = v_access.community_id;
  
  -- Get issues with comments
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', dwi.id,
      'title', dwi.title,
      'description', dwi.description,
      'category', dwi.category,
      'location_detail', dwi.location_detail,
      'priority', dwi.priority,
      'status', dwi.status,
      'photos_reported', dwi.photos_reported,
      'photos_completion', dwi.photos_completion,
      'rejection_reason', dwi.rejection_reason,
      'appeal_notes', dwi.appeal_notes,
      'reported_at', dwi.reported_at,
      'acknowledged_at', dwi.acknowledged_at,
      'completed_at', dwi.completed_at,
      'rejected_at', dwi.rejected_at,
      'appealed_at', dwi.appealed_at,
      'created_at', dwi.created_at,
      'updated_at', dwi.updated_at,
      'comments', (
        SELECT COALESCE(jsonb_agg(
          jsonb_build_object(
            'id', c.id,
            'author_type', c.author_type,
            'author_name', c.author_name,
            'comment_text', c.comment_text,
            'attachments', c.attachments,
            'created_at', c.created_at
          ) ORDER BY c.created_at ASC
        ), '[]'::jsonb)
        FROM public.developer_warranty_issue_comments c
        WHERE c.issue_id = dwi.id
      )
    ) ORDER BY dwi.created_at DESC
  ), '[]'::jsonb) INTO v_issues
  FROM public.developer_warranty_issues dwi
  WHERE dwi.community_id = v_access.community_id
    AND dwi.status != 'draft';
  
  RETURN jsonb_build_object(
    'ok', true,
    'community', v_community,
    'issues', v_issues
  );
END;
$$;

COMMENT ON FUNCTION public.get_developer_portal_data IS
  'Anonymous function to get all warranty issues and comments for developer portal.';

REVOKE ALL ON FUNCTION public.get_developer_portal_data FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_developer_portal_data TO anon, authenticated;

-- -----------------------------------------------------------------------------
-- 5. TRIGGERS (Audit Trail & Lifecycle)
-- -----------------------------------------------------------------------------

-- 5.1 Trigger to log issue lifecycle events
CREATE OR REPLACE FUNCTION private.trg_log_warranty_issue_lifecycle()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_event_type text;
  v_actor_type text;
  v_actor_name text;
BEGIN
  -- Determine event type
  IF TG_OP = 'INSERT' THEN
    v_event_type := 'created';
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      v_event_type := 'status_changed';
    ELSIF OLD.photos_completion IS DISTINCT FROM NEW.photos_completion THEN
      v_event_type := 'photos_added';
    ELSE
      v_event_type := 'updated';
    END IF;
  END IF;
  
  -- Determine actor (simplified - will be enhanced with developer context)
  v_actor_type := 'admin';
  v_actor_name := (
    SELECT COALESCE(p.display_name, p.email)
    FROM public.profiles p
    WHERE p.id = auth.uid()
    LIMIT 1
  );
  
  -- Log event
  INSERT INTO public.developer_warranty_issue_events (
    issue_id,
    event_type,
    old_status,
    new_status,
    actor_type,
    actor_user_id,
    actor_name,
    event_metadata
  ) VALUES (
    NEW.id,
    v_event_type,
    CASE WHEN TG_OP = 'UPDATE' THEN OLD.status ELSE NULL END,
    NEW.status,
    v_actor_type,
    auth.uid(),
    v_actor_name,
    jsonb_build_object(
      'operation', TG_OP,
      'changed_fields', CASE 
        WHEN TG_OP = 'UPDATE' THEN jsonb_build_object(
          'status', (OLD.status IS DISTINCT FROM NEW.status),
          'photos_completion', (OLD.photos_completion IS DISTINCT FROM NEW.photos_completion)
        )
        ELSE '{}'::jsonb
      END
    )
  );
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_log_warranty_issue_lifecycle
  AFTER INSERT OR UPDATE ON public.developer_warranty_issues
  FOR EACH ROW
  EXECUTE FUNCTION private.trg_log_warranty_issue_lifecycle();

-- 5.2 Trigger to auto-update updated_at on issues
CREATE OR REPLACE FUNCTION private.trg_update_warranty_issue_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  NEW.updated_by := auth.uid();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_warranty_issue_timestamp
  BEFORE UPDATE ON public.developer_warranty_issues
  FOR EACH ROW
  EXECUTE FUNCTION private.trg_update_warranty_issue_timestamp();

-- 5.3 Trigger to auto-update updated_at on settings
CREATE OR REPLACE FUNCTION private.trg_update_warranty_settings_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  NEW.updated_by := auth.uid();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_warranty_settings_timestamp
  BEFORE UPDATE ON public.community_warranty_settings
  FOR EACH ROW
  EXECUTE FUNCTION private.trg_update_warranty_settings_timestamp();

-- -----------------------------------------------------------------------------
-- 6. GRANTS
-- -----------------------------------------------------------------------------

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public.developer_accesses TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.developer_warranty_issues TO authenticated;
GRANT SELECT, INSERT ON public.developer_warranty_issue_comments TO authenticated;
GRANT SELECT ON public.developer_warranty_issue_events TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.community_warranty_settings TO authenticated;

COMMIT;
