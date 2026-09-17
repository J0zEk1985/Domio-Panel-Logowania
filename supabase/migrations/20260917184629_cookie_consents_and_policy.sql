-- Cookie consent audit log (PKE Art. 399 / GDPR Art. 7) and cookies legal document type.

-- ---------------------------------------------------------------------------
-- legal_documents: allow document_type = cookies
-- ---------------------------------------------------------------------------

ALTER TABLE public.legal_documents
  DROP CONSTRAINT IF EXISTS legal_documents_document_type_check;

ALTER TABLE public.legal_documents
  ADD CONSTRAINT legal_documents_document_type_check
  CHECK (document_type = ANY (ARRAY['terms'::text, 'privacy'::text, 'marketing'::text, 'cookies'::text]));

INSERT INTO public.legal_documents (
  document_type,
  version,
  content,
  is_active,
  is_required,
  published_at
) VALUES (
  'cookies',
  '1.0.0',
  $cookies$POLITYKA PLIKÓW COOKIES — DOMIO

1. Administrator
Administratorem serwisów DOMIO (w tym udomio.com.pl, domio.com.pl oraz subdomen *.domio.com.pl) jest podmiot wskazany w Polityce prywatności.

2. Czym są pliki cookies i podobne technologie
Pliki cookies to niewielkie informacje zapisywane w przeglądarce. Prawo komunikacji elektronicznej (art. 399) obejmuje również pamięć lokalną (localStorage / sessionStorage) oraz IndexedDB, gdy serwis zapisuje lub odczytuje informacje na urządzeniu końcowym.

3. Podstawa prawna
- Ciasteczka niezbędne: art. 399 PKE (wyjątek — niezbędne do świadczenia usługi żądanej przez użytkownika) oraz art. 6 ust. 1 lit. b i f RODO.
- Ciasteczka i skrypty opcjonalne: zgoda (art. 399 PKE oraz art. 6 ust. 1 lit. a RODO). Zgody opcjonalne są domyślnie wyłączone.

4. Kategorie
4.1. Niezbędne (zawsze aktywne)
- domio-auth-token — sesja SSO Supabase (produkcja: ciasteczko na domenie nadrzędnej, 7 dni, SameSite=Lax, Secure).
- identyfikator PKCE powiązany z sesją (ten sam mechanizm przechowywania).
- domio-cookie-consent — zapis Twojej decyzji o zgodach (do 180 dni).
- znaczniki mostu sesji w sessionStorage (SSO między aplikacjami DOMIO).

4.2. Funkcjonalne (wymagają zgody)
- sidebar:state — stan menu bocznego (Administracja, Flota).
- motywy wyglądu (np. domio-theme, fleet-ui-theme).
- zapamiętanie widoku lub roli w panelu (np. dyspozytor/technik).
- Google Maps / Places oraz kafelki OpenStreetMap — tylko po wyrażeniu zgody; bez zgody mapa i podpowiedzi adresu są wyłączone.
Szkice formularzy, tryb offline sprzątania i wybór aktywnej roli w trakcie pracy są elementem świadczonej usługi i nie służą analityce ani marketingowi.

4.3. Analityczne
Obecnie nie stosujemy narzędzi analitycznych (brak Google Analytics, PostHog, Hotjar itp.). Kategoria jest zarezerwowana na przyszłość i pozostaje wyłączona, dopóki nie uzyskasz zgody.

4.4. Marketingowe
Nie stosujemy pikseli reklamowych ani cookies marketingowych. Logowanie przez Google lub Facebooka (jeśli dostępne) następuje dopiero po Twoim kliknięciu i jest realizowane u tych dostawców w celu uwierzytelnienia.

5. Podmioty trzecie (po zgodzie funkcjonalnej lub w ramach logowania)
- Google (Maps, Places, ewentualnie logowanie) — maps.googleapis.com.
- OpenStreetMap — kafelki map.
- Supabase — hosting bazy, auth i API (podmiot przetwarzający).
Czcionki serwisu są hostowane lokalnie i nie ładujemy Google Fonts.

6. Zarządzanie zgodą
W każdej chwili możesz zmienić lub wycofać zgodę przyciskiem „Zarządzaj zgodami cookies” w stopce lub ustawieniach. Wycofanie nie wpływa na zgodność wcześniejszego przetwarzania.

7. Rejestr zgód
Każda decyzja (akceptacja, odrzucenie, zmiana, wycofanie) jest zapisywana w dzienniku dowodowym: identyfikator zgody, kategorie, wersja polityki, skrót SHA-256 adresu IP z solą, przeglądarka i czas. Dziennik jest tylko do dopisywania (brak edycji i usuwania wpisów).

8. Okres przechowywania
Decyzja w przeglądarce: do 180 dni lub do zmiany. Po zmianie wersji niniejszej polityki baner pojawi się ponownie. Wpisy dziennika przechowujemy przez okres niezbędny do wykazania rozliczalności wobec UODO i sądów.

9. Kontakt
Dane kontaktowe administratora oraz prawa osób, których dane dotyczą, opisuje Polityka prywatności.$cookies$,
  true,
  false,
  clock_timestamp()
);

