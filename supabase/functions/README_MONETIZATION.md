# DOMIO Monetization API - Edge Functions

## 📋 Overview

Supabase Edge Functions dla systemu monetyzacji DOMIO. Wszystkie endpointy wymagają autoryzacji przez Supabase Auth (JWT token).

**Base URL:** `https://your-project-ref.supabase.co/functions/v1/`

**Authentication:** Bearer Token w header `Authorization`

## 🔧 Deployed Functions

| Function | Method | Description | Auth Required | Admin Only |
|----------|--------|-------------|---------------|------------|
| `pricing-plans` | GET | Lista planów cenowych | ✅ | ❌ |
| `pricing-plans/:id` | GET | Szczegóły planu | ✅ | ❌ |
| `pricing-plans` | POST | Tworzenie planu | ✅ | ✅ Owner |
| `pricing-plans/:id` | PUT | Aktualizacja planu | ✅ | ✅ Owner |
| `pricing-plans/:id` | DELETE | Dezaktywacja planu | ✅ | ✅ Owner |
| `calculate-price` | POST | Kalkulacja ceny | ✅ | ❌ |
| `purchase-subscription` | POST | Zakup subskrypcji | ✅ | ✅ Admin |
| `subscriptions` | GET | Lista subskrypcji | ✅ | ❌ |
| `subscriptions/:id` | GET | Szczegóły subskrypcji | ✅ | ❌ |
| `subscriptions/:id/cancel` | POST | Anulowanie | ✅ | ✅ Admin |
| `subscriptions/:id/renew` | POST | Odnowienie | ✅ | ✅ Admin |
| `upgrade-subscription` | POST | Upgrade subskrypcji | ✅ | ✅ Admin |
| `check-access` | POST | Sprawdzenie dostępu | ✅ | ❌ |
| `grant-trial` | POST | Nadanie triala | ✅ | ✅ Owner |

## 📝 API Examples

### 1. Pricing Plans

#### List Active Plans
```bash
curl -X GET \
  https://your-project.supabase.co/functions/v1/pricing-plans \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Query Parameters:**
- `module` (optional): Filter by module (`home`, `developer_warranty`, etc.)
- `is_active` (optional): Filter active plans (default: `true`)

**Response:**
```json
{
  "success": true,
  "data": {
    "plans": [
      {
        "id": "uuid",
        "module": "home",
        "display_name": "DOMIO Home Standard",
        "is_unit_based": true,
        "price_per_unit": 2.50,
        "min_price": 99.00,
        "features": ["Feature 1", "Feature 2"]
      }
    ],
    "count": 1
  }
}
```

#### Create Plan (Service Owner Only)
```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/pricing-plans \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "module": "home",
    "display_name": "DOMIO Home Standard",
    "description": "Plan podstawowy dla wspólnot",
    "is_global": false,
    "is_unit_based": true,
    "price_per_unit": 2.50,
    "min_price": 99.00,
    "features": ["Dostęp dla mieszkańców", "Tablica ogłoszeń"]
  }'
```

---

### 2. Calculate Price

```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/calculate-price \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "plan_id": "plan-uuid",
    "billing_interval": "yearly",
    "community_id": "community-uuid"
  }'
```

**Request Body:**
```typescript
{
  plan_id: string;          // UUID of pricing plan
  billing_interval: "monthly" | "yearly";
  community_id?: string;    // Required for unit-based plans
  unit_count?: number;      // Optional, will count from DB if not provided
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "plan_id": "uuid",
    "module": "home",
    "plan_name": "DOMIO Home Standard",
    "unit_count": 50,
    "calculated_amount": 125.00,
    "billing_interval": "yearly",
    "breakdown": {
      "price_per_unit": 2.50,
      "min_price": 99.00,
      "base_price": 125.00,
      "min_price_applied": false,
      "final_amount": 125.00
    }
  }
}
```

---

### 3. Purchase Subscription

```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/purchase-subscription \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "plan_id": "plan-uuid",
    "beneficiary_community_id": "community-uuid",
    "billing_interval": "yearly",
    "invoice_entity_community_id": "community-uuid",
    "payment_method": "transfer"
  }'
