import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    storageKey: 'domio-auth-token',
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    flowType: 'pkce',
    // @ts-ignore
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
