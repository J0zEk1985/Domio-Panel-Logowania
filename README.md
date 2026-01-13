# Domio - Panel Logowania

Kompletny system autentykacji (Auth Hub) zbudowany w React + Vite + TypeScript + Tailwind CSS + Supabase.

## Funkcjonalności

- ✅ Strona logowania (/login) - biały boks z logowaniem email/hasło oraz Google/Facebook
- ✅ Strona rejestracji (/signup) - ciemny grafitowy boks z walidacją hasła i akceptacją regulaminu
- ✅ Strona logowania personelu (/staff-login) - logowanie przez internal_id i PIN
- ✅ Dashboard z kartami dostępnych aplikacji
- ✅ Przekierowania z parametrem return_to
- ✅ Pobieranie IP przy rejestracji i zapis do tabeli profiles
- ✅ Audyt rejestracji (ip_address, accepted_terms_at, terms_version)

## Konfiguracja

1. Skopiuj plik `.env.example` do `.env`:
```bash
cp .env.example .env
```

2. Wypełnij zmienne środowiskowe w pliku `.env`:
```
VITE_SUPABASE_URL=twoj_url_projektu_supabase
VITE_SUPABASE_ANON_KEY=twoj_anon_key_supabase
```

3. Zainstaluj zależności:
```bash
npm install
```

4. Uruchom serwer deweloperski:
```bash
npm run dev
```

## Wymagania bazy danych

Aplikacja wymaga następujących struktur w bazie danych Supabase:

1. **Widok `user_app_access`** - musi być utworzony w bazie danych, aby Dashboard mógł wyświetlać dostępne aplikacje użytkownika.

   Przykładowa definicja widoku (SQL):
   ```sql
   CREATE OR REPLACE VIEW public.user_app_access AS
   SELECT DISTINCT
     m.user_id,
     os.app_id,
     a.name AS app_name,
     a.domain_url AS app_domain_url,
     a.api_url AS app_api_url,
     m.org_id,
     o.name AS org_name,
     os.status AS subscription_status
   FROM public.memberships m
   JOIN public.org_subscriptions os ON os.org_id = m.org_id
   JOIN public.applications a ON a.id = os.app_id
   JOIN public.organizations o ON o.id = m.org_id
   WHERE os.status = 'active' AND a.is_active = true;
   ```

2. **Tabela `profiles`** - musi mieć odpowiednie uprawnienia RLS, aby umożliwić zapis profilu użytkownika.

## Routing

- `/` - przekierowuje do `/login`
- `/login` - strona logowania
- `/signup` - strona rejestracji
- `/staff-login` - logowanie personelu
- `/dashboard` - dashboard z aplikacjami (wymaga zalogowania)
- `/dashboard?return_to=<url>` - dashboard z automatycznym przekierowaniem

## Uwagi

- Logowanie przez Google/Facebook wymaga skonfigurowania providerów w Supabase Dashboard
- Strona staff-login używa uproszczonego systemu autentykacji (sessionStorage). W produkcji może wymagać dodatkowej konfiguracji.
