# DOMIO Monetization Schema Documentation

## 📋 Przegląd

System monetyzacji DOMIO obsługuje:
- **Płatny dostęp do modułu "home"** - cennik dynamiczny oparty na liczbie lokali
- **Globalny moduł premium "developer_warranty"** - stała cena miesięczna/roczna dla całej organizacji
- **Model zakupowy**: Administracja (org) płaci, Wspólnota (community) otrzymuje dostęp i jest podmiotem na fakturze
- **Automatyczna blokada**: System blokuje dostęp gdy liczba lokali przekroczy opłacony próg

## 🗂️ Struktura Tabel

### 1. `pricing_plans` - Plany Cenowe (Konfiguracja Właściciela Serwisu)

Tabela definiuje dostępne plany cenowe dla modułów.

**Kluczowe pola:**
- `module` - identyfikator modułu (`home`, `developer_warranty`, etc.)
- `is_global` - czy plan obowiązuje globalnie dla całej org (true) czy per-wspólnota (false)
- `is_unit_based` - czy cena zależy od liczby lokali (true dla `home`)
- `price_per_unit` - cena za jeden lokal (dla `home`)
- `min_price` - minimalna kwota (próg cenowy, np. minimum 99 PLN)
- `price_monthly` / `price_yearly` - stałe ceny (dla `developer_warranty`)

**Przykład: Plan dla modułu "home"**
```sql
INSERT INTO pricing_plans (
  module, 
  display_name, 
  is_global, 
  is_unit_based,
  price_per_unit,
  min_price,
  features
) VALUES (
  'home',
  'DOMIO Home - Dostęp dla Wspólnoty',
  false,
  true,
  2.00,  -- 2 PLN za lokal
  99.00, -- minimum 99 PLN
  '["Dostęp dla mieszkańców", "Tablica ogłoszeń", "Zgłoszenia usterek"]'::jsonb
);
```

**Przykład: Plan dla "developer_warranty"**
```sql
INSERT INTO pricing_plans (
  module,
  display_name,
  is_global,
  is_unit_based,
  price_monthly,
  price_yearly,
  features
) VALUES (
  'developer_warranty',
  'Usterki Deweloperskie',
  true,
  false,
  199.00, -- 199 PLN/miesiąc
  1990.00, -- 1990 PLN/rok (oszczędność 398 PLN)
  '["Globalny dostęp", "Wszystkie wspólnoty", "Zgłoszenia deweloperskie"]'::jsonb
);
```

### 2. `module_subscriptions` - Aktywne Subskrypcje

Tabela przechowuje zakupione licencje.

**Kluczowe pola:**
- `purchaser_org_id` - kto płaci (zawsze Administracja)
- `beneficiary_community_id` - kto otrzymuje dostęp (Wspólnota), NULL dla globalnych
- `invoice_entity_community_id` - kto jest podmiotem na fakturze (zazwyczaj Wspólnota)
- `paid_unit_count` - ile lokali zostało opłacone
- `current_unit_count` - aktualna liczba lokali w wspólnocie
- `status` - status subskrypcji

**Status lifecycle:**
```
pending → active → [blocked_pending_payment | expired | cancelled | suspended]
```

**Automatyczna blokada:**
Gdy `current_unit_count > paid_unit_count`, trigger automatycznie:
1. Zmienia status na `blocked_pending_payment`
2. Ustawia `blocked_at` i `blocked_reason`
3. Usuwa grant dostępu w tabeli `module_access_grants`
4. Loguje zdarzenie w `subscription_events`

### 3. `module_access_grants` - Kontrola Dostępu

Tabela szybkich sprawdzeń dostępu. Tworzona automatycznie przy aktywacji subskrypcji.

**Kluczowe pola:**
- `org_id` + `community_id` + `module` - klucz dostępu
- `is_granted` - czy dostęp jest aktywny
- `granted_by_subscription_id` - referencja do subskrypcji
- `is_manual_grant` - czy to manualne nadanie (np. trial, migracja)

**Sprawdzanie dostępu:**
```sql
SELECT public.has_module_access(
  'org-uuid',
  'community-uuid',
  'home'::public.app_module
);
-- Returns: true/false
```

### 4. `subscription_events` - Audit Log

Wszystkie zdarzenia związane z subskrypcjami.

