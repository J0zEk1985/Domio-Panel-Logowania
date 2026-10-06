/**
 * Subscriptions API
 * 
 * Endpoints:
 * - GET  /subscriptions           - List user's org subscriptions
 * - GET  /subscriptions/:id       - Get subscription details
 * - POST /subscriptions/:id/cancel - Cancel subscription
 * - POST /subscriptions/:id/renew  - Renew subscription
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
  getQueryParam,
  type AuthContext
} from '../_shared/monetization/auth.ts';
import {
  SubscriptionFiltersSchema,
  CancelSubscriptionSchema,
  RenewSubscriptionSchema,
  validate,
  formatZodErrors
} from '../_shared/monetization/validation.ts';

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return corsPreflightResponse();
  }

  try {
    const url = new URL(req.url);
    const pathParts = url.pathname.split('/').filter(Boolean);
    
    // Extract subscription_id and action
    const subscriptionId = pathParts[pathParts.length - 2] === 'subscriptions' || pathParts[pathParts.length - 1] === 'subscriptions'
      ? null
      : pathParts.find((p, i) => pathParts[i - 1] === 'subscriptions');
    
    const action = pathParts[pathParts.length - 1];

    // Route requests
    if (req.method === 'GET') {
      if (subscriptionId && action === subscriptionId) {
        return await handleGetSubscription(req, subscriptionId);
      } else {
        return await handleListSubscriptions(req);
      }
    } else if (req.method === 'POST') {
      if (!subscriptionId) {
        return errorResponse('MISSING_ID', 'Subscription ID is required', 400);
      }
      
      if (action === 'cancel') {
        return await handleCancelSubscription(req, subscriptionId);
      } else if (action === 'renew') {
        return await handleRenewSubscription(req, subscriptionId);
      } else {
        return methodNotAllowedError(['GET', 'POST']);
      }
    } else {
      return methodNotAllowedError(['GET', 'POST']);
    }
  } catch (error: any) {
    console.error('Error in subscriptions function:', error);
    return internalError(error.message);
  }
});

/**
 * GET /subscriptions
 * List subscriptions for user's organization(s)
 */
async function handleListSubscriptions(req: Request): Promise<Response> {
  // Authentication required
  const authResult = await requireAuth(req);
  if (authResult instanceof Response) return authResult;
  
  const { user, supabase } = authResult as AuthContext;

  try {
    // Get user's organizations
    const { data: memberships, error: membershipError } = await supabase
      .from('memberships')
      .select('org_id')
      .eq('user_id', user.id);

    if (membershipError || !memberships || memberships.length === 0) {
      return successResponse({
        subscriptions: [],
        count: 0
      });
    }

    const orgIds = memberships.map(m => m.org_id);

    // Parse filters
    const module = getQueryParam(req, 'module');
    const status = getQueryParam(req, 'status');
    const includeExpired = getQueryParam(req, 'include_expired') === 'true';

    let query = supabase
      .from('module_subscriptions')
      .select('*, module_pricing_plans!inner(*)')
      .in('purchaser_org_id', orgIds)
      .order('created_at', { ascending: false });

    // Apply filters
    if (module) {
      query = query.eq('module', module);
    }

    if (status) {
      query = query.eq('status', status);
    }

    if (!includeExpired) {
      query = query.neq('status', 'expired');
    }

    const { data, error } = await query;

    if (error) {
      return internalError(`Failed to fetch subscriptions: ${error.message}`);
    }

    return successResponse({
      subscriptions: data || [],
      count: data?.length || 0
    });
  } catch (error: any) {
    return internalError(error.message);
  }
}

/**
 * GET /subscriptions/:id
 * Get subscription details with full information
 */
async function handleGetSubscription(req: Request, subscriptionId: string): Promise<Response> {
  // Authentication required
  const authResult = await requireAuth(req);
  if (authResult instanceof Response) return authResult;
  
  const { user, supabase } = authResult as AuthContext;

  try {
    const { data: subscription, error: subscriptionError } = await supabase
      .from('module_subscriptions')
      .select(`
        *,
        module_pricing_plans(*),
        communities:beneficiary_community_id(*),
        organizations:purchaser_org_id(*)
      `)
      .eq('id', subscriptionId)
      .single();

    if (subscriptionError) {
      if (subscriptionError.code === 'PGRST116') {
        return notFoundError('Subscription');
      }
      return internalError(`Failed to fetch subscription: ${subscriptionError.message}`);
    }

    // Verify user is member of purchaser org
    const { data: membership } = await supabase
      .from('memberships')
      .select('id')
      .eq('user_id', user.id)
      .eq('org_id', subscription.purchaser_org_id)
      .single();

    if (!membership) {
      return errorResponse(
        'FORBIDDEN',
        'You do not have access to this subscription',
        403
      );
    }

    // Get subscription events
    const { data: events } = await supabase
      .from('subscription_events')
      .select('*')
      .eq('subscription_id', subscriptionId)
      .order('triggered_at', { ascending: false })
      .limit(20);

    return successResponse({
      subscription,
      events: events || [],
      health_status: getHealthStatus(subscription)
    });
  } catch (error: any) {
    return internalError(error.message);
  }
}

/**
 * POST /subscriptions/:id/cancel
 * Cancel subscription
 */
