/**
 * Pricing Plans API
 * 
 * Endpoints:
 * - GET  /pricing-plans           - List active pricing plans
 * - GET  /pricing-plans/:id       - Get plan by ID
 * - POST /pricing-plans           - Create plan (Service Owner only)
 * - PUT  /pricing-plans/:id       - Update plan (Service Owner only)
 * - DELETE /pricing-plans/:id     - Deactivate plan (Service Owner only)
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
  requireServiceOwner,
  parseBody,
  getQueryParam,
  type AuthContext
} from '../_shared/monetization/auth.ts';
import {
  CreatePricingPlanSchema,
  UpdatePricingPlanSchema,
  AppModuleSchema,
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
    const planId = pathParts[pathParts.length - 1] !== 'pricing-plans' 
      ? pathParts[pathParts.length - 1] 
      : null;

    // Route requests
    switch (req.method) {
      case 'GET':
        if (planId) {
          return await handleGetPlanById(req, planId);
        } else {
          return await handleListPlans(req);
        }

      case 'POST':
        return await handleCreatePlan(req);

      case 'PUT':
        if (!planId) {
          return errorResponse('MISSING_ID', 'Plan ID is required for update', 400);
        }
        return await handleUpdatePlan(req, planId);

      case 'DELETE':
        if (!planId) {
          return errorResponse('MISSING_ID', 'Plan ID is required for deletion', 400);
        }
        return await handleDeactivatePlan(req, planId);

      default:
        return methodNotAllowedError(['GET', 'POST', 'PUT', 'DELETE']);
    }
  } catch (error: any) {
    console.error('Error in pricing-plans function:', error);
    return internalError(error.message);
  }
});

/**
 * GET /pricing-plans
 * List active pricing plans with optional filtering
 */
async function handleListPlans(req: Request): Promise<Response> {
  // Authentication required
  const authResult = await requireAuth(req);
  if (authResult instanceof Response) return authResult;
  
  const { supabase } = authResult as AuthContext;

  // Extract filters from query params
  const module = getQueryParam(req, 'module');
  const isActive = getQueryParam(req, 'is_active') !== 'false';

  try {
    let query = supabase
      .from('module_pricing_plans')
      .select('*')
      .order('module', { ascending: true })
      .order('display_name', { ascending: true });

    // Apply filters
    if (isActive) {
      query = query.eq('is_active', true);
    }

    if (module) {
      // Validate module
      const moduleValidation = validate(AppModuleSchema, module);
      if (!moduleValidation.success) {
        return validationError(formatZodErrors(moduleValidation.errors));
      }
      query = query.eq('module', module);
    }

    const { data, error } = await query;

    if (error) {
      return internalError(`Failed to fetch plans: ${error.message}`);
    }

    return successResponse({
      plans: data || [],
      count: data?.length || 0
    });
  } catch (error: any) {
    return internalError(error.message);
  }
}

/**
 * GET /pricing-plans/:id
 * Get specific plan by ID
 */
async function handleGetPlanById(req: Request, planId: string): Promise<Response> {
  // Authentication required
  const authResult = await requireAuth(req);
  if (authResult instanceof Response) return authResult;
  
  const { supabase } = authResult as AuthContext;

  try {
    const { data, error } = await supabase
      .from('module_pricing_plans')
      .select('*')
      .eq('id', planId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return notFoundError('Pricing plan');
      }
      return internalError(`Failed to fetch plan: ${error.message}`);
    }

    return successResponse(data);
  } catch (error: any) {
    return internalError(error.message);
  }
}

/**
 * POST /pricing-plans
 * Create new pricing plan (Service Owner only)
 */
async function handleCreatePlan(req: Request): Promise<Response> {
  // Authentication required
  const authResult = await requireAuth(req);
  if (authResult instanceof Response) return authResult;
  
  const { user, supabase } = authResult as AuthContext;

  // Service Owner only
  const ownerCheck = await requireServiceOwner(supabase, user.id);
  if (ownerCheck instanceof Response) return ownerCheck;

  // Parse and validate body
  const bodyResult = await parseBody(req);
  if (bodyResult instanceof Response) return bodyResult;

  const validation = validate(CreatePricingPlanSchema, bodyResult);
  if (!validation.success) {
    return validationError(formatZodErrors(validation.errors));
  }

  const planData = validation.data;

  try {
    const { data, error } = await supabase
      .from('module_pricing_plans')
      .insert({
        module: planData.module,
        display_name: planData.display_name,
        description: planData.description || null,
        is_global: planData.is_global,
        is_unit_based: planData.is_unit_based,
        price_per_unit: planData.price_per_unit || null,
        min_price: planData.min_price || null,
        price_monthly: planData.price_monthly || null,
        price_yearly: planData.price_yearly || null,
        features: planData.features || [],
        terms_conditions: planData.terms_conditions || null,
        available_from: planData.available_from || null,
        available_until: planData.available_until || null,
        is_active: true,
        created_by: user.id
      })
      .select()
      .single();

    if (error) {
      return internalError(`Failed to create plan: ${error.message}`);
    }

    return successResponse(data, 201);
  } catch (error: any) {
    return internalError(error.message);
  }
}

/**
 * PUT /pricing-plans/:id
 * Update pricing plan (Service Owner only)
 */
async function handleUpdatePlan(req: Request, planId: string): Promise<Response> {
  // Authentication required
  const authResult = await requireAuth(req);
  if (authResult instanceof Response) return authResult;
  
  const { user, supabase } = authResult as AuthContext;

  // Service Owner only
  const ownerCheck = await requireServiceOwner(supabase, user.id);
  if (ownerCheck instanceof Response) return ownerCheck;

  // Parse and validate body
  const bodyResult = await parseBody(req);
  if (bodyResult instanceof Response) return bodyResult;

  const validation = validate(UpdatePricingPlanSchema, bodyResult);
  if (!validation.success) {
    return validationError(formatZodErrors(validation.errors));
  }

  const updates = validation.data;

  try {
    const { data, error } = await supabase
      .from('module_pricing_plans')
      .update(updates)
      .eq('id', planId)
      .select()
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return notFoundError('Pricing plan');
      }
      return internalError(`Failed to update plan: ${error.message}`);
    }

    return successResponse(data);
  } catch (error: any) {
    return internalError(error.message);
  }
}

/**
 * DELETE /pricing-plans/:id
 * Deactivate pricing plan (soft delete)
 */
async function handleDeactivatePlan(req: Request, planId: string): Promise<Response> {
  // Authentication required
  const authResult = await requireAuth(req);
  if (authResult instanceof Response) return authResult;
  
  const { user, supabase } = authResult as AuthContext;

  // Service Owner only
  const ownerCheck = await requireServiceOwner(supabase, user.id);
  if (ownerCheck instanceof Response) return ownerCheck;

  try {
    const { data, error } = await supabase
      .from('module_pricing_plans')
      .update({ is_active: false })
      .eq('id', planId)
      .select()
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return notFoundError('Pricing plan');
      }
      return internalError(`Failed to deactivate plan: ${error.message}`);
    }

    return successResponse({
      message: 'Plan deactivated successfully',
      plan: data
    });
  } catch (error: any) {
    return internalError(error.message);
  }
}
