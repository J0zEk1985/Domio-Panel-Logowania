# ✅ KROK 3: API Endpoints (Supabase Edge Functions) - ZAKOŃCZONY

## 📦 Utworzone Pliki

### Edge Functions (8 funkcji)

| Funkcja | Linie | Endpointy | Status |
|---------|-------|-----------|--------|
| ✅ `pricing-plans` | ~350 | GET, POST, PUT, DELETE | Utworzona |
| ✅ `calculate-price` | ~180 | POST | Utworzona |
| ✅ `purchase-subscription` | ~250 | POST | Utworzona |
| ✅ `check-access` | ~100 | POST | Utworzona |
| ✅ `upgrade-subscription` | ~220 | POST | Utworzona |
| ✅ `subscriptions` | ~400 | GET, POST (cancel/renew) | Utworzona |
| ✅ `grant-trial` | ~120 | POST | Utworzona |

### Shared Utilities (4 pliki)

| Plik | Funkcja | Status |
|------|---------|--------|
| ✅ `_shared/monetization/types.ts` | TypeScript types | Utworzony |
| ✅ `_shared/monetization/responses.ts` | HTTP response helpers | Utworzony |
| ✅ `_shared/monetization/auth.ts` | Auth & authorization | Utworzony |
| ✅ `_shared/monetization/validation.ts` | Zod schemas | Utworzony |

### Dokumentacja (1 plik)

| Plik | Zawartość | Status |
|------|-----------|--------|
| ✅ `functions/README_MONETIZATION.md` | API documentation + examples | Utworzony |

**RAZEM:** 12 plików, ~2,100 linii kodu

---

## 🎯 Zrealizowane Endpointy

### Pricing Plans

- ✅ `GET /pricing-plans` - Lista planów (z filtrowaniem)
- ✅ `GET /pricing-plans/:id` - Szczegóły planu
- ✅ `POST /pricing-plans` - Tworzenie (Owner only)
- ✅ `PUT /pricing-plans/:id` - Aktualizacja (Owner only)
- ✅ `DELETE /pricing-plans/:id` - Dezaktywacja (Owner only)

### Price Calculation

- ✅ `POST /calculate-price` - Kalkulacja przed zakupem
  - Wspiera unit-based i flat-rate
  - Automatyczne liczenie lokali
  - Breakdown ceny

### Subscriptions

- ✅ `GET /subscriptions` - Lista subskrypcji (z filtrowaniem)
- ✅ `GET /subscriptions/:id` - Szczegóły + events
- ✅ `POST /subscriptions/:id/cancel` - Anulowanie (Admin)
- ✅ `POST /subscriptions/:id/renew` - Odnowienie (Admin)

### Purchase & Upgrade

- ✅ `POST /purchase-subscription` - Zakup (Admin)
  - Payment intent creation
  - Subscription creation
  - Access grant auto-creation
- ✅ `POST /upgrade-subscription` - Upgrade przy przekroczeniu limitu (Admin)

### Access Control

- ✅ `POST /check-access` - Sprawdzenie dostępu
  - Fast check przez database function
  - Zwraca grant details

### Trial Management

- ✅ `POST /grant-trial` - Nadanie triala (Owner only)

---

## 🔧 Funkcjonalności

### ✅ Authentication & Authorization

- JWT token validation (Supabase Auth)
- Role-based access control:
  - `requireAuth()` - authenticated users
  - `requireOrgMember()` - org members
  - `requireOrgAdmin()` - org admins
  - `requireServiceOwner()` - service owners
- Per-endpoint authorization checks

### ✅ Validation (Zod)

Wszystkie endpointy używają Zod schemas:
- `CreatePricingPlanSchema` - z custom refinements
- `CalculatePriceSchema`
- `PurchaseSubscriptionSchema`
- `CheckAccessSchema`
- `UpgradeSubscriptionSchema`
- `CancelSubscriptionSchema`
- `RenewSubscriptionSchema`
- `GrantTrialSchema`

**Features:**
- Type-safe validation
- Custom refinements (unit-based requirements)
- Formatted error messages

### ✅ Error Handling

Standardowe response helpers:
- `successResponse(data, status)`
- `errorResponse(code, message, status)`
- `validationError(errors)`
- `unauthorizedError()`
- `forbiddenError()`
- `notFoundError(resource)`
- `internalError(message)`
- `methodNotAllowedError(allowed[])`

**Consistent format:**
```json
{
  "success": boolean,
  "data": {} | null,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable",
    "details": {}
  }
}
```

### ✅ CORS

Pre-configured for wszystkich funkcji:
- Preflight handling (`OPTIONS`)
- Allow all origins (`*`)
- Standard headers

### ✅ Database Integration

- Używa Supabase client z JWT context
- RLS policies automatycznie aplikowane
- Wykorzystuje database functions:
  - `count_residential_units_for_community()`
  - `calculate_unit_based_price()`
  - `has_module_access()`
- Transakcje przez pojedyncze queries

---

## 📊 Statystyki

| Metryka | Wartość |
|---------|---------|
| **Edge Functions** | 7 |
| **Shared utilities** | 4 |
| **Total endpoints** | 14+ |
| **Lines of code** | ~2,100 |
| **Zod schemas** | 8 |
| **Response helpers** | 9 |
| **Auth middleware** | 4 |

---

## 🔐 Security

### ✅ Authentication
- JWT validation on every request
- Supabase Auth integration
- Token extraction from `Authorization` header

### ✅ Authorization
- Role-based checks (owner, admin, member)
- Resource ownership validation
- RLS enforcement at database level

### ✅ Input Validation
- Zod schemas for all inputs
- SQL injection prevention (parameterized queries)
- Type safety through TypeScript

