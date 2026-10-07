BEGIN;

-- Portal login URL is stable (access_token). The activation URL works only until the PIN is set.

CREATE OR REPLACE FUNCTION private.notify_developer_access_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_community public.communities%ROWTYPE;
  v_webhook_payload jsonb;
  v_portal_url text;
BEGIN
  SELECT * INTO v_community
  FROM public.communities
  WHERE id = NEW.community_id;

  v_portal_url := format('https://adm.domio.com.pl/deweloper/%s', NEW.access_token);

  v_webhook_payload := jsonb_build_object(
    'event', 'developer_access_created',
    'timestamp', now(),
    'data', jsonb_build_object(
      'access_id', NEW.id,
      'developer_email', NEW.developer_email,
      'developer_name', NEW.developer_name,
      'activation_token', NEW.activation_token,
      'activation_url', format('https://adm.domio.com.pl/deweloper/aktywacja/%s', NEW.activation_token),
      'access_token', NEW.access_token,
      'portal_url', v_portal_url,
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
  v_portal text;
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
      v_portal := COALESCE(
        NULLIF(btrim(v_data->>'portal_url'), ''),
        CASE
          WHEN NULLIF(btrim(v_data->>'access_token'), '') IS NOT NULL
          THEN 'https://adm.domio.com.pl/deweloper/' || btrim(v_data->>'access_token')
          ELSE NULL
        END
      );
      v_subject := 'DOMIO — aktywacja dostępu dewelopera';
      v_html := format(
        '<div style="font-family:Arial,sans-serif;line-height:1.5;color:#1f2937">'
        || '<p>Dzień dobry,</p>'
        || '<p>Otrzymujesz dostęp do portalu usterek deweloperskich wspólnoty <strong>%s</strong> w systemie DOMIO.</p>'
        || '<p>Po wejściu w link ustawisz własny PIN (4–6 cyfr). Administrator nie widzi tego PIN-u.</p>'
        || '<p><a href="%s">Aktywuj dostęp</a></p>'
        || '<p style="font-size:12px;color:#6b7280">Jeśli link się nie otwiera, skopiuj adres:<br>%s</p>',
        v_community,
        private.html_escape(v_url),
        private.html_escape(v_url)
      );
      IF v_portal IS NOT NULL THEN
        v_html := v_html || format(
          '<p>Po aktywacji logujesz się do listy usterek tym adresem. Zachowaj go — link aktywacyjny działa tylko raz.</p>'
          || '<p><a href="%s">Otwórz portal usterek</a></p>'
          || '<p style="font-size:12px;color:#6b7280">Adres portalu:<br>%s</p>',
          private.html_escape(v_portal),
          private.html_escape(v_portal)
        );
      END IF;
      v_html := v_html || '</div>';
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

REVOKE ALL ON FUNCTION public.claim_integration_event_jobs(integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.claim_integration_event_jobs(integer) TO service_role;

CREATE OR REPLACE FUNCTION public.activate_developer_access(
  p_activation_token uuid,
  p_pin text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public, extensions
AS $$
DECLARE
  v_access_id uuid;
  v_access_token uuid;
  v_pin_hash text;
BEGIN
  IF p_activation_token IS NULL OR p_pin IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_parameters');
  END IF;

  IF p_pin !~ '^\d{4,6}$' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'pin_must_be_4_to_6_digits');
  END IF;

  SELECT id, access_token INTO v_access_id, v_access_token
  FROM public.developer_accesses
  WHERE activation_token = p_activation_token
    AND activated_at IS NULL
    AND (activation_token_expires_at IS NULL OR activation_token_expires_at > now())
    AND deactivated_at IS NULL;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'token_invalid_or_expired');
  END IF;

  v_pin_hash := crypt(p_pin, gen_salt('bf', 10));

  UPDATE public.developer_accesses
  SET
    activated_at = now(),
    pin_hash = v_pin_hash,
    activation_token_expires_at = now()
  WHERE id = v_access_id;

  RETURN jsonb_build_object(
    'ok', true,
    'message', 'activation_successful',
    'portal_url', format('https://adm.domio.com.pl/deweloper/%s', v_access_token)
  );
END;
$$;

NOTIFY pgrst, 'reload schema';

COMMIT;
