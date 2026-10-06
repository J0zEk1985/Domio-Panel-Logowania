# 🚀 Wdrożenie Kroku 1: Schemat Monetyzacji

## 📋 Przed Wdrożeniem

### Wymagania
- ✅ PostgreSQL 12+ (Supabase)
- ✅ Uprawnienia `SUPERUSER` lub `CREATE TYPE`, `CREATE TABLE`, `CREATE TRIGGER`
- ✅ Backup bazy danych (na wszelki wypadek)
- ✅ Dostęp SSH do VPS (`domio-vps`)

### Checklist Przed Migracją
- [ ] Backup bazy danych wykonany
- [ ] Migracje zrecenzowane i zatwierdzone
- [ ] Środowisko testowe przetestowane
- [ ] Dokumentacja przeczytana
- [ ] Downtime window zaplanowany (opcjonalnie)

## 🔧 Krok Po Kroku: Wdrożenie na VPS

### 1. Backup Bazy Danych

```powershell
# Wykonaj backup przed migracją
ssh domio-vps "docker exec fbabab700e43 pg_dump -U postgres -d postgres -F c -f /tmp/backup_before_monetization_$(date +%Y%m%d_%H%M%S).dump"

# Pobierz backup lokalnie (opcjonalnie)
scp domio-vps:/tmp/backup_before_monetization_*.dump ./backups/
```

### 2. Weryfikacja Połączenia i Obecnej Struktury

```powershell
# Sprawdź połączenie
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -c 'SELECT version();'"

# Sprawdź obecne tabele związane z subskrypcjami
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -c '\dt public.org_subscriptions'"
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -c '\dt public.community_units'"
```

### 3. Upload Plików Migracji na VPS

```powershell
# Ustaw zmienną z ścieżką do projektu
$PROJECT_PATH = "d:\projekty\Domio-Panel-Logowania"

# Upload migracji
scp "$PROJECT_PATH\supabase\migrations\20261006222000_monetization_plans_and_subscriptions.sql" domio-vps:/tmp/
scp "$PROJECT_PATH\supabase\migrations\20261006223000_monetization_business_logic.sql" domio-vps:/tmp/

# Upload seed data (opcjonalnie dla dev/staging)
scp "$PROJECT_PATH\supabase\seed\monetization_seed_data.sql" domio-vps:/tmp/

# Upload testów
scp "$PROJECT_PATH\supabase\tests\monetization_tests.sql" domio-vps:/tmp/
```

### 4. Uruchomienie Migracji

```powershell
# UWAGA: Migracje są w transakcjach (BEGIN/COMMIT), więc rollback jest automatyczny w razie błędu

# Migracja 1: Schema i RLS
ssh domio-vps "docker exec -i fbabab700e43 psql -U postgres -d postgres -v ON_ERROR_STOP=1 < /tmp/20261006222000_monetization_plans_and_subscriptions.sql"

# Sprawdź czy tabele zostały utworzone
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -c '\dt public.pricing_plans'"
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -c '\dt public.module_subscriptions'"

# Migracja 2: Business Logic i Triggery
ssh domio-vps "docker exec -i fbabab700e43 psql -U postgres -d postgres -v ON_ERROR_STOP=1 < /tmp/20261006223000_monetization_business_logic.sql"

# Sprawdź czy funkcje zostały utworzone
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -c '\df public.calculate_unit_based_price'"
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -c '\df public.has_module_access'"
```

### 5. Weryfikacja Migracji

```powershell
# Sprawdź strukturę tabel
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -c '\d+ public.pricing_plans'"
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -c '\d+ public.module_subscriptions'"

# Sprawdź triggery
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -c 'SELECT tgname, tgrelid::regclass FROM pg_trigger WHERE tgname LIKE ''%subscription%'' OR tgname LIKE ''%monetization%'';'"

# Sprawdź RLS policies
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -c 'SELECT schemaname, tablename, policyname FROM pg_policies WHERE tablename LIKE ''%subscription%'' OR tablename LIKE ''pricing%'';'"
```

### 6. Uruchomienie Testów (Opcjonalnie - Staging/Dev)

