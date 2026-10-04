# Changelog - 2026-10-04

## ✅ Zmiany zaimplementowane

### 1. 📅 Data wygaśnięcia subskrypcji na dashboardzie

**Problem:** W panelu głównym (`DashboardPage.tsx`) nie była wyświetlana data wygaśnięcia aktywnej subskrypcji.

**Rozwiązanie:** Dodano datę wygaśnięcia (`expires_at`) obok informacji o planie na karcie każdego aktywnego modułu.

**Przykład wyświetlania:**
- `Plan Basic · 99 zł / mies. · Wygasa: 4 lis 2026`

**Zmodyfikowane pliki:**
- `src/pages/DashboardPage.tsx` - funkcja `planSummaryFor()`

---

### 2. 🎟️ Ograniczenie czasu trwania kodów promocyjnych

**Problem:** Kody promocyjne mogły być użyte dla dowolnego okresu rozliczenia (miesięczny/roczny), co pozwalało klientom na wykorzystanie kodu do rocznej subskrypcji, mimo że kod był przeznaczony tylko na miesięczną próbę.

**Rozwiązanie:** Dodano możliwość ograniczenia kodów promocyjnych do konkretnego okresu rozliczenia.

#### Zmiany w bazie danych:

**Nowa kolumna:** `allowed_billing_intervals` (text[])
- `NULL` lub pusta tablica = brak ograniczenia (kod działa dla obu)
- `['monthly']` = kod może być użyty tylko dla subskrypcji miesięcznych
- `['yearly']` = kod może być użyty tylko dla subskrypcji rocznych
- `['monthly', 'yearly']` = kod działa dla obu (jak NULL)

**Nowa migracja SQL:**
```
supabase/migrations/20261004210000_promo_code_billing_interval_restriction.sql
```

**Funkcje RPC zaktualizowane:**
- `preview_promo_code(p_code, p_billing_interval)` - dodano drugi parametr
- `redeem_promo_code(p_code, p_billing_interval)` - dodano drugi parametr

**Nowy błąd:** `INTERVAL_NOT_ALLOWED`
- Wyświetlany komunikat: *"Ten kod promocyjny nie może być użyty dla wybranego okresu rozliczenia."*

#### Zmiany w kodzie TypeScript:

**Frontend (`src/lib/promoCodes.ts`):**
- Dodano pole `allowedBillingIntervals: string[] | null` do typu `PromoPreview`
- Zaktualizowano funkcje `previewPromoCode()` i `redeemPromoCode()` aby przyjmowały `billingInterval`
- Dodano obsługę nowego błędu `INTERVAL_NOT_ALLOWED`

**Checkout (`src/components/module/CheckoutDrawer.tsx`):**
- Przekazywanie `interval` do funkcji sprawdzających kod promocyjny
- Automatyczne resetowanie kodu promocyjnego przy zmianie okresu rozliczenia (monthly ↔ yearly)

**Panel administracyjny:**

1. **Typy (`src/components/admin/pricingAdminTypes.ts`):**
   - Dodano pole `allowed_billing_intervals: string[] | null` do `PromoCodeRow`
   - Rozszerzono formularz o pola `allowMonthly` i `allowYearly`

2. **Formularz (`src/components/admin/PromoCodesSection.tsx`):**
   - Dodano checkboxy do wyboru dozwolonych okresów rozliczenia
   - Dodano kolumnę "Okres rozliczenia" w tabeli kodów promocyjnych
   - Walidacja: kod musi mieć zaznaczony przynajmniej jeden okres

**Wyświetlane etykiety w tabeli admin:**
- "Wszystkie" - kod działa dla obu okresów
- "Tylko miesięczna" - kod działa tylko dla monthly
- "Tylko roczna" - kod działa tylko dla yearly

---

## 📋 Instrukcja wdrożenia

### Krok 1: Wgranie migracji SQL na VPS

```bash
# Skopiuj plik migracji na VPS
scp supabase/migrations/20261004210000_promo_code_billing_interval_restriction.sql domio-vps:/tmp/

# Wykonaj migrację na bazie danych
ssh domio-vps "docker exec -i fbabab700e43 psql -U postgres -d postgres -v ON_ERROR_STOP=1 < /tmp/20261004210000_promo_code_billing_interval_restriction.sql"
```