async function handleCancelSubscription(req: Request, subscriptionId: string): Promise<Response> {
  // Authentication required
  const authResult = await requireAuth(req);
  if (authResult instanceof Response) return authResult;
  
  const { user, supabase } = authResult as AuthContext;

  // Parse body (optional reason)
  const bodyResult = await parseBody(req);
  const body = bodyResult instanceof Response ? {} : bodyResult;

  const validation = validate(CancelSubscriptionSchema, { subscription_id: subscriptionId, ...body });
  if (!validation.success) {
    return validationError(formatZodErrors(validation.errors));
  }

  try {
    // Fetch subscription
    const { data: subscription, error: subscriptionError } = await supabase
      .from('module_subscriptions')
      .select('*')
      .eq('id', subscriptionId)
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

    // Cancel subscription
    const { data: cancelled, error: cancelError } = await supabase
      .from('module_subscriptions')
      .update({
        status: 'cancelled',
        cancelled_at: new Date().toISOString()
      })
      .eq('id', subscriptionId)
      .select()
      .single();

    if (cancelError) {
      return internalError(`Failed to cancel subscription: ${cancelError.message}`);
    }

    // Revoke access grant
    await supabase
      .from('module_access_grants')
      .update({
        is_granted: false,
        revoked_at: new Date().toISOString()
      })
      .eq('granted_by_subscription_id', subscriptionId);

    return successResponse({
      subscription: cancelled,
      message: 'Subskrypcja została anulowana'
    });
  } catch (error: any) {
    return internalError(error.message);
  }
}

/**
 * POST /subscriptions/:id/renew
 * Renew subscription
 */
async function handleRenewSubscription(req: Request, subscriptionId: string): Promise<Response> {
  // Authentication required
  const authResult = await requireAuth(req);
  if (authResult instanceof Response) return authResult;
  
  const { user, supabase } = authResult as AuthContext;

  // Parse and validate body
  const bodyResult = await parseBody(req);
  if (bodyResult instanceof Response) return bodyResult;

  const validation = validate(RenewSubscriptionSchema, { subscription_id: subscriptionId, ...bodyResult });
  if (!validation.success) {
    return validationError(formatZodErrors(validation.errors));
  }

  const { billing_interval, payment_method } = validation.data;

  try {
    // Fetch subscription
    const { data: subscription, error: subscriptionError } = await supabase
      .from('module_subscriptions')
      .select('*, module_pricing_plans(*)')
      .eq('id', subscriptionId)
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

    // Calculate renewal price
    const plan = subscription.module_pricing_plans;
    let renewalAmount: number;

    if (plan.is_unit_based) {
      // Recalculate based on current unit count
      const { data: price, error: priceError } = await supabase
        .rpc('calculate_unit_based_price', {
          p_plan_id: plan.id,
          p_unit_count: subscription.current_unit_count || subscription.paid_unit_count
        });

      if (priceError) {
        return internalError(`Failed to calculate price: ${priceError.message}`);
      }

      renewalAmount = price;
    } else {
      // Flat rate
      renewalAmount = billing_interval === 'monthly' 
        ? plan.price_monthly 
        : plan.price_yearly;
    }

    // Calculate new expiry date
    const baseDate = subscription.expires_at && new Date(subscription.expires_at) > new Date()
      ? new Date(subscription.expires_at)
      : new Date();

    const newExpiresAt = new Date(baseDate);
    if (billing_interval === 'monthly') {
      newExpiresAt.setMonth(newExpiresAt.getMonth() + 1);
    } else if (billing_interval === 'yearly') {
      newExpiresAt.setFullYear(newExpiresAt.getFullYear() + 1);
    }

    // Get renewal history
    const renewalHistory = subscription.purchase_metadata?.renewal_history || [];

    // Renew subscription
    const { data: renewed, error: renewError } = await supabase
      .from('module_subscriptions')
      .update({
        status: 'active',
        expires_at: newExpiresAt.toISOString(),
        billing_interval,
        amount_paid: subscription.amount_paid + renewalAmount,
        purchase_metadata: {
          ...subscription.purchase_metadata,
          renewal_history: [
            ...renewalHistory,
            {
              previous_expires_at: subscription.expires_at,
              new_expires_at: newExpiresAt.toISOString(),
              amount_paid: renewalAmount,
              renewed_at: new Date().toISOString(),
              renewed_by: user.id
            }
          ]
        }
      })
      .eq('id', subscriptionId)
      .select()
      .single();

    if (renewError) {
      return internalError(`Failed to renew subscription: ${renewError.message}`);
    }

    return successResponse({
      subscription: renewed,
      renewal_details: {
        amount_paid: renewalAmount,
        new_expires_at: newExpiresAt.toISOString()
      },
      message: 'Subskrypcja została odnowiona'
    });
  } catch (error: any) {
    return internalError(error.message);
  }
}

/**
 * Helper: Get subscription health status
 */
function getHealthStatus(subscription: any): string {
  if (subscription.status === 'blocked_pending_payment') {
    return 'blocked';
  }

  if (subscription.paid_unit_count && subscription.current_unit_count && 
      subscription.current_unit_count > subscription.paid_unit_count) {
    return 'needs_upgrade';
  }

  if (subscription.status === 'expired') {
    return 'expired';
  }

  if (subscription.expires_at) {
    const daysLeft = Math.ceil(
      (new Date(subscription.expires_at).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
    );
    if (daysLeft > 0 && daysLeft <= 7) {
      return 'expiring_soon';
    }
  }

  return 'healthy';
}