```powershell
# UWAGA: Testy tworzą i usuwają dane testowe
# NIE uruchamiaj na produkcji bez wcześniejszego przeglądu!

ssh domio-vps "docker exec -i fbabab700e43 psql -U postgres -d postgres -v ON_ERROR_STOP=1 < /tmp/monetization_tests.sql"

# Sprawdź output - powinny być same ✓ PASSED
```

### 7. Załadowanie Danych Seed (Dev/Staging)

```powershell
# Tylko dla środowisk dev/staging/test
# NIE uruchamiaj na produkcji bez modyfikacji danych

ssh domio-vps "docker exec -i fbabab700e43 psql -U postgres -d postgres -v ON_ERROR_STOP=1 < /tmp/monetization_seed_data.sql"

# Sprawdź dane
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -c 'SELECT module, display_name, price_per_unit, min_price FROM public.pricing_plans;'"
```

## 🧪 Post-Deployment Verification

### Test 1: Sprawdź Funkcje

```sql
-- Test calculate_unit_based_price (zakładając plan z seed data)
SELECT calculate_unit_based_price(
  'a0000000-0000-0000-0000-000000000001'::uuid, 
  20
);
-- Expected: 99.00

SELECT calculate_unit_based_price(
  'a0000000-0000-0000-0000-000000000001'::uuid, 
  100
);
-- Expected: 250.00
```

```powershell
# Wykonaj przez SSH
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -c \"SELECT calculate_unit_based_price('a0000000-0000-0000-0000-000000000001'::uuid, 20);\""
```

### Test 2: Sprawdź RLS

```sql
-- Zaloguj się jako authenticated user i sprawdź dostęp do planów
SELECT id, module, display_name FROM public.pricing_plans WHERE is_active = true;
-- Powinno zwrócić aktywne plany
```

### Test 3: Sprawdź Triggery

```sql
-- Sprawdź czy trigger updated_at działa
UPDATE public.pricing_plans 
SET description = 'Updated description' 
WHERE module = 'home';

SELECT updated_at > created_at FROM public.pricing_plans WHERE module = 'home';
-- Powinno zwrócić true
```

## 🔄 Rollback (W Razie Problemów)

### Opcja 1: Przywróć Backup

```powershell
# UWAGA: To usunie WSZYSTKIE zmiany po backupie, nie tylko migracje monetyzacji!

# Przywróć backup
ssh domio-vps "docker exec fbabab700e43 pg_restore -U postgres -d postgres -c /tmp/backup_before_monetization_*.dump"
```

### Opcja 2: Manualne Usunięcie (Bezpieczniejsze)

```sql
-- UWAGA: Kolejność jest ważna ze względu na foreign keys!

BEGIN;

-- Usuń tabele w odwrotnej kolejności
DROP TABLE IF EXISTS public.subscription_events CASCADE;
DROP TABLE IF EXISTS public.subscription_payment_intents CASCADE;
DROP TABLE IF EXISTS public.module_access_grants CASCADE;
DROP TABLE IF EXISTS public.module_subscriptions CASCADE;
DROP TABLE IF EXISTS public.pricing_plans CASCADE;

-- Usuń funkcje
DROP FUNCTION IF EXISTS public.count_residential_units_for_community(uuid);
DROP FUNCTION IF EXISTS public.calculate_unit_based_price(uuid, integer);
DROP FUNCTION IF EXISTS public.has_module_access(uuid, uuid, public.app_module);
DROP FUNCTION IF EXISTS public.check_home_subscription_unit_threshold();
DROP FUNCTION IF EXISTS public.sync_subscription_unit_count();
DROP FUNCTION IF EXISTS public.grant_module_access_on_activation();
DROP FUNCTION IF EXISTS public.log_subscription_status_change();
DROP FUNCTION IF EXISTS public.trigger_set_updated_at();

-- Usuń typy (jeśli nie są używane gdzie indziej)
DROP TYPE IF EXISTS public.app_module CASCADE;
DROP TYPE IF EXISTS public.subscription_status CASCADE;
DROP TYPE IF EXISTS public.billing_interval CASCADE;

COMMIT;
```

