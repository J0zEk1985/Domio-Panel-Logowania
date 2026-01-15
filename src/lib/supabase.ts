/**
 * Supabase Client Configuration
 * Configured identically to Cleaning for SSO session sharing
 * Uses cookieOptions with domain: '.domio.com.pl' to share session with Cleaning
 */

import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL
const SUPABASE_PUBLISHABLE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!SUPABASE_URL || !SUPABASE_PUBLISHABLE_KEY) {
  throw new Error('Missing Supabase environment variables')
}

/**
 * Supabase client configured identically to Cleaning
 * Uses cookieOptions with domain: '.domio.com.pl', sameSite: 'lax' to share session
 * Uses storageKey: 'domio-auth-token' - MUST be identical in both apps (Hub and Cleaning)
 * 
 * This configuration enables the app to create session cookies that can be read
 * by Cleaning app on subdomain (cleaning.domio.com.pl) for SSO.
 */
export const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: {
    // CRITICAL: storageKey must be identical to Cleaning for SSO to work
    storageKey: 'domio-auth-token',
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    flowType: 'pkce',
    // @ts-ignore - cookieOptions is not in TypeScript definitions but is supported by Supabase
    cookieOptions: {
      domain: '.domio.com.pl',
      path: '/',
      sameSite: 'lax',
      secure: true,
    },
  },
  global: {
    headers: {
      'X-Client-Info': 'domio-sso',
    },
  },
})
