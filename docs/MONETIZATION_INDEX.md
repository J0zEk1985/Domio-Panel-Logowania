# 💰 DOMIO Monetization System - Documentation Index

## 📚 Dokumentacja Systemu Monetyzacji

System monetyzacji DOMIO obsługuje płatny dostęp do modułów **home** (dynamiczny cennik oparty na liczbie lokali) oraz **developer_warranty** (globalny moduł premium).

---

## 🗂️ Struktura Dokumentacji

### 📖 Główne Dokumenty

| Dokument | Opis | Wielkość |
|----------|------|----------|
| **[MONETIZATION_SCHEMA.md](./MONETIZATION_SCHEMA.md)** | Kompletna dokumentacja schematu bazy danych, tabel, funkcji, triggerów i RLS policies | ~450 linii |
| **[MONETIZATION_ERD.md](./MONETIZATION_ERD.md)** | Diagramy ERD, flow charts i wizualizacje architektury (Mermaid) | ~400 linii |
| **[STEP_1_SUMMARY.md](./STEP_1_SUMMARY.md)** | Podsumowanie Kroku 1: zrealizowane wymagania, statystyki, checklist | ~300 linii |
| **[DEPLOYMENT_STEP_1.md](./DEPLOYMENT_STEP_1.md)** | Instrukcje wdrożenia na VPS, testy, troubleshooting, rollback | ~450 linii |

### 💾 Pliki Migracji

| Plik | Opis | Wielkość |
|------|------|----------|
| **[20261006222000_monetization_plans_and_subscriptions.sql](../supabase/migrations/20261006222000_monetization_plans_and_subscriptions.sql)** | Schema: tabele, RLS, typy ENUM | ~750 linii |
| **[20261006223000_monetization_business_logic.sql](../supabase/migrations/20261006223000_monetization_business_logic.sql)** | Business logic: funkcje, triggery, automatyka | ~360 linii |

### 🧪 Testy i Seed Data

| Plik | Opis | Wielkość |
|------|------|----------|
| **[monetization_tests.sql](../supabase/tests/monetization_tests.sql)** | Automatyczne testy integracyjne (6 test cases) | ~600 linii |
| **[monetization_seed_data.sql](../supabase/seed/monetization_seed_data.sql)** | Przykładowe plany cenowe dla dev/staging | ~180 linii |

### 🔤 TypeScript Types

| Plik | Opis | Wielkość |
|------|------|----------|
| **[monetization.ts](../src/types/monetization.ts)** | TypeScript interfejsy, typy, helpery UI | ~600 linii |

---

## 🚀 Quick Start

### 1. Przeczytaj Dokumentację
```
docs/MONETIZATION_SCHEMA.md  ← Zacznij tutaj!
```

### 2. Zobacz Diagramy
```
docs/MONETIZATION_ERD.md     ← Wizualizacje
```

### 3. Wdróż Migracje
```
docs/DEPLOYMENT_STEP_1.md    ← Instrukcje wdrożenia
```

### 4. Uruchom Testy
```
supabase/tests/monetization_tests.sql  ← Weryfikacja
```

---

## 📊 Kluczowe Komponenty

### Tabele

| Tabela | Rola | Rekordy (estimate) |
|--------|------|-------------------|
| `pricing_plans` | Konfiguracja planów cenowych (Service Owner) | ~10-20 |
| `module_subscriptions` | Zakupione licencje | ~100-1000 |
| `module_access_grants` | Fast lookup dla sprawdzania dostępu | ~100-1000 |
| `subscription_events` | Audit log wszystkich zdarzeń | ~1000+ |
| `subscription_payment_intents` | Pre-purchase tracking | ~500-2000 |

### Funkcje Kluczowe

| Funkcja | Cel | Performance |
|---------|-----|------------|
| `count_residential_units_for_community()` | Liczenie lokali mieszkalnych (bez technicznych) | O(n) - 1-2ms |
| `calculate_unit_based_price()` | Kalkulacja ceny: MAX(min, price*units) | O(1) - <1ms |
| `has_module_access()` | Szybkie sprawdzenie dostępu | O(1) - <1ms |

### Triggery

| Trigger | Event | Funkcja |
|---------|-------|---------|
| `check_home_subscription_threshold` | `AFTER INSERT` na `community_units` | Auto-blokuje subskrypcję gdy units > paid_threshold |
| `sync_subscription_unit_count` | `BEFORE INSERT/UPDATE` na `module_subscriptions` | Sync `current_unit_count` przy aktywacji |
| `grant_module_access_on_activation` | `BEFORE UPDATE` na `module_subscriptions` | Auto-tworzy grant w `module_access_grants` |
| `log_subscription_status_change` | `AFTER INSERT/UPDATE` na `module_subscriptions` | Loguje wszystkie zmiany statusu |

---

## 🎯 Zrealizowane Wymagania