-- ---------------------------------------------------------------------------
-- cookie_consents: append-only evidence log
-- ---------------------------------------------------------------------------

CREATE TABLE public.cookie_consents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  consent_id uuid NOT NULL,
  user_id uuid NULL REFERENCES auth.users (id) ON DELETE SET NULL,
  accepted_categories jsonb NOT NULL,
  policy_version text NOT NULL,
  action text NOT NULL,
  app_source text NOT NULL,
  ip_address_hash text NOT NULL,
  user_agent text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT cookie_consents_action_check
    CHECK (action = ANY (ARRAY['accept_all'::text, 'reject_optional'::text, 'customize'::text, 'withdraw'::text])),
  CONSTRAINT cookie_consents_app_source_check
    CHECK (app_source = ANY (ARRAY['hub'::text, 'cleaning'::text, 'serwis'::text, 'administracja'::text, 'home'::text, 'flota'::text])),
  CONSTRAINT cookie_consents_policy_version_check
    CHECK (char_length(policy_version) BETWEEN 1 AND 32),
  CONSTRAINT cookie_consents_user_agent_check
    CHECK (char_length(user_agent) <= 512),
  CONSTRAINT cookie_consents_ip_hash_check
    CHECK (char_length(ip_address_hash) BETWEEN 16 AND 128),
  CONSTRAINT cookie_consents_categories_object_check
    CHECK (jsonb_typeof(accepted_categories) = 'object'),
  CONSTRAINT cookie_consents_categories_essential_check
    CHECK ((accepted_categories ->> 'essential') = 'true')
);

CREATE INDEX cookie_consents_consent_id_created_at_idx
  ON public.cookie_consents (consent_id, created_at DESC);

CREATE INDEX cookie_consents_user_id_created_at_idx
  ON public.cookie_consents (user_id, created_at DESC)
  WHERE user_id IS NOT NULL;

COMMENT ON TABLE public.cookie_consents IS
  'Append-only cookie consent evidence log (GDPR Art. 7). No updates or deletes.';

CREATE OR REPLACE FUNCTION private.tg_cookie_consents_append_only()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'pg_catalog'
AS $$
BEGIN
  RAISE EXCEPTION 'cookie_consents is append-only'
    USING ERRCODE = 'restrict_violation';
END;
$$;

REVOKE ALL ON FUNCTION private.tg_cookie_consents_append_only() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.tg_cookie_consents_append_only() TO postgres, service_role;

CREATE TRIGGER cookie_consents_no_update
  BEFORE UPDATE ON public.cookie_consents
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_cookie_consents_append_only();

CREATE TRIGGER cookie_consents_no_delete
  BEFORE DELETE ON public.cookie_consents
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_cookie_consents_append_only();

ALTER TABLE public.cookie_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cookie_consents FORCE ROW LEVEL SECURITY;

CREATE POLICY cookie_consents_select_own
  ON public.cookie_consents
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY cookie_consents_select_platform_admin
  ON public.cookie_consents
  FOR SELECT
  TO authenticated
  USING (public.is_platform_admin());

REVOKE ALL ON TABLE public.cookie_consents FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE public.cookie_consents TO authenticated;
GRANT INSERT, SELECT ON TABLE public.cookie_consents TO service_role;
