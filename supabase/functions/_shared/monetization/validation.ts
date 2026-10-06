/**
 * Zod Validation Schemas for Monetization API
 */

import { z } from 'npm:zod@3';

// Enums
export const AppModuleSchema = z.enum([
  'admin',
  'cleaning',
  'maintenance',
  'home',
  'fleet',
  'developer_warranty'
]);

export const BillingIntervalSchema = z.enum(['monthly', 'yearly', 'one_time']);

export const SubscriptionStatusSchema = z.enum([
  'active',
  'blocked_pending_payment',
  'expired',
  'cancelled',
  'suspended'
]);

// Pricing Plans
const PricingPlanObjectSchema = z.object({
  module: AppModuleSchema,
  display_name: z.string().min(1).max(200),
  description: z.string().optional(),
  is_global: z.boolean(),
  is_unit_based: z.boolean(),
  price_per_unit: z.number().min(0).optional(),
  min_price: z.number().min(0).optional(),
  price_monthly: z.number().min(0).optional(),
  price_yearly: z.number().min(0).optional(),
  features: z.array(z.string()).optional(),
  terms_conditions: z.string().optional(),
  available_from: z.string().datetime().optional(),
  available_until: z.string().datetime().optional()
});

export const CreatePricingPlanSchema = PricingPlanObjectSchema.refine(
  (data) => {
    // Unit-based plans must have price_per_unit and min_price
    if (data.is_unit_based) {
      return data.price_per_unit !== undefined && 
             data.price_per_unit > 0 &&
             data.min_price !== undefined && 
             data.min_price > 0;
    }
    return true;
  },
  {
    message: 'Unit-based plans must have price_per_unit and min_price greater than 0'
  }
).refine(
  (data) => {
    // Flat-rate plans must have monthly or yearly price
    if (!data.is_unit_based) {
      return data.price_monthly !== undefined || data.price_yearly !== undefined;
    }
    return true;
  },
  {
    message: 'Flat-rate plans must have either price_monthly or price_yearly'
  }
);

export const UpdatePricingPlanSchema = PricingPlanObjectSchema.partial();

// Calculate Price
export const CalculatePriceSchema = z.object({
  plan_id: z.string().uuid(),
  billing_interval: BillingIntervalSchema,
  community_id: z.string().uuid().optional(),
  unit_count: z.number().int().min(0).optional()
});

// Purchase Subscription
export const PurchaseSubscriptionSchema = z.object({
  plan_id: z.string().uuid(),
  beneficiary_community_id: z.string().uuid().optional(),
  billing_interval: BillingIntervalSchema,
  payment_method: z.string().optional(),
  invoice_entity_community_id: z.string().uuid().optional()
});

// Upgrade Subscription
export const UpgradeSubscriptionSchema = z.object({
  subscription_id: z.string().uuid(),
  payment_method: z.string().optional()
});

// Renew Subscription
export const RenewSubscriptionSchema = z.object({
  subscription_id: z.string().uuid(),
  billing_interval: BillingIntervalSchema,
  payment_method: z.string().optional()
});

// Cancel Subscription
export const CancelSubscriptionSchema = z.object({
  subscription_id: z.string().uuid(),
  reason: z.string().optional()
});

// Check Access
export const CheckAccessSchema = z.object({
  org_id: z.string().uuid(),
  community_id: z.string().uuid().optional(),
  module: AppModuleSchema
});

// Grant Trial
export const GrantTrialSchema = z.object({
  org_id: z.string().uuid(),
  community_id: z.string().uuid().optional(),
  module: AppModuleSchema,
  duration_days: z.number().int().min(1).max(90).optional().default(7),
  reason: z.string().optional()
});

// Query Parameters
export const PaginationSchema = z.object({
  page: z.coerce.number().int().min(1).optional().default(1),
  per_page: z.coerce.number().int().min(1).max(100).optional().default(20)
});

export const SubscriptionFiltersSchema = z.object({
  module: AppModuleSchema.optional(),
  status: SubscriptionStatusSchema.optional(),
  include_expired: z.coerce.boolean().optional().default(false)
});

/**
 * Validate data against schema and return errors or parsed data
 */
export function validate<T>(
  schema: z.ZodSchema<T>,
  data: any
): { success: true; data: T } | { success: false; errors: z.ZodError } {
  const result = schema.safeParse(data);
  
  if (result.success) {
    return { success: true, data: result.data };
  } else {
    return { success: false, errors: result.error };
  }
}

/**
 * Format Zod errors for API response
 */
export function formatZodErrors(errors: z.ZodError): any {
  return errors.errors.map(err => ({
    path: err.path.join('.'),
    message: err.message,
    code: err.code
  }));
}