### Krok 2: Wgranie nowego bundle na serwer

Folder `dist/` zawiera zaktualizowany bundle produkcyjny:
- `dist/index.html` (wskazuje na nowe hashe)
- `dist/assets/index-DDPabF6U.js` (nowy JavaScript bundle)
- `dist/assets/index-C_GHM0-2.css` (nowy CSS bundle)

Wgraj zawartość `dist/` na serwer `test.udomio.com.pl` / `udomio.com.pl`.

---

## 🧪 Testowanie

### Test 1: Dashboard - data wygaśnięcia
1. Zaloguj się na konto z aktywną subskrypcją
2. Na głównym dashboardzie sprawdź kartę modułu z aktywnym planem
3. Powinna być widoczna data wygaśnięcia, np: "Wygasa: 4 lis 2026"

### Test 2: Kod promocyjny z ograniczeniem
1. W panelu admin przejdź do "Cennik i Promocje"
2. Dodaj nowy kod promocyjny z ograniczeniem np. tylko miesięczna
3. W checkout spróbuj użyć tego kodu dla rocznej subskrypcji
4. Powinien pojawić się błąd: "Ten kod promocyjny nie może być użyty dla wybranego okresu rozliczenia."
5. Zmień na miesięczną - kod powinien zadziałać

### Test 3: Kod bez ograniczeń
1. Dodaj kod z obydwoma okresami zaznaczonymi (lub żadnym)
2. Kod powinien działać zarówno dla monthly jak i yearly

---

## 📊 Podsumowanie mechanizmów

### Jak działają kody promocyjne?
- **Jednorazowe** - kod jest wykorzystywany tylko raz przy aktywacji subskrypcji
- **Zniżka** - rabat (% lub kwota) jest stosowany tylko do pierwszej transakcji
- **Nie ma automatycznego przedłużania zniżki** - po wygaśnięciu subskrypcji klient musi ją ręcznie odnowić (bez zniżki)

### Jak działa odnawianie subskrypcji?
- **Brak automatycznego odnawiania!**
- Użytkownik musi ręcznie przedłużyć subskrypcję przed wygaśnięciem
- Po aktywacji planu:
  - Miesięczny: `expires_at = now() + 30 days`
  - Roczny: `expires_at = now() + 1 year`
- Status: `active` lub `cancelled`

### Przykładowe scenariusze kodów z ograniczeniem:

**Scenariusz 1: Kod tylko na miesięczną próbę**
```sql
INSERT INTO promo_codes (code, discount_percent, allowed_billing_intervals)
VALUES ('TRIAL30', 30, ARRAY['monthly']);
```
- Użytkownik może użyć tego kodu tylko przy wyborze planu miesięcznego
- Próba użycia dla rocznej subskrypcji = błąd

**Scenariusz 2: Specjalna oferta roczna**
```sql
INSERT INTO promo_codes (code, discount_amount, allowed_billing_intervals)
VALUES ('YEAR2026', 200, ARRAY['yearly']);
```
- Kod daje 200 zł zniżki tylko dla rocznej subskrypcji
- Nie działa dla miesięcznej

**Scenariusz 3: Kod uniwersalny**
```sql
INSERT INTO promo_codes (code, discount_percent, allowed_billing_intervals)
VALUES ('WELCOME10', 10, NULL);
-- lub
VALUES ('WELCOME10', 10, ARRAY['monthly', 'yearly']);
```
- Kod działa dla obu okresów rozliczenia

---

## 🔍 Weryfikacja zmian w bundle

✅ String "Wygasa:" znaleziony w `dist/assets/index-DDPabF6U.js`
✅ Build zakończony sukcesem bez błędów TypeScript
✅ Wszystkie zmiany w src/ zostały uwzględnione w bundle produkcyjnym

---

## 📝 Uwagi

1. **Migracja SQL jest bezpieczna** - dodaje tylko nową kolumnę i aktualizuje istniejące funkcje RPC
2. **Wsteczna kompatybilność** - istniejące kody promocyjne będą działać jak dotychczas (brak ograniczenia)
3. **Walidacja po stronie backendu** - sprawdzanie okresu rozliczenia odbywa się w funkcji RPC, więc nie można ominąć ograniczenia z poziomu frontendu
