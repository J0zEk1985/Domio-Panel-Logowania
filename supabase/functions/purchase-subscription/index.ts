/**
 * Purchase Subscription API
 * 
 * POST /purchase-subscription
 * Complete workflow: calculate price → create payment intent → create subscription
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
  requireOrgAdmin,
  parseBody,
  type AuthContext
} from '../_shared/monetization/auth.ts';
import {
  PurchaseSubscriptionSchema,
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
    return await handlePurchaseSubscription(req);
  } catch (error: any) {
    console.error('Error in purchase-subscription function:', error);
    return internalError(error.message);
  }
});

/**
 * POST /purchase-subscription
 * Purchase a subscription for a module
 */
async function handlePurchaseSubscription(req: Request): Promise<Response> {
  // Authentication required
  const authResult = await requireAuth(req);
  if (authResult instanceof Response) return authResult;
  
  const { user, supabase } = authResult as AuthContext;

  // Parse and validate body
  const bodyResult = await parseBody(req);
  if (bodyResult instanceof Response) return bodyResult;

  const validation = validate(PurchaseSubscriptionSchema, bodyResult);
  if (!validation.success) {
    return validationError(formatZodErrors(validation.errors));
  }

  const purchaseData = validation.data;

  try {
    // Get user's org (assuming purchaser_org_id from membership)
    const { data: membership, error: membershipError } = await supabase
      .from('memberships')
      .select('org_id, role')
      .eq('user_id', user.id)
      .in('role', ['owner', 'wlasciciel', 'admin', 'administrator'])
      .single();

    if (membershipError || !membership) {
      return errorResponse(
        'NO_ORG_ADMIN',
        'You must be an admin of an organization to purchase subscriptions',
        403
      );
    }

    const purchaser_org_id = membership.org_id;

    // Verify admin access
    const adminCheck = await requireOrgAdmin(supabase, user.id, purchaser_org_id);
    if (adminCheck instanceof Response) return adminCheck;

    // Fetch plan
    const { data: plan, error: planError } = await supabase
      .from('module_pricing_plans')
      .select('*')
      .eq('id', purchaseData.plan_id)
      .eq('is_active', true)
      .single();

    if (planError) {
      if (planError.code === 'PGRST116') {
        return notFoundError('Pricing plan');
      }
      return internalError(`Failed to fetch plan: ${planError.message}`);
    }

    // Calculate price
    let unitCount: number | null = null;
    let calculatedAmount: number;

    if (plan.is_unit_based) {
      if (!purchaseData.beneficiary_community_id) {
        return errorResponse(
          'MISSING_COMMUNITY',
          'beneficiary_community_id is required for unit-based plans',
          400
        );
      }

      // Count units
      const { data: countData, error: countError } = await supabase
        .rpc('count_residential_units_for_community', {
          p_community_id: purchaseData.beneficiary_community_id
        });

      if (countError) {
        return internalError(`Failed to count units: ${countError.message}`);
      }

      unitCount = countData || 0;

      // Calculate price
      const { data: priceData, error: priceError } = await supabase
        .rpc('calculate_unit_based_price', {
          p_plan_id: plan.id,
          p_unit_count: unitCount
        });

      if (priceError) {
        return internalError(`Failed to calculate price: ${priceError.message}`);
      }

      calculatedAmount = priceData;
    } else {
      // Flat-rate pricing
      if (purchaseData.billing_interval === 'monthly') {
        if (!plan.price_monthly) {
          return errorResponse('NO_MONTHLY_PRICE', 'Plan does not have monthly pricing', 400);
        }
        calculatedAmount = plan.price_monthly;
      } else if (purchaseData.billing_interval === 'yearly') {
        if (!plan.price_yearly) {
          return errorResponse('NO_YEARLY_PRICE', 'Plan does not have yearly pricing', 400);
        }
        calculatedAmount = plan.price_yearly;
      } else {
        return errorResponse('INVALID_INTERVAL', 'Invalid billing interval', 400);
      }
    }

    let promoCode: string | null = null;
    if (purchaseData.promo_code) {
      const { data: preview, error: promoError } = await supabase.rpc('preview_promo_code', {
        p_code: purchaseData.promo_code,
        p_billing_interval: purchaseData.billing_interval,
      });

      if (promoError) {
        return internalError(`Failed to check promo code: ${promoError.message}`);
      }

      const promo = (preview ?? {}) as {
        ok?: boolean;
        error?: string;
        code?: string;
        discount_percent?: number | null;
        discount_amount?: number | null;
      };

      if (!promo.ok) {
        const promoMessages: Record<string, string> = {
          EMPTY: 'Wpisz kod promocyjny.',
          EXPIRED: 'Ten kod promocyjny wygasł.',
          LIMIT: 'Ten kod promocyjny został już wykorzystany.',
          INTERVAL_NOT_ALLOWED: 'Ten kod promocyjny nie może być użyty dla wybranego okresu rozliczenia.',
        };
        return errorResponse(
          promo.error ?? 'INVALID',
          promoMessages[promo.error ?? ''] ?? 'Nieprawidłowy kod promocyjny.',
          400,
        );
      }

      const listPrice = calculatedAmount;
      const percent = promo.discount_percent == null ? null : Number(promo.discount_percent);
      const amountOff = promo.discount_amount == null ? null : Number(promo.discount_amount);
      if (percent != null && Number.isFinite(percent)) {
        calculatedAmount *= 1 - percent / 100;
      }
      if (amountOff != null && Number.isFinite(amountOff)) {
        calculatedAmount -= amountOff;
      }
      calculatedAmount = Math.max(0, Math.round(calculatedAmount * 100) / 100);
      promoCode = promo.code ?? purchaseData.promo_code;

      if (calculatedAmount !== listPrice) {
        console.info('[purchase-subscription] promo applied', promoCode, listPrice, calculatedAmount);
      }
    }

    // Get invoice entity data
    let invoiceEntityName = null;
    let invoiceEntityNip = null;
    
    if (purchaseData.invoice_entity_community_id || purchaseData.beneficiary_community_id) {
      const communityId = purchaseData.invoice_entity_community_id || purchaseData.beneficiary_community_id;
      const { data: community } = await supabase
        .from('communities')
        .select('legal_name, nip')
        .eq('id', communityId!)
        .single();

      if (community) {
        invoiceEntityName = community.legal_name;
        invoiceEntityNip = community.nip;
      }
    }

    // Create payment intent
    const { data: paymentIntent, error: intentError } = await supabase
      .from('subscription_payment_intents')
      .insert({
        purchaser_org_id,
        beneficiary_community_id: purchaseData.beneficiary_community_id || null,
        plan_id: plan.id,
        invoice_entity_community_id: purchaseData.invoice_entity_community_id || purchaseData.beneficiary_community_id || null,
        invoice_entity_name: invoiceEntityName,
        invoice_entity_nip: invoiceEntityNip,
        unit_count: unitCount,
        calculated_amount: calculatedAmount,
        billing_interval: purchaseData.billing_interval,
        status: 'completed', // Auto-complete for now (integrate payment gateway later)
        payment_method: purchaseData.payment_method || 'manual',
        payment_confirmed_at: new Date().toISOString(),
        calculation_details: {
          unit_count: unitCount,
          calculated_amount: calculatedAmount,
          plan_name: plan.display_name
        }
      })
      .select()
      .single();

    if (intentError) {
      return internalError(`Failed to create payment intent: ${intentError.message}`);
    }

    // Calculate expiry date
    const expiresAt = new Date();
    if (purchaseData.billing_interval === 'monthly') {
      expiresAt.setMonth(expiresAt.getMonth() + 1);
    } else if (purchaseData.billing_interval === 'yearly') {
      expiresAt.setFullYear(expiresAt.getFullYear() + 1);
    }

    // Create subscription
    const { data: subscription, error: subscriptionError } = await supabase
      .from('module_subscriptions')
      .insert({
        purchaser_org_id,
        beneficiary_community_id: purchaseData.beneficiary_community_id || null,
        invoice_entity_community_id: purchaseData.invoice_entity_community_id || purchaseData.beneficiary_community_id || null,
        plan_id: plan.id,
        module: plan.module,
        status: 'active',
        billing_interval: purchaseData.billing_interval,
        amount_paid: calculatedAmount,
        paid_unit_count: unitCount,
        expires_at: expiresAt.toISOString(),
        purchase_metadata: {
          payment_intent_id: paymentIntent.id,
          payment_method: purchaseData.payment_method || 'manual',
          purchased_by: user.id,
          purchased_at: new Date().toISOString(),
          promo_code: promoCode,
        }
      })
      .select()
      .single();

    if (subscriptionError) {
      return internalError(`Failed to create subscription: ${subscriptionError.message}`);
    }

    if (promoCode) {
      const { data: redeemed, error: redeemError } = await supabase.rpc('redeem_promo_code', {
        p_code: promoCode,
        p_billing_interval: purchaseData.billing_interval,
      });
      if (redeemError || !(redeemed as { ok?: boolean } | null)?.ok) {
        console.error('[purchase-subscription] redeem_promo_code:', redeemError ?? redeemed);
      }
    }

    // Update payment intent with subscription_id
    await supabase
      .from('subscription_payment_intents')
      .update({
        subscription_id: subscription.id,
        fulfilled_at: new Date().toISOString()
      })
      .eq('id', paymentIntent.id);

    return successResponse({
      subscription,
      payment_intent: paymentIntent,
      message: 'Subskrypcja została pomyślnie zakupiona'
    }, 201);
  } catch (error: any) {
    return internalError(error.message);
  }
}
