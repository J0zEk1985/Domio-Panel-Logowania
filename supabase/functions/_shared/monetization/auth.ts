/**
 * Authentication & Authorization Middleware for Edge Functions
 */

import { createClient, SupabaseClient } from 'npm:@supabase/supabase-js@2';
import { unauthorizedError, forbiddenError } from './responses.ts';

export interface AuthContext {
  user: {
    id: string;
    email?: string;
  };
  supabase: SupabaseClient;
}

/**
 * Extract JWT from Authorization header and verify user
 */
export async function requireAuth(req: Request): Promise<AuthContext | Response> {
  const authHeader = req.headers.get('Authorization');
  
  if (!authHeader) {
    return unauthorizedError('Missing authorization header');
  }

  const token = authHeader.replace('Bearer ', '');
  
  if (!token) {
    return unauthorizedError('Invalid authorization header');
  }

  // Create Supabase client with user's JWT
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  
  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: authHeader
      }
    }
  });

  // Verify user
  const { data: { user }, error } = await supabase.auth.getUser();

  if (error || !user) {
    return unauthorizedError('Invalid or expired token');
  }

  return {
    user: {
      id: user.id,
      email: user.email
    },
    supabase
  };
}

/**
 * Check if user is member of organization
 */
export async function requireOrgMember(
  supabase: SupabaseClient,
  userId: string,
  orgId: string
): Promise<boolean | Response> {
  const { data, error } = await supabase
    .from('memberships')
    .select('id')
    .eq('user_id', userId)
    .eq('org_id', orgId)
    .single();

  if (error || !data) {
    return forbiddenError('You are not a member of this organization');
  }

  return true;
}

/**
 * Check if user is admin/owner of organization
 */
export async function requireOrgAdmin(
  supabase: SupabaseClient,
  userId: string,
  orgId: string
): Promise<boolean | Response> {
  const { data, error } = await supabase
    .from('memberships')
    .select('role')
    .eq('user_id', userId)
    .eq('org_id', orgId)
    .in('role', ['owner', 'wlasciciel', 'admin', 'administrator'])
    .single();

  if (error || !data) {
    return forbiddenError('You must be an admin or owner of this organization');
  }

  return true;
}

/**
 * Check if user is service owner (super admin)
 */
export async function requireServiceOwner(
  supabase: SupabaseClient,
  userId: string
): Promise<boolean | Response> {
  const { data, error } = await supabase
    .from('profiles')
    .select('platform_role')
    .eq('id', userId)
    .maybeSingle();

  if (error || data?.platform_role !== 'admin') {
    return forbiddenError('You must be a platform admin to perform this action');
  }

  return true;
}

/**
 * Extract and validate query parameters
 */
export function getQueryParam(req: Request, param: string): string | null {
  const url = new URL(req.url);
  return url.searchParams.get(param);
}

/**
 * Extract and validate required query parameter
 */
export function requireQueryParam(req: Request, param: string): string | Response {
  const value = getQueryParam(req, param);
  
  if (!value) {
    return new Response(
      JSON.stringify({
        success: false,
        error: {
          code: 'MISSING_PARAM',
          message: `Missing required query parameter: ${param}`
        }
      }),
      {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }

  return value;
}

/**
 * Parse and validate JSON body
 */
export async function parseBody<T = any>(req: Request): Promise<T | Response> {
  try {
    const body = await req.json();
    return body as T;
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: {
          code: 'INVALID_JSON',
          message: 'Invalid JSON in request body'
        }
      }),
      {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
}
