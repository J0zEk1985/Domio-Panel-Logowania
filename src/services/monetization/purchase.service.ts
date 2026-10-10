/**
 * PurchaseService - Obsługa Procesu Zakupu
 * 
 * Odpowiedzialność:
 * - Kalkulacja kosztów przed zakupem
 * - Tworzenie payment intents
 * - Zarządzanie danymi do faktury
 * - Finalizacja zakupu i tworzenie subskrypcji
 * - Upgrade subskrypcji przy przekroczeniu limitu
 */

import { SupabaseClient } from '@supabase/supabase-js';
import {
  SubscriptionPaymentIntent,
  CreatePaymentIntentInput,
  PurchaseSubscriptionRequest,
  PurchaseSubscriptionResponse,
  BillingInterval,
  ModuleSubscription,
  PaymentStatus
} from '../../types/monetization';
import { PricingService } from './pricing.service';
import { SubscriptionService } from './subscription.service';

export interface PurchaseCalculation {
  unit_count?: number;
  calculated_amount: number;
  billing_interval: BillingInterval;
  plan_name: string;
  breakdown: {
    base_amount: number;
    min_price_applied?: boolean;
    unit_price?: number;
    savings?: number; // For yearly plans
  };
}

export interface InvoiceData {
  entity_name: string;
  entity_nip?: string;
  entity_address?: {
    street?: string;
    city?: string;
    postal_code?: string;
    country?: string;
  };
}

export class PurchaseService {
  private pricingService: PricingService;
  private subscriptionService: SubscriptionService;

  constructor(private supabase: SupabaseClient) {
    this.pricingService = new PricingService(supabase);
    this.subscriptionService = new SubscriptionService(supabase);
  }

  // =========================================================================
  // PUBLIC METHODS - Pre-Purchase Calculation
  // =========================================================================

  /**
   * Oblicza koszt zakupu przed utworzeniem payment intent
   */
  async calculatePurchaseCost(
    planId: string,
    billingInterval: BillingInterval,
    communityId?: string
  ): Promise<PurchaseCalculation> {
    const plan = await this.pricingService.getPlanById(planId);
    if (!plan) {
      throw new Error('Plan not found');
    }

    let unitCount: number | undefined;
    let calculatedAmount: number;
    let breakdown: PurchaseCalculation['breakdown'];

    if (plan.is_unit_based) {
      // Unit-based pricing (home module)
      if (!communityId) {
        throw new Error('Community ID is required for unit-based plans');
      }

      // Pobierz liczbę lokali mieszkalnych
      unitCount = await this.countResidentialUnits(communityId);

      const priceResult = await this.pricingService.calculateUnitBasedPrice(
        planId,
        unitCount,
        billingInterval
      );

      calculatedAmount = priceResult.calculated_amount;

      breakdown = {
        base_amount: (plan.price_per_unit || 0) * unitCount,
        min_price_applied: calculatedAmount === plan.min_price,
        unit_price: plan.price_per_unit || 0
      };
    } else {
      // Flat-rate pricing (developer_warranty, fleet)
      const priceResult = await this.pricingService.calculateFlatPrice(
        planId,
        billingInterval
      );

      calculatedAmount = priceResult.calculated_amount;

      breakdown = {
        base_amount: calculatedAmount
      };

      // Oblicz oszczędność dla planu rocznego
      if (billingInterval === 'yearly') {
        const savings = this.pricingService.calculateYearlySavings(plan);
        if (savings) {
          breakdown.savings = savings;
        }
      }
    }

    return {
      unit_count: unitCount,
      calculated_amount: calculatedAmount,
      billing_interval: billingInterval,
      plan_name: plan.display_name,
      breakdown
    };
  }

  /**
   * Liczy lokale mieszkalne dla wspólnoty (bez pomieszczeń technicznych)
   */
  private async countResidentialUnits(communityId: string): Promise<number> {
    const { data, error } = await this.supabase
      .rpc('count_residential_units_for_community', {
        p_community_id: communityId
      });

    if (error) {
      throw new Error(`Failed to count units: ${error.message}`);
    }

    return Number(data) || 0;
  }

  // =========================================================================
  // PUBLIC METHODS - Payment Intent Management
  // =========================================================================