### ✅ Error Messages
- No sensitive data in errors
- Consistent error codes
- Proper HTTP status codes

---

## 🧪 Testowanie

### Manual Testing

```bash
# Test locally
supabase functions serve pricing-plans

# Deploy to production
supabase functions deploy pricing-plans

# Test with curl
curl -X GET http://localhost:54321/functions/v1/pricing-plans \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Frontend Integration

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(URL, KEY);

// Get auth token
const { data: { session } } = await supabase.auth.getSession();

// Call function
const response = await supabase.functions.invoke('pricing-plans', {
  method: 'GET'
});

// Or with fetch
const res = await fetch(
  `${URL}/functions/v1/pricing-plans`,
  {
    headers: {
      'Authorization': `Bearer ${session.access_token}`
    }
  }
);
```

---

## 📚 Przykłady Użycia

### 1. Purchase Flow (Frontend)

```typescript
// 1. List available plans
const { data: plansData } = await supabase.functions.invoke('pricing-plans', {
  method: 'GET'
});

// 2. Calculate price
const { data: priceData } = await supabase.functions.invoke('calculate-price', {
  body: {
    plan_id: selectedPlan.id,
    billing_interval: 'yearly',
    community_id: communityId
  }
});

// 3. Purchase
const { data: purchaseData } = await supabase.functions.invoke('purchase-subscription', {
  body: {
    plan_id: selectedPlan.id,
    beneficiary_community_id: communityId,
    billing_interval: 'yearly',
    invoice_entity_community_id: communityId
  }
});

// 4. Check access
const { data: accessData } = await supabase.functions.invoke('check-access', {
  body: {
    org_id: orgId,
    community_id: communityId,
    module: 'home'
  }
});
```

### 2. Access Check (Middleware)

```typescript
// React Router loader / middleware
async function requireModuleAccess(orgId: string, module: string) {
  const { data } = await supabase.functions.invoke('check-access', {
    body: { org_id: orgId, module }
  });
  
  if (!data.has_access) {
    throw redirect('/subscriptions/purchase?module=' + module);
  }
  
  return data;
}
```

### 3. Upgrade Flow

```typescript
// When subscription blocked
const { data: subscription } = await supabase.functions.invoke(
  `subscriptions/${subscriptionId}`
);

if (subscription.status === 'blocked_pending_payment') {
  // Show upgrade prompt
  const { data: upgraded } = await supabase.functions.invoke('upgrade-subscription', {
    body: {
      subscription_id: subscriptionId,
      payment_method: 'card'
    }
  });
  
  console.log('Upgraded!', upgraded.upgrade_details);
}
```

---

## 🚀 Deployment

### Deploy All Functions

```bash
# Deploy all monetization functions
supabase functions deploy pricing-plans
supabase functions deploy calculate-price
supabase functions deploy purchase-subscription
supabase functions deploy check-access
supabase functions deploy upgrade-subscription
supabase functions deploy subscriptions
supabase functions deploy grant-trial
```

### Deploy Script

```bash
#!/bin/bash
FUNCTIONS=(
  "pricing-plans"
  "calculate-price"
  "purchase-subscription"
  "check-access"
  "upgrade-subscription"
  "subscriptions"
  "grant-trial"
)

for func in "${FUNCTIONS[@]}"; do
  echo "Deploying $func..."
  supabase functions deploy $func
done

echo "All functions deployed!"
```

### Environment Variables

Required in Supabase project settings:
- `SUPABASE_URL` - auto-provided
- `SUPABASE_ANON_KEY` - auto-provided

---

## ⚡ Performance

### Edge Function Characteristics

- **Cold start:** ~200-500ms
- **Warm execution:** ~10-50ms
- **Timeout:** 60 seconds
- **Max payload:** 10MB

### Optimization Tips

1. **Database queries:**
   - Use database functions (faster)
   - Minimize round trips
   - Use proper indexes (already in Krok 1)

2. **Response size:**
   - Paginate large lists
   - Use `select` to limit columns
   - Gzip compression (automatic)

3. **Caching:**
   - Client-side caching of plans
   - Access checks can be cached (1-5 min)
   - Use ETags for conditional requests

---

## 📝 TODO / Future Enhancements

### Payment Gateway Integration
- [ ] Stripe integration
- [ ] PayU integration
- [ ] Webhook handling for payment confirmation
- [ ] Payment status tracking

### Advanced Features
- [ ] Proration for mid-cycle upgrades
- [ ] Refunds on cancellation
- [ ] Bulk operations API
- [ ] Webhooks for subscription events
- [ ] Invoice generation PDF

### Monitoring
- [ ] Request logging
- [ ] Error tracking (Sentry)
- [ ] Performance metrics
- [ ] Usage analytics

### Testing
- [ ] Integration tests
- [ ] Load testing
- [ ] Security audit

---

## ✅ Checklist Kroku 3

- [x] Edge Functions utworzone (7)
- [x] Shared utilities (4)
- [x] Authentication & authorization
- [x] Zod validation schemas
- [x] Error handling standardowy
- [x] CORS configuration
- [x] Database integration
- [x] README z examples
- [x] Deployment instructions
- [ ] **Deployment na Supabase** (czeka na użytkownika)
- [ ] **Testing na production** (czeka na użytkownika)

---

**Status:** ✅ Gotowe do Deploy  
**Technologie:** Supabase Edge Functions (Deno), Zod, TypeScript  
**Next:** Wdrożenie i testowanie

**Wszystkie 3 Kroki Zakończone!**
1. ✅ Krok 1: Database Schema (DONE)
2. ✅ Krok 2: Business Logic (DONE)
3. ✅ Krok 3: API Endpoints (DONE)

Teraz można przejść do Kroku 4: Frontend UI lub najpierw wdrożyć i przetestować API.
