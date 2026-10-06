/**
 * Upgrade Subscription API
 * 
 * POST /upgrade-subscription
 * Upgrade subscription when unit count exceeds paid threshold
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
  UpgradeSubscriptionSchema,
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
    return await handleUpgradeSubscription(req);
  } catch (error: any) {
    console.error('Error in upgrade-subscription function:', error);
    return internalError(error.message);
  }
});

/**
 * POST /upgrade-subscription
 * Upgrade subscription by paying for additional units
 */
async function handleUpgradeSubscription(req: Request): Promise<Response> {
  // Authentication required
  const authResult = await requireAuth(req);
  if (authResult instanceof Response) return authResult;
  
  const { user, supabase } = authResult as AuthContext;

  // Parse and validate body
  const bodyResult = await parseBody(req);
  if (bodyResult instanceof Response) return bodyResult;

  const validation = validate(UpgradeSubscriptionSchema, bodyResult);
  if (!validation.success) {
    return validationError(formatZodErrors(validation.errors));
  }

  const { subscription_id, payment_method } = validation.data;

  try {
    // Fetch subscription
    const { data: subscription, error: subscriptionError } = await supabase
      .from('module_subscriptions')
      .select('*')
      .eq('id', subscription_id)
      .single();

    if (subscriptionError) {
      if (subscriptionError.code === 'PGRST116') {
        return notFoundError('Subscription');
      }
      return internalError(`Failed to fetch subscription: ${subscriptionError.message}`);
    }

    // Verify user is admin of purchaser org
    const adminCheck = await requireOrgAdmin(supabase, user.id, subscription.purchaser_org_id);
    if (adminCheck instanceof Response) return adminCheck;

    // Check if subscription is blocked
    if (subscription.status !== 'blocked_pending_payment') {
      return errorResponse(
        'NOT_BLOCKED',
        'Subscription is not blocked. No upgrade needed.',
        400
      );
    }

    // Check if it's unit-based
    if (!subscription.paid_unit_count || !subscription.current_unit_count) {
      return errorResponse(
        'NOT_UNIT_BASED',
        'Subscription is not unit-based',
        400
      );
    }

    // Fetch plan
    const { data: plan, error: planError } = await supabase
      .from('module_pricing_plans')
      .select('*')
      .eq('id', subscription.plan_id)
      .single();

    if (planError) {
      return internalError(`Failed to fetch plan: ${planError.message}`);
    }

    if (!plan.is_unit_based) {
      return errorResponse(
        'PLAN_NOT_UNIT_BASED',
        'Plan is not unit-based',
        400
      );
    }

    // Calculate upgrade cost
    const { data: newPrice, error: priceError } = await supabase
      .rpc('calculate_unit_based_price', {
        p_plan_id: plan.id,
        p_unit_count: subscription.current_unit_count
      });

    if (priceError) {
      return internalError(`Failed to calculate price: ${priceError.message}`);
    }

    const upgradeAmount = Math.max(0, newPrice - subscription.amount_paid);

    if (upgradeAmount <= 0) {
      return errorResponse(
        'NO_UPGRADE_NEEDED',
        'No upgrade payment needed',
        400
      );
    }

    // Create payment intent for upgrade
    const { data: paymentIntent, error: intentError } = await supabase
      .from('subscription_payment_intents')
      .insert({
        purchaser_org_id: subscription.purchaser_org_id,
        beneficiary_community_id: subscription.beneficiary_community_id,
        plan_id: subscription.plan_id,
        invoice_entity_community_id: subscription.invoice_entity_community_id,
        unit_count: subscription.current_unit_count,
        calculated_amount: upgradeAmount,
        billing_interval: subscription.billing_interval,
        status: 'completed', // Auto-complete for now
        payment_method: payment_method || 'upgrade',
        payment_confirmed_at: new Date().toISOString(),
        subscription_id: subscription_id,
        fulfilled_at: new Date().toISOString(),
        calculation_details: {
          type: 'upgrade',
          from_units: subscription.paid_unit_count,
          to_units: subscription.current_unit_count,
          upgrade_amount: upgradeAmount
        }
      })
      .select()
      .single();

    if (intentError) {
      return internalError(`Failed to create payment intent: ${intentError.message}`);
    }

    // Get current upgrade history
    const upgradeHistory = subscription.purchase_metadata?.upgrade_history || [];

    // Unblock subscription
    const { data: upgraded, error: upgradeError } = await supabase
      .from('module_subscriptions')
      .update({
        status: 'active',
        paid_unit_count: subscription.current_unit_count,
        amount_paid: subscription.amount_paid + upgradeAmount,
        blocked_at: null,
        blocked_reason: null,
        purchase_metadata: {
          ...subscription.purchase_metadata,
          upgrade_history: [
            ...upgradeHistory,
            {
              from_units: subscription.paid_unit_count,
              to_units: subscription.current_unit_count,
              additional_payment: upgradeAmount,
              upgraded_at: new Date().toISOString(),
              upgraded_by: user.id
            }
          ]
        }
      })
      .eq('id', subscription_id)
      .select()
      .single();

    if (upgradeError) {
      return internalError(`Failed to upgrade subscription: ${upgradeError.message}`);
    }

    // Restore access grant
    await supabase
      .from('module_access_grants')
      .update({
        is_granted: true,
        revoked_at: null
      })
      .eq('granted_by_subscription_id', subscription_id);

    return successResponse({
      subscription: upgraded,
      payment_intent: paymentIntent,
      upgrade_details: {
        from_units: subscription.paid_unit_count,
        to_units: subscription.current_unit_count,
        additional_payment: upgradeAmount
      },
      message: 'Subskrypcja została pomyślnie zaktualizowana i odblokowana'
    });
  } catch (error: any) {
    return internalError(error.message);
  }
}
