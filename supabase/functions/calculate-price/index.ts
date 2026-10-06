/**
 * Calculate Price API
 * 
 * POST /calculate-price
 * Calculates subscription price before purchase
 * Supports both unit-based (home) and flat-rate (developer_warranty) plans
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';
import {
  successResponse,
  errorResponse,
  validationError,
  notFoundError,
  internalError,
  methodNotAllowedError,
  corsPreflightResponse
} from '../_shared/monetization/responses.ts';
import {
  requireAuth,
  parseBody,
  type AuthContext
} from '../_shared/monetization/auth.ts';
import {
  CalculatePriceSchema,
  validate,
  formatZodErrors
} from '../_shared/monetization/validation.ts';

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return corsPreflightResponse();
  }

  if (req.method !== 'POST') {
    return methodNotAllowedError(['POST']);
  }

  try {
    return await handleCalculatePrice(req);
  } catch (error: any) {
    console.error('Error in calculate-price function:', error);
    return internalError(error.message);
  }
});

/**
 * POST /calculate-price
 * Calculate subscription price with breakdown
 */
async function handleCalculatePrice(req: Request): Promise<Response> {
  // Authentication required
  const authResult = await requireAuth(req);
  if (authResult instanceof Response) return authResult;
  
  const { supabase } = authResult as AuthContext;

  // Parse and validate body
  const bodyResult = await parseBody(req);
  if (bodyResult instanceof Response) return bodyResult;

  const validation = validate(CalculatePriceSchema, bodyResult);
  if (!validation.success) {
    return validationError(formatZodErrors(validation.errors));
  }

  const { plan_id, billing_interval, community_id, unit_count } = validation.data;

  try {
    // Fetch plan
    const { data: plan, error: planError } = await supabase
      .from('module_pricing_plans')
      .select('*')
      .eq('id', plan_id)
      .eq('is_active', true)
      .single();

    if (planError) {
      if (planError.code === 'PGRST116') {
        return notFoundError('Pricing plan');
      }
      return internalError(`Failed to fetch plan: ${planError.message}`);
    }

    // Calculate based on plan type
    if (plan.is_unit_based) {
      // Unit-based pricing (home module)
      return await calculateUnitBasedPrice(supabase, plan, billing_interval, community_id, unit_count);
    } else {
      // Flat-rate pricing (developer_warranty, fleet)
      return await calculateFlatPrice(plan, billing_interval);
    }
  } catch (error: any) {
    return internalError(error.message);
  }
}

/**
 * Calculate price for unit-based plan
 */
async function calculateUnitBasedPrice(
  supabase: any,
  plan: any,
  billing_interval: string,
  community_id?: string,
  unit_count?: number
): Promise<Response> {
  // If unit_count not provided, count from database
  let finalUnitCount = unit_count;

  if (!finalUnitCount && community_id) {
    const { data: countData, error: countError } = await supabase
      .rpc('count_residential_units_for_community', {
        p_community_id: community_id
      });

    if (countError) {
      return internalError(`Failed to count units: ${countError.message}`);
    }

    finalUnitCount = countData || 0;
  }

  if (finalUnitCount === undefined) {
    return errorResponse(
      'MISSING_UNIT_COUNT',
      'Unit count or community_id is required for unit-based plans',
      400
    );
  }

  // Calculate price using database function
  const { data: calculatedAmount, error: calcError } = await supabase
    .rpc('calculate_unit_based_price', {
      p_plan_id: plan.id,
      p_unit_count: finalUnitCount
    });

  if (calcError) {
    return internalError(`Failed to calculate price: ${calcError.message}`);
  }

  const basePrice = plan.price_per_unit * finalUnitCount;
  const minPriceApplied = calculatedAmount === plan.min_price;

  return successResponse({
    plan_id: plan.id,
    module: plan.module,
    plan_name: plan.display_name,
    unit_count: finalUnitCount,
    calculated_amount: calculatedAmount,
    billing_interval,
    breakdown: {
      price_per_unit: plan.price_per_unit,
      min_price: plan.min_price,
      base_price: basePrice,
      min_price_applied: minPriceApplied,
      final_amount: calculatedAmount
    }
  });
}

/**
 * Calculate price for flat-rate plan
 */
async function calculateFlatPrice(
  plan: any,
  billing_interval: string
): Promise<Response> {
  let calculatedAmount: number;

  if (billing_interval === 'monthly') {
    if (!plan.price_monthly) {
      return errorResponse(
        'NO_MONTHLY_PRICE',
        'This plan does not have monthly pricing',
        400
      );
    }
    calculatedAmount = plan.price_monthly;
  } else if (billing_interval === 'yearly') {
    if (!plan.price_yearly) {
      return errorResponse(
        'NO_YEARLY_PRICE',
        'This plan does not have yearly pricing',
        400
      );
    }
    calculatedAmount = plan.price_yearly;
  } else {
    return errorResponse(
      'INVALID_INTERVAL',
      'Invalid billing interval for this plan',
      400
    );
  }

  // Calculate savings for yearly
  let savings = null;
  if (billing_interval === 'yearly' && plan.price_monthly && plan.price_yearly) {
    const yearlyFromMonthly = plan.price_monthly * 12;
    savings = Math.max(0, yearlyFromMonthly - plan.price_yearly);
  }

  return successResponse({
    plan_id: plan.id,
    module: plan.module,
    plan_name: plan.display_name,
    calculated_amount: calculatedAmount,
    billing_interval,
    breakdown: {
      base_price: calculatedAmount,
      final_amount: calculatedAmount,
      savings: savings,
      savings_percent: savings && plan.price_monthly 
        ? Math.round((savings / (plan.price_monthly * 12)) * 100)
        : null
    }
  });
}