  /**
   * Tworzy payment intent (zamówienie przed płatnością)
   */
  async createPaymentIntent(
    input: CreatePaymentIntentInput
  ): Promise<SubscriptionPaymentIntent> {
    // Walidacja
    this.validatePaymentIntentInput(input);

    // Oblicz koszt
    const calculation = await this.calculatePurchaseCost(
      input.plan_id,
      input.billing_interval,
      input.beneficiary_community_id
    );

    // Pobierz dane do faktury
    let invoiceData: InvoiceData | null = null;
    if (input.invoice_entity_community_id) {
      invoiceData = await this.getCommunityInvoiceData(
        input.invoice_entity_community_id
      );
    }

    // Utwórz payment intent
    const { data, error } = await this.supabase
      .from('subscription_payment_intents')
      .insert({
        purchaser_org_id: input.purchaser_org_id,
        beneficiary_community_id: input.beneficiary_community_id || null,
        plan_id: input.plan_id,
        invoice_entity_community_id: input.invoice_entity_community_id || null,
        invoice_entity_name: invoiceData?.entity_name || null,
        invoice_entity_nip: invoiceData?.entity_nip || null,
        invoice_entity_address: invoiceData?.entity_address || null,
        unit_count: calculation.unit_count || null,
        calculated_amount: calculation.calculated_amount,
        billing_interval: input.billing_interval,
        status: 'pending',
        payment_method: input.payment_method || null,
        calculation_details: {
          ...calculation,
          calculated_at: new Date().toISOString()
        }
      })
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create payment intent: ${error.message}`);
    }

    return data;
  }

  /**
   * Pobiera payment intent po ID
   */
  async getPaymentIntent(intentId: string): Promise<SubscriptionPaymentIntent | null> {
    const { data, error } = await this.supabase
      .from('subscription_payment_intents')
      .select('*')
      .eq('id', intentId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return null;
      }
      throw new Error(`Failed to fetch payment intent: ${error.message}`);
    }

    return data;
  }

  /**
   * Aktualizuje status payment intent
   */
  async updatePaymentIntentStatus(
    intentId: string,
    status: PaymentStatus,
    paymentMethod?: string
  ): Promise<SubscriptionPaymentIntent> {
    const updates: any = { status };

    if (status === 'completed') {
      updates.payment_confirmed_at = new Date().toISOString();
    }

    if (paymentMethod) {
      updates.payment_method = paymentMethod;
    }

    const { data, error } = await this.supabase
      .from('subscription_payment_intents')
      .update(updates)
      .eq('id', intentId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update payment intent: ${error.message}`);
    }

    return data;
  }

  /**
   * Anuluje payment intent
   */
  async cancelPaymentIntent(intentId: string): Promise<void> {
    await this.updatePaymentIntentStatus(intentId, 'cancelled');
  }

  // =========================================================================
  // PUBLIC METHODS - Purchase Completion
  // =========================================================================

  /**
   * Finalizuje zakup - tworzy subskrypcję po potwierdzeniu płatności
   */
  async completePurchase(intentId: string): Promise<ModuleSubscription> {
    const intent = await this.getPaymentIntent(intentId);
    if (!intent) {
      throw new Error('Payment intent not found');
    }

    if (intent.status !== 'completed') {
      throw new Error('Payment intent is not completed');
    }

    if (intent.subscription_id) {
      // Already fulfilled
      const subscription = await this.subscriptionService.getSubscriptionById(
        intent.subscription_id
      );
      if (subscription) {
        return subscription;
      }
    }

    // Pobierz plan
    const plan = await this.pricingService.getPlanById(intent.plan_id);
    if (!plan) {
      throw new Error('Plan not found');
    }

    // Oblicz expires_at
    const expiresAt = this.calculateExpiryDate(intent.billing_interval);

    // Utwórz subskrypcję
    const subscription = await this.subscriptionService.createSubscription({
      purchaser_org_id: intent.purchaser_org_id,
      beneficiary_community_id: intent.beneficiary_community_id || undefined,
      invoice_entity_community_id: intent.invoice_entity_community_id || undefined,
      plan_id: intent.plan_id,
      module: plan.module,
      billing_interval: intent.billing_interval,
      amount_paid: intent.calculated_amount,
      paid_unit_count: intent.unit_count || undefined,
      expires_at: expiresAt,
      purchase_metadata: {
        payment_intent_id: intentId,
        payment_method: intent.payment_method,
        purchased_at: new Date().toISOString(),
        calculation_details: intent.calculation_details
      }
    });

    // Zaktualizuj payment intent
    await this.supabase
      .from('subscription_payment_intents')
      .update({
        subscription_id: subscription.id,
        fulfilled_at: new Date().toISOString()
      })
      .eq('id', intentId);

    return subscription;
  }

  /**
   * Pełny workflow zakupu: kalkulacja → intent → płatność → subskrypcja
   */
  async purchaseSubscription(
    request: PurchaseSubscriptionRequest,
    purchaserOrgId: string
  ): Promise<PurchaseSubscriptionResponse> {
    void request;
    void purchaserOrgId;
    throw new Error(
      'Płatność online nie jest jeszcze dostępna. Plan można aktywować tylko kodem rabatowym 100%.'
    );
  }

  // =========================================================================
  // PUBLIC METHODS - Upgrade & Top-up
  // =========================================================================

  /**
   * Oblicza koszt upgrade'u przy przekroczeniu limitu lokali
   */
  async calculateUpgradeCost(subscriptionId: string): Promise<{
    current_unit_count: number;
    paid_unit_count: number;
    additional_units: number;
    upgrade_amount: number;
    new_total_amount: number;
  }> {
    const subscription = await this.subscriptionService.getSubscriptionById(
      subscriptionId
    );

    if (!subscription) {
      throw new Error('Subscription not found');
    }

    if (!subscription.paid_unit_count || !subscription.current_unit_count) {
      throw new Error('Subscription is not unit-based');
    }

    const plan = await this.pricingService.getPlanById(subscription.plan_id);
    if (!plan || !plan.is_unit_based) {
      throw new Error('Plan is not unit-based');
    }

    const additionalUnits = subscription.current_unit_count - subscription.paid_unit_count;

    if (additionalUnits <= 0) {
      return {
        current_unit_count: subscription.current_unit_count,
        paid_unit_count: subscription.paid_unit_count,
        additional_units: 0,
        upgrade_amount: 0,
        new_total_amount: subscription.amount_paid
      };
    }

    // Oblicz nową cenę z aktualną liczbą lokali
    const newPrice = await this.pricingService.calculateUnitBasedPrice(
      plan.id,
      subscription.current_unit_count,
      subscription.billing_interval
    );

    const upgradeAmount = Math.max(0, newPrice.calculated_amount - subscription.amount_paid);

    return {
      current_unit_count: subscription.current_unit_count,
      paid_unit_count: subscription.paid_unit_count,
      additional_units: additionalUnits,
      upgrade_amount: upgradeAmount,
      new_total_amount: newPrice.calculated_amount
    };
  }

  /**
   * Wykonuje upgrade subskrypcji (dopłata za dodatkowe lokale)
   */
  async upgradeSubscription(
    subscriptionId: string,
    paymentMethod?: string
  ): Promise<ModuleSubscription> {
    const subscription = await this.subscriptionService.getSubscriptionById(
      subscriptionId
    );

    if (!subscription) {
      throw new Error('Subscription not found');
    }

    const upgradeCost = await this.calculateUpgradeCost(subscriptionId);

    if (upgradeCost.upgrade_amount <= 0) {
      throw new Error('No upgrade needed - subscription is not over limit');
    }

    // Utwórz payment intent dla upgrade'u
    const plan = await this.pricingService.getPlanById(subscription.plan_id);
    if (!plan) {
      throw new Error('Plan not found');
    }

    const intent = await this.supabase
      .from('subscription_payment_intents')
      .insert({
        purchaser_org_id: subscription.purchaser_org_id,
        beneficiary_community_id: subscription.beneficiary_community_id,
        plan_id: subscription.plan_id,
        invoice_entity_community_id: subscription.invoice_entity_community_id,
        unit_count: upgradeCost.current_unit_count,
        calculated_amount: upgradeCost.upgrade_amount,
        billing_interval: subscription.billing_interval,
        status: 'completed', // Auto-complete for upgrade
        payment_method: paymentMethod || 'upgrade',
        payment_confirmed_at: new Date().toISOString(),
        subscription_id: subscriptionId,
        fulfilled_at: new Date().toISOString(),
        calculation_details: {
          type: 'upgrade',
          from_units: upgradeCost.paid_unit_count,
          to_units: upgradeCost.current_unit_count,
          additional_units: upgradeCost.additional_units,
          upgrade_amount: upgradeCost.upgrade_amount
        }
      })
      .select()
      .single();

    if (intent.error) {
      throw new Error(`Failed to create upgrade intent: ${intent.error.message}`);
    }

    // Odblokuj subskrypcję
    const upgraded = await this.subscriptionService.unblockSubscription(
      subscriptionId,
      upgradeCost.current_unit_count,
      upgradeCost.upgrade_amount
    );

    return upgraded;
  }

  // =========================================================================
  // PRIVATE METHODS
  // =========================================================================

  private validatePaymentIntentInput(input: CreatePaymentIntentInput): void {
    if (!input.purchaser_org_id) {
      throw new Error('purchaser_org_id is required');
    }

    if (!input.plan_id) {
      throw new Error('plan_id is required');
    }

    if (!input.billing_interval) {
      throw new Error('billing_interval is required');
    }
  }

  private async getCommunityInvoiceData(communityId: string): Promise<InvoiceData> {
    const { data, error } = await this.supabase
      .from('communities')
      .select('legal_name, nip, regon')
      .eq('id', communityId)
      .single();

    if (error) {
      throw new Error(`Failed to fetch community data: ${error.message}`);
    }

    return {
      entity_name: data.legal_name || 'N/A',
      entity_nip: data.nip || undefined,
      entity_address: {} // TODO: Extract from communities table
    };
  }

  private calculateExpiryDate(billingInterval: BillingInterval): string {
    const now = new Date();

    if (billingInterval === 'monthly') {
      now.setMonth(now.getMonth() + 1);
    } else if (billingInterval === 'yearly') {
      now.setFullYear(now.getFullYear() + 1);
    }

    return now.toISOString();
  }
}

// =========================================================================
// FACTORY FUNCTION
// =========================================================================

export function createPurchaseService(supabase: SupabaseClient): PurchaseService {
  return new PurchaseService(supabase);
}