```powershell
# Wykonaj rollback
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c 'DROP TABLE IF EXISTS public.subscription_events CASCADE; ...' "
```

## 📊 Monitoring Po Wdrożeniu

### Sprawdź Logi Postgres

```powershell
# Sprawdź ostatnie logi kontenera
ssh domio-vps "docker logs fbabab700e43 --tail 100"

# Filtruj po ERROR
ssh domio-vps "docker logs fbabab700e43 --tail 1000 | grep ERROR"
```

### Sprawdź Rozmiar Tabel

```sql
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE tablename IN (
  'pricing_plans',
  'module_subscriptions',
  'module_access_grants',
  'subscription_events',
  'subscription_payment_intents'
)
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

```powershell
ssh domio-vps "docker exec fbabab700e43 psql -U postgres -d postgres -c \"SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size FROM pg_tables WHERE tablename IN ('pricing_plans', 'module_subscriptions') ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;\""
```

### Sprawdź Wydajność Triggerów

```sql
-- Włącz track_functions
SET track_functions = 'all';

-- Po kilku operacjach sprawdź statystyki
SELECT 
  funcname, 
  calls, 
  total_time, 
  self_time
FROM pg_stat_user_functions
WHERE funcname LIKE '%subscription%' OR funcname LIKE '%unit%'
ORDER BY total_time DESC;
```

## 🐛 Troubleshooting

### Problem: "Permission denied for table"

**Rozwiązanie:**
```sql
-- Sprawdź granty
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name = 'pricing_plans';

-- Nadaj uprawnienia jeśli brakuje
GRANT SELECT, INSERT, UPDATE ON public.pricing_plans TO authenticated;
```

### Problem: "Function does not exist"

**Rozwiązanie:**
```sql
-- Sprawdź czy funkcja istnieje
\df public.calculate_unit_based_price

-- Sprawdź namespace
SELECT n.nspname, p.proname 
FROM pg_proc p 
JOIN pg_namespace n ON p.pronamespace = n.oid 
WHERE p.proname LIKE '%calculate%';
```

### Problem: "Trigger did not fire"

**Rozwiązanie:**
```sql
-- Sprawdź triggery
SELECT 
  tgname AS trigger_name,
  tgrelid::regclass AS table_name,
  tgenabled AS enabled
FROM pg_trigger
WHERE tgname LIKE '%subscription%';

-- Włącz trigger jeśli wyłączony
ALTER TABLE public.module_subscriptions ENABLE TRIGGER ALL;
```

### Problem: "RLS blocking queries"

**Rozwiązanie:**
```sql
-- Tymczasowo wyłącz RLS dla debugowania (tylko dev!)
ALTER TABLE public.pricing_plans DISABLE ROW LEVEL SECURITY;

-- Sprawdź policies
SELECT * FROM pg_policies WHERE tablename = 'pricing_plans';

-- Włącz z powrotem
ALTER TABLE public.pricing_plans ENABLE ROW LEVEL SECURITY;
```

## ✅ Checklist Po Wdrożeniu

- [ ] Wszystkie migracje wykonane bez błędów
- [ ] Tabele utworzone i widoczne w `\dt`
- [ ] Funkcje utworzone i widoczne w `\df`
- [ ] Triggery aktywne i widoczne w `pg_trigger`
- [ ] RLS policies skonfigurowane
- [ ] Testy przeszły pomyślnie (jeśli uruchomione)
- [ ] Dane seed załadowane (dev/staging)
- [ ] Monitoring skonfigurowany
- [ ] Dokumentacja zaktualizowana
- [ ] Team poinformowany o zmianach

## 📞 Wsparcie

W razie problemów:
1. Sprawdź logi Postgres: `docker logs fbabab700e43`
2. Przeczytaj dokumentację: `docs/MONETIZATION_SCHEMA.md`
3. Zobacz testy: `supabase/tests/monetization_tests.sql`
4. Skontaktuj się z zespołem deweloperskim

---

**Last Updated:** 2026-10-06  
**Version:** 1.0  
**Author:** AI Assistant