```

**Request Body:**
```typescript
{
  plan_id: string;                        // UUID of pricing plan
  beneficiary_community_id?: string;      // For home module
  billing_interval: "monthly" | "yearly";
  invoice_entity_community_id?: string;   // Who appears on invoice
  payment_method?: string;                // "transfer", "card", etc.
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "subscription": {
      "id": "uuid",
      "module": "home",
      "status": "active",
      "paid_unit_count": 50,
      "amount_paid": 125.00,
      "expires_at": "2027-10-06T00:00:00Z"
    },
    "payment_intent": {
      "id": "uuid",
      "calculated_amount": 125.00,
      "status": "completed"
    },
    "message": "Subskrypcja została pomyślnie zakupiona"
  }
}
```

---

### 4. Check Access

```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/check-access \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "org_id": "org-uuid",
    "community_id": "community-uuid",
    "module": "home"
  }'
```

**Request Body:**
```typescript
{
  org_id: string;
  community_id?: string;  // Optional for global modules
  module: "home" | "developer_warranty" | "fleet" | etc.
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "has_access": true,
    "org_id": "uuid",
    "community_id": "uuid",
    "module": "home",
    "grant": {
      "id": "uuid",
      "granted_at": "2026-10-06T00:00:00Z",
      "expires_at": "2027-10-06T00:00:00Z"
    },
    "message": "Dostęp przyznany"
  }
}
```

---

### 5. List Subscriptions

```bash
curl -X GET \
  "https://your-project.supabase.co/functions/v1/subscriptions?module=home&status=active" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Query Parameters:**
- `module` (optional): Filter by module
- `status` (optional): Filter by status
- `include_expired` (optional): Include expired subscriptions

**Response:**
```json
{
  "success": true,
  "data": {
    "subscriptions": [
      {
        "id": "uuid",
        "module": "home",
        "status": "active",
        "paid_unit_count": 50,
        "current_unit_count": 50,
        "amount_paid": 125.00,
        "expires_at": "2027-10-06T00:00:00Z",
        "pricing_plans": {
          "display_name": "DOMIO Home Standard"
        }
      }
    ],
    "count": 1
  }
}
```

---

### 6. Upgrade Subscription

```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/upgrade-subscription \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subscription_id": "subscription-uuid",
    "payment_method": "card"
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "subscription": {
      "id": "uuid",
      "status": "active",
      "paid_unit_count": 75,
      "current_unit_count": 75,
      "amount_paid": 187.50
    },
    "upgrade_details": {
      "from_units": 50,
      "to_units": 75,
      "additional_payment": 62.50
    },
    "message": "Subskrypcja została pomyślnie zaktualizowana i odblokowana"
  }
}
```

---

### 7. Cancel Subscription

```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/subscriptions/subscription-uuid/cancel \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "User requested cancellation"
  }'
```

---

### 8. Renew Subscription

```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/subscriptions/subscription-uuid/renew \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "billing_interval": "yearly",
    "payment_method": "transfer"
  }'
```

---

### 9. Grant Trial (Service Owner Only)

```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/grant-trial \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "org_id": "org-uuid",
    "community_id": "community-uuid",
    "module": "home",
    "duration_days": 14,
    "reason": "Marketing trial for Q4 2026"
  }'
```

---

## 🚨 Error Responses

All errors follow consistent format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {}
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Missing or invalid JWT token |
| `FORBIDDEN` | 403 | User lacks required permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 400 | Invalid request data |
| `METHOD_NOT_ALLOWED` | 405 | HTTP method not allowed |
| `INTERNAL_ERROR` | 500 | Server error |

---

## 🔐 Authentication

All requests require Supabase Auth JWT token in `Authorization` header:

```javascript
// Frontend example (React)
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Get JWT token
const { data: { session } } = await supabase.auth.getSession();
const token = session?.access_token;

// Make API request
const response = await fetch(
  'https://your-project.supabase.co/functions/v1/pricing-plans',
  {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  }
);

const data = await response.json();
```

---

## 🧪 Testing

### Test in Supabase CLI

```bash
# Deploy function
supabase functions deploy pricing-plans

# Test locally
supabase functions serve pricing-plans

# Test with curl
curl -X GET http://localhost:54321/functions/v1/pricing-plans \
  -H "Authorization: Bearer YOUR_DEV_TOKEN"
```

### Test in Production

Use your Supabase project URL and get JWT token from Auth.

---

## 📊 Rate Limiting

Edge Functions have default rate limits:
- **10 requests/second** per IP
- **100,000 invocations/month** on free tier

For production, consider implementing custom rate limiting.

---

## 🔄 CORS

All functions include CORS headers:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS`
- `Access-Control-Allow-Headers: authorization, x-client-info, apikey, content-type`

---

## 📚 Additional Resources

- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Deno Documentation](https://deno.land/manual)
- [Zod Validation](https://zod.dev/)
