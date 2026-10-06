/**
 * Check Access API
 * 
 * POST /check-access
 * Fast access check for module availability
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
  parseBody,
  type AuthContext
} from '../_shared/monetization/auth.ts';
import {
  CheckAccessSchema,
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
    return await handleCheckAccess(req);
  } catch (error: any) {
    console.error('Error in check-access function:', error);
    return internalError(error.message);
  }
});

/**
 * POST /check-access
 * Check if org/community has access to a module
 */
async function handleCheckAccess(req: Request): Promise<Response> {
  // Authentication required
  const authResult = await requireAuth(req);
  if (authResult instanceof Response) return authResult;
  
  const { supabase } = authResult as AuthContext;

  // Parse and validate body
  const bodyResult = await parseBody(req);
  if (bodyResult instanceof Response) return bodyResult;

  const validation = validate(CheckAccessSchema, bodyResult);
  if (!validation.success) {
    return validationError(formatZodErrors(validation.errors));
  }

  const { org_id, community_id, module } = validation.data;

  try {
    // Use database function for access check
    const { data: hasAccess, error: accessError } = await supabase
      .rpc('has_module_access', {
        p_org_id: org_id,
        p_community_id: community_id || null,
        p_module: module
      });

    if (accessError) {
      return internalError(`Failed to check access: ${accessError.message}`);
    }

    // If has access, get grant details
    let grant = null;
    if (hasAccess) {
      let query = supabase
        .from('module_access_grants')
        .select('*')
        .eq('org_id', org_id)
        .eq('module', module)
        .eq('is_granted', true)
        .is('revoked_at', null);

      if (community_id) {
        query = query.eq('community_id', community_id);
      } else {
        query = query.is('community_id', null);
      }

      const { data: grantData } = await query.single();
      grant = grantData;
    }

    return successResponse({
      has_access: hasAccess,
      org_id,
      community_id: community_id || null,
      module,
      grant,
      message: hasAccess 
        ? 'Dostęp przyznany' 
        : 'Brak dostępu - wymagana aktywna subskrypcja'
    });
  } catch (error: any) {
    return internalError(error.message);
  }
}
