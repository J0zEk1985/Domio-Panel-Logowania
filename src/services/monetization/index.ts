/**
 * DOMIO Monetization Services
 * 
 * Main export file for all monetization services
 */

// Services
export {
  PricingService,
  createPricingService
} from './pricing.service';

export {
  SubscriptionService,
  createSubscriptionService,
  type SubscriptionFilters,
  type SubscriptionWithDetails
} from './subscription.service';

export {
  PurchaseService,
  createPurchaseService,
  type PurchaseCalculation,
  type InvoiceData
} from './purchase.service';

export {
  AccessControlService,
  createAccessControlService,
  type ManualGrantInput
} from './access-control.service';

export {
  NotificationService,
  createNotificationService,
  type NotificationRecipient,
  type NotificationPayload,
  type NotificationTemplateType
} from './notification.service';

// Re-export types from monetization.ts
export type {
  PricingPlan,
  CreatePricingPlanInput,
  ModuleSubscription,
  CreateSubscriptionInput,
  ModuleAccessGrant,
  SubscriptionPaymentIntent,
  CreatePaymentIntentInput,
  SubscriptionEvent,
  AppModule,
  SubscriptionStatus,
  BillingInterval,
  PaymentStatus,
  CalculatePriceResponse,
  PurchaseSubscriptionRequest,
  PurchaseSubscriptionResponse,
  CheckAccessInput,
  CheckAccessResult
} from '../../types/monetization';

// Composite Service Factory
import { SupabaseClient } from '@supabase/supabase-js';
import { PricingService } from './pricing.service';
import { SubscriptionService } from './subscription.service';
import { PurchaseService } from './purchase.service';
import { AccessControlService } from './access-control.service';
import { NotificationService } from './notification.service';

/**
 * Composite service containing all monetization services
 */
export interface MonetizationServices {
  pricing: PricingService;
  subscription: SubscriptionService;
  purchase: PurchaseService;
  accessControl: AccessControlService;
  notification: NotificationService;
}

/**
 * Factory function to create all monetization services at once
 * 
 * @example
 * ```typescript
 * import { createClient } from '@supabase/supabase-js';
 * import { createMonetizationServices } from './services/monetization';
 * 
 * const supabase = createClient(url, key);
 * const services = createMonetizationServices(supabase);
 * 
 * // Use services
 * const plans = await services.pricing.getActivePlans();
 * const hasAccess = await services.accessControl.hasAccess({
 *   org_id: 'xxx',
 *   module: 'home'
 * });
 * ```
 */
export function createMonetizationServices(
  supabase: SupabaseClient
): MonetizationServices {
  return {
    pricing: new PricingService(supabase),
    subscription: new SubscriptionService(supabase),
    purchase: new PurchaseService(supabase),
    accessControl: new AccessControlService(supabase),
    notification: new NotificationService(supabase)
  };
}

/**
 * Helper hook for React components (if using React)
 * 
 * @example
 * ```typescript
 * function MyComponent() {
 *   const services = useMonetizationServices();
 *   
 *   useEffect(() => {
 *     services.pricing.getActivePlans().then(setPlans);
 *   }, []);
 * }
 * ```
 */
export function useMonetizationServices(): MonetizationServices {
  // TODO: Implement with your React context or state management
  throw new Error('useMonetizationServices not implemented. Implement with your React context.');
}
