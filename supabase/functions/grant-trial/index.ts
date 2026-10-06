/**
 * Grant Trial API
 * 
 * POST /grant-trial
 * Grant trial access to a module (Service Owner only)
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';
import {
  successResponse,
  errorResponse,
  validationError,
  internalError,
  methodNotAllowedError,
  corsPreflightResponse
} from '../_shared/monetization/responses.ts';
import {
  requireAuth,
  requireServiceOwner,
  parseBody,
  type AuthContext
} from '../_shared/monetization/auth.ts';
import {
  GrantTrialSchema,
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
    return await handleGrantTrial(req);
  } catch (error: any) {
    console.error('Error in grant-trial function:', error);
    return internalError(error.message);
  }
});

/**
 * POST /grant-trial
 * Grant trial access to a module
 */
async function handleGrantTrial(req: Request): Promise<Response> {
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

  const validation = validate(GrantTrialSchema, bodyResult);
  if (!validation.success) {
    return validationError(formatZodErrors(validation.errors));
  }

  const { org_id, community_id, module, duration_days, reason } = validation.data;

  try {
    // Check if trial already exists
    let existingQuery = supabase
      .from('module_access_grants')
      .select('*')
      .eq('org_id', org_id)
      .eq('module', module)
      .eq('is_granted', true)
      .eq('is_manual_grant', true)
      .is('revoked_at', null);

    if (community_id) {
      existingQuery = existingQuery.eq('community_id', community_id);
    } else {
      existingQuery = existingQuery.is('community_id', null);
    }

    const { data: existing } = await existingQuery.single();

    if (existing) {
      return errorResponse(
        'TRIAL_EXISTS',
        'An active trial or manual grant already exists for this org/module',
        409
      );
    }

    // Calculate expiry date
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + duration_days);

    // Create manual grant (trial)
    const { data: grant, error: grantError } = await supabase
      .from('module_access_grants')
      .insert({
        org_id,
        community_id: community_id || null,
        module,
        is_granted: true,
        granted_by_subscription_id: null,
        is_manual_grant: true,
        manual_grant_reason: reason || `Trial period: ${duration_days} days`,
        manual_granted_by: user.id,
        granted_at: new Date().toISOString(),
        expires_at: expiresAt.toISOString()
      })
      .select()
      .single();

    if (grantError) {
      return internalError(`Failed to grant trial: ${grantError.message}`);
    }

    return successResponse({
      grant,
      trial_details: {
        org_id,
        community_id: community_id || null,
        module,
        duration_days,
        expires_at: expiresAt.toISOString(),
        granted_by: user.id
      },
      message: `Trial dostępu do modułu ${module} został przyznany na ${duration_days} dni`
    }, 201);
  } catch (error: any) {
    return internalError(error.message);
  }
}
