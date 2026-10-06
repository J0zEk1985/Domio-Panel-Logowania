/**
 * DOMIO Monetization Layer - TypeScript Types
 * 
 * Module access model, unit-based pricing, subscription management
 */

// ============================================================================
// ENUMS
// ============================================================================

export type AppModule = 
  | 'admin'              // Administracja
  | 'cleaning'           // Cleaning
  | 'maintenance'        // Serwis
  | 'home'               // DOMIO Home (community app)
  | 'fleet'              // Flota
  | 'developer_warranty' // Usterki deweloperskie (global premium)

export type SubscriptionStatus = 
  | 'active'                   // Aktywna
  | 'blocked_pending_payment'  // Zablokowana - czeka na dopłatę
  | 'expired'                  // Wygasła
  | 'cancelled'                // Anulowana
  | 'suspended'                // Zawieszona (admin action)

export type BillingInterval = 
  | 'monthly'   // Miesięczny
  | 'yearly'    // Roczny
  | 'one_time'  // Jednorazowy

// ============================================================================
// PRICING PLANS (Service Owner Configuration)
// ============================================================================

export interface PricingPlan {
  id: string
  
  // Module identification
  module: AppModule
  
  // Plan naming (Polish UI)
  display_name: string
  description: string | null
  
  // Pricing model flags
  is_global: boolean          // true = org-wide (developer_warranty), false = community-based (home)
  is_unit_based: boolean      // true = price per unit (home), false = flat rate
  
  // Unit-based pricing (for home)
  price_per_unit: number | null  // Cena za lokal
  min_price: number | null       // Minimalna kwota (próg cenowy)
  
  // Flat pricing (for developer_warranty or other modules)
  price_monthly: number | null   // Cena miesięczna
  price_yearly: number | null    // Cena roczna
  
  // Availability
  is_active: boolean
  available_from: string | null  // timestamptz
  available_until: string | null // timestamptz
  
  // Metadata
  features: string[]            // Lista funkcji do wyświetlenia w UI
  terms_conditions: string | null
  
  // Timestamps
  created_at: string            // timestamptz
  updated_at: string            // timestamptz
  created_by: string | null     // uuid
}

export interface CreatePricingPlanInput {
  module: AppModule
  display_name: string
  description?: string
  is_global: boolean
  is_unit_based: boolean
  price_per_unit?: number
  min_price?: number
  price_monthly?: number
  price_yearly?: number
  features?: string[]
  terms_conditions?: string
  available_from?: string
  available_until?: string
}

// ============================================================================
// SUBSCRIPTIONS (Purchased Licenses)
// ============================================================================

export interface ModuleSubscription {
  id: string
  
  // Who purchased (always org/admin)
  purchaser_org_id: string
  
  // Who benefits (community for home, null for global/org-level like developer_warranty)
  beneficiary_community_id: string | null
  
  // Invoice entity (who appears on invoice - usually community even though org pays)
  invoice_entity_community_id: string | null
  
  // Plan reference
  plan_id: string
  module: AppModule
  
  // Status
  status: SubscriptionStatus
  
  // Unit-based subscription tracking (for home)
  paid_unit_count: number | null       // Liczba opłaconych lokali
  current_unit_count: number | null    // Aktualna liczba lokali
  
  // Billing period
  billing_interval: BillingInterval
  amount_paid: number                  // Kwota zapłacona
  
  // Lifecycle dates
  purchased_at: string                 // timestamptz
  activated_at: string | null          // timestamptz
  expires_at: string | null            // timestamptz
  blocked_at: string | null            // timestamptz
  blocked_reason: string | null
  cancelled_at: string | null          // timestamptz
  
  // Metadata
  purchase_metadata: Record<string, any>
  
  // Timestamps
  created_at: string                   // timestamptz
  updated_at: string                   // timestamptz
}

export interface CreateSubscriptionInput {
  purchaser_org_id: string
  beneficiary_community_id?: string
  invoice_entity_community_id?: string
  plan_id: string
  module: AppModule
  billing_interval: BillingInterval
  amount_paid: number
  paid_unit_count?: number
  expires_at?: string
  purchase_metadata?: Record<string, any>
}

// ============================================================================
// MODULE ACCESS CONTROL (License Check)
// ============================================================================

export interface ModuleAccessGrant {
  id: string
  
  // Grant scope
  org_id: string
  community_id: string | null
  module: AppModule
  
  // Access control
  is_granted: boolean
  granted_by_subscription_id: string | null
  
  // Override for manual grants (e.g., trial, migration, special deals)
  is_manual_grant: boolean
  manual_grant_reason: string | null
  manual_granted_by: string | null
  
  // Lifecycle
  granted_at: string          // timestamptz
  expires_at: string | null   // timestamptz
  revoked_at: string | null   // timestamptz
  
  // Timestamps
  created_at: string          // timestamptz
  updated_at: string          // timestamptz
}

export interface CheckAccessInput {
  org_id: string
  community_id?: string
  module: AppModule
}

export interface CheckAccessResult {
  has_access: boolean
  grant?: ModuleAccessGrant
  reason?: string
}

// ============================================================================
// SUBSCRIPTION EVENTS (Audit Trail)
// ============================================================================

export type SubscriptionEventType = 
  | 'created'
  | 'activated'
  | 'blocked'
  | 'unblocked'
  | 'renewed'
  | 'cancelled'
  | 'expired'
  | 'unit_threshold_exceeded'
  | 'status_changed'

export interface SubscriptionEvent {
  id: string
  subscription_id: string
  
