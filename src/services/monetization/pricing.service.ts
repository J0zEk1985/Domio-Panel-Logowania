/**
 * PricingService - Zarządzanie Planami Cenowymi
 * 
 * Odpowiedzialność:
 * - CRUD operacje na pricing_plans
 * - Kalkulacja cen dla różnych typów planów
 * - Walidacja planów cenowych
 * - Pobieranie dostępnych planów dla klientów
 */

import { SupabaseClient } from '@supabase/supabase-js';
import {
  PricingPlan,
  CreatePricingPlanInput,
  AppModule,
  CalculatePriceResponse,
  BillingInterval,
  PaymentIntentCalculation
} from '../../types/monetization';

export class PricingService {
  constructor(private supabase: SupabaseClient) {}

  // =========================================================================
  // PUBLIC METHODS - Service Owner Operations
  // =========================================================================

  /**
   * Pobiera wszystkie aktywne plany cenowe
   */
  async getActivePlans(): Promise<PricingPlan[]> {
    const { data, error } = await this.supabase
      .from('module_pricing_plans')
      .select('*')
      .eq('is_active', true)
      .order('module', { ascending: true })
      .order('display_name', { ascending: true });

    if (error) {
      throw new Error(`Failed to fetch pricing plans: ${error.message}`);
    }

    return data || [];
  }

  /**
   * Pobiera plany dla konkretnego modułu
   */
  async getPlansByModule(module: AppModule): Promise<PricingPlan[]> {
    const { data, error } = await this.supabase
      .from('module_pricing_plans')
      .select('*')
      .eq('module', module)
      .eq('is_active', true)
      .order('display_name', { ascending: true });

    if (error) {
      throw new Error(`Failed to fetch plans for module ${module}: ${error.message}`);
    }

    return data || [];
  }

  /**
   * Pobiera plan po ID
   */
  async getPlanById(planId: string): Promise<PricingPlan | null> {
    const { data, error } = await this.supabase
      .from('module_pricing_plans')
      .select('*')
      .eq('id', planId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return null; // Not found
      }
      throw new Error(`Failed to fetch plan: ${error.message}`);
    }