**Typy zdarzeń:**
- `created` - utworzenie subskrypcji
- `activated` - aktywacja
- `blocked` - zablokowanie (np. przekroczenie limitu lokali)
- `unblocked` - odblokowanie
- `unit_threshold_exceeded` - automatyczne zablokowanie przy dodaniu lokalu
- `renewed` - odnowienie
- `cancelled` - anulowanie
- `expired` - wygaśnięcie

### 5. `subscription_payment_intents` - Zamówienia i Płatności

Tabela pre-purchase: kalkulacja ceny, dane do faktury, tracking płatności.

**Workflow:**
1. Administracja wybiera wspólnotę i plan
2. System tworzy `payment_intent` z obliczoną kwotą
3. Administracja potwierdza i płaci
4. Po potwierdzeniu płatności tworzona jest `module_subscription`
5. `fulfilled_at` i `subscription_id` są aktualizowane

## 🔧 Funkcje Pomocnicze

### `count_residential_units_for_community(p_community_id uuid)`
Liczy lokale mieszkalne (z wyłączeniem pomieszczeń technicznych).

```sql
SELECT count_residential_units_for_community('community-uuid');
-- Returns: integer (np. 45)
```

### `calculate_unit_based_price(p_plan_id uuid, p_unit_count integer)`
Oblicza cenę dla planu opartego na lokalach.

**Formuła:** `MAX(min_price, price_per_unit * unit_count)`

```sql
SELECT calculate_unit_based_price('plan-uuid', 20);
-- Returns: 99.00 (bo 20 * 2.00 = 40 < min_price 99)

SELECT calculate_unit_based_price('plan-uuid', 100);
-- Returns: 200.00 (bo 100 * 2.00 = 200 > min_price 99)
```

### `has_module_access(p_org_id uuid, p_community_id uuid, p_module app_module)`
Szybkie sprawdzenie czy org/community ma dostęp do modułu.

```sql
SELECT has_module_access(
  'org-uuid',
  'community-uuid',
  'home'::public.app_module
);
-- Returns: boolean
```

## 🔐 Row Level Security (RLS)

Wszystkie tabele mają włączony RLS.

**Zasady:**
- `pricing_plans`: Wszyscy authenticated mogą czytać aktywne plany. Tylko service owner może edytować.
- `module_subscriptions`: Członkowie org mogą widzieć swoje subskrypcje. Tylko admini org mogą tworzyć.
- `module_access_grants`: Członkowie org/community mogą sprawdzać swoje dostępy.
- `subscription_events`: Read-only dla właścicieli subskrypcji.
- `subscription_payment_intents`: Tylko członkowie purchaser org.

## 🚨 Triggery i Automatyka

### 1. **Auto-blocking na przekroczenie limitu lokali**
`trg_check_home_subscription_threshold` na `community_units`

**Kiedy:** Po dodaniu nowego lokalu mieszkalnego (`kind = 'residential'`)

**Co robi:**
1. Znajduje aktywne subskrypcje `home` dla tej wspólnoty
2. Liczy aktualne lokale mieszkalne
3. Jeśli `current > paid`, blokuje subskrypcję
4. Usuwa grant dostępu
5. Loguje zdarzenie `unit_threshold_exceeded`

### 2. **Sync liczby lokali przy aktywacji**
`trg_sync_subscription_unit_count` na `module_subscriptions`

**Kiedy:** INSERT lub UPDATE gdy status → `active`

**Co robi:**
Automatycznie wypełnia `current_unit_count` aktualną liczbą lokali.

### 3. **Auto-tworzenie grantu dostępu**
`trg_grant_module_access` na `module_subscriptions`

**Kiedy:** UPDATE gdy status zmienia się na `active`

**Co robi:**
1. Tworzy wpis w `module_access_grants`
2. Ustawia `activated_at`
3. Loguje zdarzenie `activated`

### 4. **Audit log zdarzeń**
`trg_log_subscription_events` na `module_subscriptions`

**Kiedy:** INSERT lub UPDATE (zmiana statusu)

**Co robi:**
Automatycznie loguje wszystkie zmiany statusu do `subscription_events`.

## 📊 Diagramy

### Relacje Tabel
```
pricing_plans (1) ─────┬───── (N) module_subscriptions
                       │
organizations (1) ─────┼───── (N) module_subscriptions (purchaser)
                       │
communities (1) ───────┴───── (N) module_subscriptions (beneficiary)
                       │
module_subscriptions ──┼───── (N) subscription_events
                       │
                       └───── (1) subscription_payment_intents
                       │
                       └───── (1) module_access_grants
```

