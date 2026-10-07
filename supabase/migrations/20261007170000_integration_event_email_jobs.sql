BEGIN;

-- n8n polls these jobs (same pattern as fleet deadline mail) and sends SMTP.

ALTER TABLE public.integration_events
  ADD COLUMN IF NOT EXISTS attempt_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS next_attempt_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS provider_message_id text;

CREATE OR REPLACE FUNCTION private.html_escape(p_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT replace(replace(replace(replace(COALESCE(p_text, ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;');
$$;

REVOKE ALL ON FUNCTION private.html_escape(text) FROM PUBLIC;

CREATE OR REPLACE FUNCTION private.warranty_status_label(p_status text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_status
    WHEN 'draft' THEN 'Szkic'
    WHEN 'reported' THEN 'Zgłoszone'
    WHEN 'acknowledged' THEN 'Potwierdzone'
    WHEN 'in_progress' THEN 'W trakcie naprawy'
    WHEN 'completed' THEN 'Zakończone'
    WHEN 'rejected' THEN 'Odrzucone'
    WHEN 'appealed' THEN 'Odwołanie'
    ELSE COALESCE(p_status, '—')
  END;
$$;

REVOKE ALL ON FUNCTION private.warranty_status_label(text) FROM PUBLIC;

-- Activation link must match the admin app host (adm.domio.com.pl).
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

CREATE OR REPLACE FUNCTION private.ping_developer_warranty_mailer()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = net, public, pg_temp
AS $$
BEGIN
  IF NEW.event_type LIKE 'developer_warranty.%' THEN
    PERFORM net.http_post(
      url := 'https://n8n.j0zek.pl/webhook/developer-warranty-mail',
      body := '{}'::jsonb,
      params := '{}'::jsonb,
      headers := '{"Content-Type": "application/json"}'::jsonb,
      timeout_milliseconds := 5000
    );
  END IF;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'developer warranty mailer ping failed: %', SQLERRM;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ping_developer_warranty_mailer ON public.integration_events;
CREATE TRIGGER trg_ping_developer_warranty_mailer
  AFTER INSERT ON public.integration_events
  FOR EACH ROW
  EXECUTE FUNCTION private.ping_developer_warranty_mailer();

CREATE OR REPLACE FUNCTION public.claim_integration_event_jobs(p_limit integer DEFAULT 10)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_limit integer := GREATEST(1, LEAST(COALESCE(p_limit, 10), 50));
  v_row public.integration_events%ROWTYPE;
  v_items jsonb := '[]'::jsonb;
  v_data jsonb;
  v_to text;
  v_subject text;
  v_html text;
  v_community text;
  v_url text;
  v_title text;
  v_author text;
BEGIN
  FOR v_row IN
    SELECT *
    FROM public.integration_events
    WHERE status IN ('pending', 'failed', 'processing')
      AND next_attempt_at <= now()
      AND attempt_count < 8
      AND event_type LIKE 'developer_warranty.%'
    ORDER BY created_at
    FOR UPDATE SKIP LOCKED
    LIMIT v_limit
  LOOP
    v_data := COALESCE(v_row.payload -> 'data', '{}'::jsonb);
    v_community := private.html_escape(
      COALESCE(NULLIF(v_data #>> '{community,legal_name}', ''), NULLIF(v_data #>> '{community,name}', ''), 'Wspólnota')
    );
    v_to := NULLIF(btrim(COALESCE(v_data->>'notify_email', v_data->>'developer_email', '')), '');
    v_subject := NULL;
    v_html := NULL;

    IF v_row.event_type = 'developer_warranty.access_created' THEN
      v_url := 'https://adm.domio.com.pl/deweloper/aktywacja/' || COALESCE(v_data->>'activation_token', '');
      v_subject := 'DOMIO — aktywacja dostępu dewelopera';
      v_html := format(
        '<div style="font-family:Arial,sans-serif;line-height:1.5;color:#1f2937">'
        || '<p>Dzień dobry,</p>'
        || '<p>Otrzymujesz dostęp do portalu usterek deweloperskich wspólnoty <strong>%s</strong> w systemie DOMIO.</p>'
        || '<p>Po wejściu w link ustawisz własny PIN (4–6 cyfr). Administrator nie widzi tego PIN-u.</p>'
        || '<p><a href="%s">Aktywuj dostęp</a></p>'
        || '<p style="font-size:12px;color:#6b7280">Jeśli link się nie otwiera, skopiuj adres:<br>%s</p>'
        || '</div>',
        v_community,
        private.html_escape(v_url),
        private.html_escape(v_url)
      );
    ELSIF v_row.event_type = 'developer_warranty.status_changed' THEN
      v_title := private.html_escape(COALESCE(v_data->>'title', 'Usterka'));
      v_subject := 'DOMIO — zmiana statusu usterki';
      v_html := format(
        '<div style="font-family:Arial,sans-serif;line-height:1.5;color:#1f2937">'
        || '<p>Dzień dobry,</p>'
        || '<p>Status usterki <strong>%s</strong> we wspólnocie <strong>%s</strong> zmienił się z „%s” na „%s”.</p>'
        || '</div>',
        v_title,
        v_community,
        private.html_escape(private.warranty_status_label(v_data->>'old_status')),
        private.html_escape(private.warranty_status_label(v_data->>'new_status'))
      );
    ELSIF v_row.event_type = 'developer_warranty.comment_added' THEN
      v_title := private.html_escape(COALESCE(v_data->>'issue_title', 'Usterka'));
      v_author := private.html_escape(
        CASE v_data->>'author_type'
          WHEN 'admin' THEN 'Administrator'
          WHEN 'developer' THEN 'Deweloper'
          ELSE COALESCE(v_data->>'author_type', 'Użytkownik')
        END
        || COALESCE(' — ' || NULLIF(v_data->>'author_name', ''), '')
      );
      v_subject := 'DOMIO — nowy komentarz do usterki';
      v_html := format(
        '<div style="font-family:Arial,sans-serif;line-height:1.5;color:#1f2937">'
        || '<p>Dzień dobry,</p>'
        || '<p>Nowy komentarz (%s) do usterki <strong>%s</strong> we wspólnocie <strong>%s</strong>:</p>'
        || '<blockquote style="margin:12px 0;padding:8px 12px;border-left:3px solid #d1d5db">%s</blockquote>'
        || '</div>',
        v_author,
        v_title,
        v_community,
        private.html_escape(left(COALESCE(v_data->>'comment_text', ''), 4000))
      );
    END IF;

    IF v_to IS NULL OR v_to !~* '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' OR v_subject IS NULL OR v_html IS NULL THEN
      UPDATE public.integration_events
      SET status = 'failed',
          attempt_count = attempt_count + 1,
          error_detail = 'missing recipient or unsupported event',
          next_attempt_at = now() + interval '1 day'
      WHERE id = v_row.id;
      CONTINUE;
    END IF;

    UPDATE public.integration_events
    SET status = 'processing',
        attempt_count = attempt_count + 1,
        next_attempt_at = now() + interval '2 minutes'
    WHERE id = v_row.id;

    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'dispatch_id', v_row.id,
      'to_email', v_to,
      'subject', v_subject,
      'html', v_html,
      'already_sent', false
    ));
  END LOOP;

  RETURN v_items;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_integration_event_sent(
  p_dispatch_id uuid,
  p_message_id text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE public.integration_events
  SET status = 'sent',
      processed_at = now(),
      error_detail = NULL,
      provider_message_id = COALESCE(NULLIF(btrim(COALESCE(p_message_id, '')), ''), provider_message_id)
  WHERE id = p_dispatch_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_integration_event_failed(
  p_dispatch_id uuid,
  p_error text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_attempts integer;
BEGIN
  SELECT attempt_count INTO v_attempts
  FROM public.integration_events
  WHERE id = p_dispatch_id;

  UPDATE public.integration_events
  SET status = 'failed',
      error_detail = left(COALESCE(NULLIF(btrim(p_error), ''), 'SMTP send failed'), 2000),
      next_attempt_at = now() + (interval '5 minutes' * GREATEST(1, COALESCE(v_attempts, 1)))
  WHERE id = p_dispatch_id
    AND status IS DISTINCT FROM 'sent';
END;
$$;

REVOKE ALL ON FUNCTION public.claim_integration_event_jobs(integer) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.mark_integration_event_sent(uuid, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.mark_integration_event_failed(uuid, text) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.claim_integration_event_jobs(integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.mark_integration_event_sent(uuid, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.mark_integration_event_failed(uuid, text) TO service_role;

NOTIFY pgrst, 'reload schema';

COMMIT;