    return data;
  }

  /**
   * Tworzy nowy plan cenowy (Service Owner only)
   */
  async createPlan(input: CreatePricingPlanInput): Promise<PricingPlan> {
    // Walidacja przed zapisem
    this.validatePlanInput(input);

    const { data, error } = await this.supabase
      .from('module_pricing_plans')
      .insert({
        module: input.module,
        display_name: input.display_name,
        description: input.description || null,
        is_global: input.is_global,
        is_unit_based: input.is_unit_based,
        price_per_unit: input.price_per_unit || null,
        min_price: input.min_price || null,
        price_monthly: input.price_monthly || null,
        price_yearly: input.price_yearly || null,
        features: input.features || [],
        terms_conditions: input.terms_conditions || null,
        available_from: input.available_from || null,
        available_until: input.available_until || null,
        is_active: true
      })
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create plan: ${error.message}`);
    }

    return data;
  }

  /**
   * Aktualizuje plan cenowy
   */
  async updatePlan(
    planId: string, 
    updates: Partial<CreatePricingPlanInput>
  ): Promise<PricingPlan> {
    // Walidacja przed zapisem
    if (Object.keys(updates).length > 0) {
      this.validatePlanInput(updates);
    }

    const { data, error } = await this.supabase
      .from('module_pricing_plans')
      .update(updates)
      .eq('id', planId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update plan: ${error.message}`);
    }

    return data;
  }

  /**
   * Deaktywuje plan (soft delete)
   */
  async deactivatePlan(planId: string): Promise<void> {
    const { error } = await this.supabase
      .from('module_pricing_plans')
      .update({ is_active: false })
      .eq('id', planId);

    if (error) {
      throw new Error(`Failed to deactivate plan: ${error.message}`);
    }
  }

  /**
   * Aktywuje plan
   */
  async activatePlan(planId: string): Promise<void> {
    const { error } = await this.supabase
      .from('module_pricing_plans')
      .update({ is_active: true })
      .eq('id', planId);

    if (error) {
      throw new Error(`Failed to activate plan: ${error.message}`);
    }
  }

  // =========================================================================
  // PUBLIC METHODS - Price Calculation
  // =========================================================================

  /**
   * Oblicza cenę dla planu unit-based (home)
   * Formula: MAX(min_price, price_per_unit * unit_count)
   */
  async calculateUnitBasedPrice(
    planId: string,
    unitCount: number,
    billingInterval: BillingInterval = 'monthly'
  ): Promise<CalculatePriceResponse> {
    if (unitCount < 0) {
      throw new Error('Unit count must be a positive number');
    }

    const plan = await this.getPlanById(planId);
    if (!plan) {
      throw new Error('Plan not found');
    }

    if (!plan.is_unit_based) {
      throw new Error('Plan is not unit-based. Use calculateFlatPrice instead.');
    }

    if (!plan.price_per_unit || !plan.min_price) {
      throw new Error('Plan is missing price_per_unit or min_price');
    }

    // Wywołaj funkcję bazodanową dla spójności
    const { data, error } = await this.supabase
      .rpc('calculate_unit_based_price', {
        p_plan_id: planId,
        p_unit_count: unitCount
      });

    if (error) {
      throw new Error(`Failed to calculate price: ${error.message}`);
    }

    const calculatedAmount = Number(data);

    const breakdown: PaymentIntentCalculation = {
      unit_count: unitCount,
      price_per_unit: plan.price_per_unit,
      min_price: plan.min_price,
      calculated_amount: calculatedAmount,
      breakdown: {
        base_price: plan.price_per_unit * unitCount,
        unit_based_price: plan.price_per_unit * unitCount,
        applied_price: calculatedAmount
      }
    };

    return {
      plan_id: planId,
      module: plan.module,
      unit_count: unitCount,
      calculated_amount: calculatedAmount,
      billing_interval: billingInterval,
      calculation_details: breakdown
    };
  }

  /**
   * Oblicza cenę dla planu flat-rate (developer_warranty, fleet)
   */
  async calculateFlatPrice(
    planId: string,
    billingInterval: BillingInterval
  ): Promise<CalculatePriceResponse> {
    const plan = await this.getPlanById(planId);
    if (!plan) {
      throw new Error('Plan not found');
    }

    if (plan.is_unit_based) {
      throw new Error('Plan is unit-based. Use calculateUnitBasedPrice instead.');
    }

    let calculatedAmount: number;

    if (billingInterval === 'monthly') {
      if (!plan.price_monthly) {
        throw new Error('Plan does not have monthly pricing');
      }
      calculatedAmount = plan.price_monthly;
    } else if (billingInterval === 'yearly') {
      if (!plan.price_yearly) {
        throw new Error('Plan does not have yearly pricing');
      }
      calculatedAmount = plan.price_yearly;
    } else {
      throw new Error('Invalid billing interval for flat rate plan');
    }

    const breakdown: PaymentIntentCalculation = {
      calculated_amount: calculatedAmount,
      breakdown: {
        base_price: calculatedAmount,
        applied_price: calculatedAmount
      }
    };

    return {
      plan_id: planId,
      module: plan.module,
      calculated_amount: calculatedAmount,
      billing_interval: billingInterval,
      calculation_details: breakdown
    };
  }

  /**
   * Universal price calculator - automatycznie wybiera metodę
   */
  async calculatePrice(
    planId: string,
    billingInterval: BillingInterval,
    unitCount?: number
  ): Promise<CalculatePriceResponse> {
    const plan = await this.getPlanById(planId);
    if (!plan) {
      throw new Error('Plan not found');
    }

    if (plan.is_unit_based) {
      if (unitCount === undefined) {
        throw new Error('Unit count is required for unit-based plans');
      }
      return this.calculateUnitBasedPrice(planId, unitCount, billingInterval);
    } else {
      return this.calculateFlatPrice(planId, billingInterval);
    }
  }

  // =========================================================================
  // PRIVATE METHODS - Validation
  // =========================================================================

  private validatePlanInput(input: Partial<CreatePricingPlanInput>): void {
    // Walidacja unit-based plan
    if (input.is_unit_based === true) {
      if (!input.price_per_unit || input.price_per_unit <= 0) {
        throw new Error('Unit-based plan must have price_per_unit > 0');
      }
      if (!input.min_price || input.min_price <= 0) {
        throw new Error('Unit-based plan must have min_price > 0');
      }
      if (input.price_monthly || input.price_yearly) {
        throw new Error('Unit-based plan should not have monthly/yearly prices');
      }
    }

    // Walidacja flat-rate plan
    if (input.is_unit_based === false) {
      if (!input.price_monthly && !input.price_yearly) {
        throw new Error('Flat-rate plan must have either price_monthly or price_yearly');
      }
      if (input.price_per_unit || input.min_price) {
        throw new Error('Flat-rate plan should not have unit-based pricing');
      }
    }

    // Walidacja kwot
    if (input.price_per_unit !== undefined && input.price_per_unit < 0) {
      throw new Error('price_per_unit must be >= 0');
    }
    if (input.min_price !== undefined && input.min_price < 0) {
      throw new Error('min_price must be >= 0');
    }
    if (input.price_monthly !== undefined && input.price_monthly < 0) {
      throw new Error('price_monthly must be >= 0');
    }
    if (input.price_yearly !== undefined && input.price_yearly < 0) {
      throw new Error('price_yearly must be >= 0');
    }

    // Walidacja dat
    if (input.available_from && input.available_until) {
      const from = new Date(input.available_from);
      const until = new Date(input.available_until);
      if (from > until) {
        throw new Error('available_from must be before available_until');
      }
    }

    // Walidacja display_name
    if (input.display_name !== undefined) {
      if (!input.display_name || input.display_name.trim().length === 0) {
        throw new Error('display_name cannot be empty');
      }
      if (input.display_name.length > 200) {
        throw new Error('display_name cannot exceed 200 characters');
      }
    }
  }

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  /**
   * Sprawdza czy plan jest dostępny w danym momencie
   */
  isPlanAvailable(plan: PricingPlan, atDate?: Date): boolean {
    if (!plan.is_active) {
      return false;
    }

    const checkDate = atDate || new Date();

    if (plan.available_from) {
      const from = new Date(plan.available_from);
      if (checkDate < from) {
        return false;
      }
    }

    if (plan.available_until) {
      const until = new Date(plan.available_until);
      if (checkDate > until) {
        return false;
      }
    }

    return true;
  }

  /**
   * Pobiera tylko dostępne plany (biorąc pod uwagę daty)
   */
  async getAvailablePlans(module?: AppModule): Promise<PricingPlan[]> {
    let query = this.supabase
      .from('module_pricing_plans')
      .select('*')
      .eq('is_active', true);

    if (module) {
      query = query.eq('module', module);
    }

    const { data, error } = await query.order('display_name', { ascending: true });

    if (error) {
      throw new Error(`Failed to fetch available plans: ${error.message}`);
    }

    const now = new Date();
    return (data || []).filter(plan => this.isPlanAvailable(plan, now));
  }

  /**
   * Oblicza oszczędność przy wyborze planu rocznego
   */
  calculateYearlySavings(plan: PricingPlan): number | null {
    if (plan.is_unit_based || !plan.price_monthly || !plan.price_yearly) {
      return null;
    }

    const yearlyFromMonthly = plan.price_monthly * 12;
    const savings = yearlyFromMonthly - plan.price_yearly;

    return Math.max(0, savings);
  }

  /**
   * Oblicza procent oszczędności przy planie rocznym
   */
  calculateYearlySavingsPercent(plan: PricingPlan): number | null {
    const savings = this.calculateYearlySavings(plan);
    if (savings === null || !plan.price_monthly) {
      return null;
    }

    const yearlyFromMonthly = plan.price_monthly * 12;
    return Math.round((savings / yearlyFromMonthly) * 100);
  }
}

// =========================================================================
// FACTORY FUNCTION
// =========================================================================

/**
 * Tworzy instancję PricingService z Supabase client
 */
export function createPricingService(supabase: SupabaseClient): PricingService {
  return new PricingService(supabase);
}