### Workflow Zakupu (home)

```
1. Admin wybiera wspólnotę
        ↓
2. System liczy lokale mieszkalne (count_residential_units_for_community)
        ↓
3. System oblicza cenę (calculate_unit_based_price)
        ↓
4. Admin potwierdza zakup
        ↓
5. Tworzony jest payment_intent (status: pending)
        ↓
6. Admin dokonuje płatności
        ↓
7. payment_intent.status → completed
        ↓
8. Tworzony jest module_subscription (status: active)
        ↓
9. Trigger tworzy module_access_grant
        ↓
10. Wspólnota ma dostęp do modułu home
```

### Workflow Blokady

```
1. Nowy lokal dodany do wspólnoty
        ↓
2. Trigger: trg_check_home_subscription_threshold
        ↓
3. System liczy lokale (current_unit_count)
        ↓
4. Porównuje z paid_unit_count
        ↓
5. Jeśli current > paid:
   ├─ subscription.status → blocked_pending_payment
   ├─ access_grant.is_granted → false
   └─ subscription_events.event_type → unit_threshold_exceeded
        ↓
6. Wspólnota traci dostęp do home
        ↓
7. Admin otrzymuje powiadomienie (TODO: notification system)
```

## 🔄 Migracja Danych

### Migracja istniejących subskrypcji

Jeśli system miał wcześniej prostą tabelę `org_subscriptions`, należy zmigrować dane:

```sql
-- Przykład: Migracja istniejących subskrypcji home
INSERT INTO module_subscriptions (
  purchaser_org_id,
  beneficiary_community_id,
  plan_id,
  module,
  status,
  billing_interval,
  amount_paid,
  activated_at,
  expires_at,
  purchase_metadata
)
SELECT 
  os.org_id,
  NULL, -- TODO: dopasować wspólnotę jeśli to home
  (SELECT id FROM pricing_plans WHERE module = 'home' AND is_active = true LIMIT 1),
  'home'::public.app_module,
  CASE 
    WHEN os.status = 'active' AND (os.expires_at IS NULL OR os.expires_at > now()) 
    THEN 'active'::public.subscription_status
    ELSE 'expired'::public.subscription_status
  END,
  'yearly'::public.billing_interval,
  0, -- brak danych o kwocie
  os.created_at,
  os.expires_at,
  jsonb_build_object('migrated_from', 'org_subscriptions')
FROM org_subscriptions os
WHERE os.app_id IN (SELECT id FROM apps WHERE name = 'home')
ON CONFLICT DO NOTHING;
```

## 🧪 Testy

### Test 1: Tworzenie planu unit-based
```sql
INSERT INTO pricing_plans (
  module, display_name, is_global, is_unit_based,
  price_per_unit, min_price, features
) VALUES (
  'home', 'Test Plan', false, true, 2.00, 99.00, '[]'::jsonb
) RETURNING *;
```

### Test 2: Kalkulacja ceny
```sql
-- 20 lokali: 20 * 2 = 40 < 99 → wynik: 99
SELECT calculate_unit_based_price('<plan-id>', 20);

-- 100 lokali: 100 * 2 = 200 > 99 → wynik: 200
SELECT calculate_unit_based_price('<plan-id>', 100);
```

### Test 3: Auto-blokowanie przy dodaniu lokalu
```sql
-- Założenia: 
-- - Wspólnota ma subskrypcję z paid_unit_count = 50
-- - Aktualnie ma 50 lokali

-- Dodajemy 51. lokal
INSERT INTO community_units (
  org_id, community_id, location_id, unit_number, kind
) VALUES (
  '<org-id>', '<community-id>', '<location-id>', '51', 'residential'
);

-- Sprawdzamy status subskrypcji
SELECT status, blocked_reason, current_unit_count, paid_unit_count
FROM module_subscriptions
WHERE beneficiary_community_id = '<community-id>' AND module = 'home';
-- Oczekiwany wynik: status = 'blocked_pending_payment'
```

## 📝 TODO

- [ ] Integracja z systemem powiadomień (notyfikacja dla admina przy blokadzie)
- [ ] API endpoints (Krok 4)
- [ ] UI dla Service Owner (zarządzanie planami)
- [ ] UI dla Admin (zakup subskrypcji)
- [ ] System płatności (integracja z payment gateway)
- [ ] Automatyczne odnowienia subskrypcji
- [ ] System rabatów i promocji
- [ ] Faktury i dokumenty księgowe
