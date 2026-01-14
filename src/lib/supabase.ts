import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables')
}

// Custom storage adapter for shared cookies on parent domain
const cookieStorage = {
  getItem: (key: string): string | null => {
    if (typeof document === 'undefined') return null
    const cookies = document.cookie.split('; ')
    const cookie = cookies.find((c) => c.trim().startsWith(`${key}=`))
    if (cookie) {
      return decodeURIComponent(cookie.split('=').slice(1).join('='))
    }
    return null
  },
  setItem: (key: string, value: string): void => {
    if (typeof document === 'undefined') return
    const maxAge = 31536000 // 1 year
    document.cookie = `${key}=${encodeURIComponent(value)}; domain=.domio.com.pl; path=/; max-age=${maxAge}; sameSite=lax; secure`
  },
  removeItem: (key: string): void => {
    if (typeof document === 'undefined') return
    document.cookie = `${key}=; domain=.domio.com.pl; path=/; max-age=0; sameSite=lax`
  },
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    storage: typeof window !== 'undefined' ? cookieStorage : undefined,
    flowType: 'pkce',
    cookieOptions: {
      domain: '.domio.com.pl',
      path: '/',
      sameSite: 'lax',
      secure: true,
      maxAge: 31536000, // 1 year
    },
  },
  global: {
    headers: {
      'X-Client-Info': 'domio-sso',
    },
  },
})