  event_type: SubscriptionEventType
  event_data: Record<string, any>
  
  triggered_by_user_id: string | null
  triggered_at: string  // timestamptz
}

// ============================================================================
// PAYMENT INTENTS / ORDERS (Pre-purchase calculation)
// ============================================================================

export type PaymentStatus = 
  | 'pending'      // Oczekuje
  | 'completed'    // Zakończone
  | 'failed'       // Niepowodzenie
  | 'cancelled'    // Anulowane

export interface SubscriptionPaymentIntent {
  id: string
  
  // Purchase details
  purchaser_org_id: string
  beneficiary_community_id: string | null
  plan_id: string
  
  // Invoice data
  invoice_entity_community_id: string | null
  invoice_entity_name: string | null
  invoice_entity_nip: string | null
  invoice_entity_address: Record<string, any> | null
  
  // Calculated pricing
  unit_count: number | null
  calculated_amount: number
  billing_interval: BillingInterval
  
  // Payment tracking
  status: PaymentStatus
  payment_method: string | null
  payment_confirmed_at: string | null  // timestamptz
  
  // Fulfillment
  subscription_id: string | null
  fulfilled_at: string | null          // timestamptz
  
  // Metadata
  calculation_details: Record<string, any>
  
  // Timestamps
  created_at: string                   // timestamptz
  updated_at: string                   // timestamptz
  created_by: string | null            // uuid
}

export interface CreatePaymentIntentInput {
  purchaser_org_id: string
  beneficiary_community_id?: string
  plan_id: string
  billing_interval: BillingInterval
  unit_count?: number
  invoice_entity_community_id?: string
  payment_method?: string
}

export interface PaymentIntentCalculation {
  unit_count?: number
  price_per_unit?: number
  min_price?: number
  calculated_amount: number
  breakdown: {
    base_price: number
    unit_based_price?: number
    applied_price: number
  }
}

// ============================================================================
// API RESPONSES
// ============================================================================

export interface CalculatePriceResponse {
  plan_id: string
  module: AppModule
  unit_count?: number
  calculated_amount: number
  billing_interval: BillingInterval
  calculation_details: PaymentIntentCalculation
}

export interface PurchaseSubscriptionRequest {
  plan_id: string
  beneficiary_community_id?: string
  billing_interval: BillingInterval
  payment_method?: string
  invoice_entity_community_id?: string
}

export interface PurchaseSubscriptionResponse {
  payment_intent: SubscriptionPaymentIntent
  subscription?: ModuleSubscription
  message: string
}

// ============================================================================
// UI HELPERS
// ============================================================================

export const MODULE_DISPLAY_NAMES: Record<AppModule, string> = {
  admin: 'Administracja',
  cleaning: 'Cleaning',
  maintenance: 'Serwis',
  home: 'DOMIO Home',
  fleet: 'Flota',
  developer_warranty: 'Usterki Deweloperskie'
}

export const SUBSCRIPTION_STATUS_LABELS: Record<SubscriptionStatus, string> = {
  active: 'Aktywna',
  blocked_pending_payment: 'Zablokowana - wymaga dopłaty',
  expired: 'Wygasła',
  cancelled: 'Anulowana',
  suspended: 'Zawieszona'
}

export const BILLING_INTERVAL_LABELS: Record<BillingInterval, string> = {
  monthly: 'Miesięczny',
  yearly: 'Roczny',
  one_time: 'Jednorazowy'
}

export const PAYMENT_STATUS_LABELS: Record<PaymentStatus, string> = {
  pending: 'Oczekuje',
  completed: 'Zakończone',
  failed: 'Niepowodzenie',
  cancelled: 'Anulowane'
}

// ============================================================================
// VALIDATION HELPERS
// ============================================================================

export function validateUnitBasedPlan(plan: Partial<PricingPlan>): string[] {
  const errors: string[] = []
  
  if (plan.is_unit_based) {
    if (!plan.price_per_unit || plan.price_per_unit <= 0) {
      errors.push('Cena za lokal musi być większa niż 0')
    }
    if (!plan.min_price || plan.min_price <= 0) {
      errors.push('Minimalna kwota musi być większa niż 0')
    }
  } else {
    if (!plan.price_monthly && !plan.price_yearly) {
      errors.push('Wymagana cena miesięczna lub roczna')
    }
  }
  
  return errors
}

export function isSubscriptionBlocked(subscription: ModuleSubscription): boolean {
  return subscription.status === 'blocked_pending_payment'
}

export function needsPaymentUpgrade(subscription: ModuleSubscription): boolean {
  if (!subscription.paid_unit_count || !subscription.current_unit_count) {
    return false
  }
  return subscription.current_unit_count > subscription.paid_unit_count
}

export function calculateUpgradeAmount(
  subscription: ModuleSubscription,
  plan: PricingPlan
): number | null {
  if (!plan.is_unit_based || !plan.price_per_unit || !plan.min_price) {
    return null
  }
  
  if (!subscription.current_unit_count || !subscription.paid_unit_count) {
    return null
  }
  
  const additional_units = subscription.current_unit_count - subscription.paid_unit_count
  if (additional_units <= 0) {
    return 0
  }
  
  // Calculate new total price with current unit count
  const new_price = Math.max(
    plan.min_price,
    plan.price_per_unit * subscription.current_unit_count
  )
  
  // Subtract already paid amount
  const upgrade_amount = new_price - subscription.amount_paid
  
  return Math.max(0, upgrade_amount)
}