| # | Wymaganie | Status |
|---|-----------|--------|
| 1 | Płatny dostęp do modułu "home" | ✅ |
| 2 | Zakup tylko przez Administrację | ✅ |
| 3 | Dynamiczny cennik oparty na lokalach | ✅ |
| 4 | Próg minimalny ceny | ✅ |
| 5 | Wykluczenie pomieszczeń technicznych | ✅ |
| 6 | Auto-blokada przy przekroczeniu limitu | ✅ |
| 7 | Model zakupowy (org płaci, community na fakturze) | ✅ |
| 8 | Globalny moduł "developer_warranty" | ✅ |
| 9 | Rozliczenie miesięczne/roczne | ✅ |
| 10 | Audit log wszystkich zdarzeń | ✅ |

---

## 🔒 Bezpieczeństwo

### Row Level Security (RLS)

✅ Wszystkie tabele mają włączony RLS  
✅ Polityki oparte na `is_org_member()` i rolach  
✅ Izolacja danych między tenantami  
✅ SECURITY DEFINER funkcje z `SET search_path`  

### Walidacja Danych

✅ CHECK constraints na kwotach i logice biznesowej  
✅ Foreign keys z proper cascade policies  
✅ UNIQUE constraints zapobiegające duplikatom  
✅ NOT NULL na polach krytycznych  

---

## 📈 Statystyki Implementacji

| Metryka | Wartość |
|---------|---------|
| **Tabele** | 5 |
| **Kolumny** | 71 |
| **Indexy** | 14 |
| **Triggery** | 7 |
| **Funkcje** | 8 |
| **RLS Policies** | 8 |
| **Typy ENUM** | 3 |
| **Linie kodu SQL** | ~1,800 |
| **Linie TypeScript** | ~600 |
| **Linie dokumentacji** | ~1,600 |
| **Test cases** | 6 |

---

## 🛠️ Narzędzia i Technologie

- **Database:** PostgreSQL 12+ (Supabase)
- **Language:** PL/pgSQL, TypeScript
- **ORM:** Supabase Client
- **Diagrams:** Mermaid
- **Testing:** SQL integration tests
- **Deployment:** SSH + Docker (VPS)

---

## 🔄 Workflow

### Purchase Flow
```
Admin wybiera wspólnotę 
  → System liczy lokale
  → Oblicza cenę (MAX(min_price, price*units))
  → Admin potwierdza
  → Tworzy payment_intent
  → Płatność
  → Tworzy subscription (status: active)
  → Trigger tworzy access_grant
  → Wspólnota ma dostęp
```

### Auto-blocking Flow
```
Dodano nowy lokal
  → Trigger: check_home_subscription_threshold
  → Liczy lokale (current_unit_count)
  → Porównuje z paid_unit_count
  → Jeśli current > paid:
    → Blokuje subscription
    → Usuwa access_grant
    → Loguje event
    → (TODO: Wysyła powiadomienie)
```

---

## 🚧 TODO / Roadmap

### Krok 2: Business Logic Layer (Serwisy)
- [ ] `PricingService` - zarządzanie planami
- [ ] `SubscriptionService` - zarządzanie subskrypcjami
- [ ] `PurchaseService` - workflow zakupu
- [ ] `AccessControlService` - sprawdzanie dostępu
- [ ] `NotificationService` - powiadomienia

### Krok 3: API Endpoints
- [ ] REST API dla wszystkich operacji
- [ ] Walidacja i autoryzacja
- [ ] Rate limiting
- [ ] API documentation (OpenAPI/Swagger)

### Krok 4: User Interface
- [ ] Panel Service Owner (zarządzanie planami)
- [ ] Panel Admin (sklep subskrypcji)
- [ ] Widok aktywnych subskrypcji
- [ ] Workflow upgrade/dopłaty
- [ ] Powiadomienia w UI

### Krok 5: Integracje
- [ ] Payment gateway (Stripe/PayU)
- [ ] System fakturowania
- [ ] Email notifications
- [ ] Slack/Discord webhooks (opcjonalnie)

---

## 📞 Support & Resources

### Dokumentacja
- Schema: [MONETIZATION_SCHEMA.md](./MONETIZATION_SCHEMA.md)
- Diagramy: [MONETIZATION_ERD.md](./MONETIZATION_ERD.md)
- Deployment: [DEPLOYMENT_STEP_1.md](./DEPLOYMENT_STEP_1.md)

### Kod
- Migracje: `supabase/migrations/2026100622*.sql`
- Testy: `supabase/tests/monetization_tests.sql`
- Types: `src/types/monetization.ts`

### Kontakt
- Team Lead: Principal Software Engineer
- Status: ✅ Krok 1 Zakończony
- Next: Czeka na akcept przed Krokiem 2

---

## 📝 Change Log

| Data | Wersja | Zmiany |
|------|--------|--------|
| 2026-10-06 | 1.0 | Krok 1: Schema i Business Logic - Initial Release |

---

**Last Updated:** 2026-10-06  
**Status:** ✅ Ready for Review  
**Next Step:** Awaiting approval for Step 2
