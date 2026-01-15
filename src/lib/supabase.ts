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
 * Custom storage adapter for Supabase that uses cookies with shared domain
 * This allows SSO across subdomains (e.g., domio.com.pl, cleaning.domio.com.pl)
 * Cookie options: domain: '.domio.com.pl', sameSite: 'lax'
 * Identical configuration to Cleaning
 */
const createCookieStorage = () => {
  const isProduction = window.location.hostname.includes('domio.com.pl')
  const useCookies = isProduction

  // Cookie options as specified: domain: '.domio.com.pl', sameSite: 'lax'
  // Identical to Cleaning configuration
  const cookieOptions = {
    domain: '.domio.com.pl',
    sameSite: 'Lax' as const,
    path: '/',
  }

  const getCookie = (name: string): string | null => {
    const value = `; ${document.cookie}`
    const parts = value.split(`; ${name}=`)
    if (parts.length === 2) {
      const cookieValue = parts.pop()?.split(';').shift() || null
      console.log(`[SSO DEBUG] Storage: getCookie(${name}):`, cookieValue ? 'Znaleziono' : 'Brak')
      return cookieValue
    }
    console.log(`[SSO DEBUG] Storage: getCookie(${name}): Brak`)
    return null
  }

  const setCookie = (name: string, value: string, days: number = 7): void => {
    const expires = new Date()
    expires.setTime(expires.getTime() + days * 24 * 60 * 60 * 1000)
    
    if (useCookies) {
      // Production: Use shared domain for SSO with cookieOptions (identical to Cleaning)
      const isSecure = window.location.protocol === 'https:'
      const secureFlag = isSecure ? ';Secure' : ''
      const cookieString = `${name}=${value};expires=${expires.toUTCString()};path=${cookieOptions.path};domain=${cookieOptions.domain};SameSite=${cookieOptions.sameSite}${secureFlag}`
      document.cookie = cookieString
      console.log(`[SSO DEBUG] Storage: setCookie(${name}) - Production mode, domain: ${cookieOptions.domain}`)
    } else {
      // Development: Use regular cookie without domain restriction
      document.cookie = `${name}=${value};expires=${expires.toUTCString()};path=/;SameSite=Lax`
      console.log(`[SSO DEBUG] Storage: setCookie(${name}) - Development mode, no domain restriction`)
    }
  }

  const removeCookie = (name: string): void => {
    if (useCookies) {
      // Production: Remove cookie with shared domain
      const isSecure = window.location.protocol === 'https:'
      const secureFlag = isSecure ? ';Secure' : ''
      document.cookie = `${name}=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=${cookieOptions.path};domain=${cookieOptions.domain};SameSite=${cookieOptions.sameSite}${secureFlag}`
      console.log(`[SSO DEBUG] Storage: removeCookie(${name}) - Production mode`)
    } else {
      // Development: Remove cookie without domain restriction
      document.cookie = `${name}=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/;SameSite=Lax`
      console.log(`[SSO DEBUG] Storage: removeCookie(${name}) - Development mode`)
    }
  }

  if (useCookies) {
    // Use cookies for production (SSO) - identical to Cleaning
    console.log('[SSO DEBUG] Storage: Używanie ciastek dla SSO (Production mode)')
    return {
      getItem: (key: string): string | null => {
        return getCookie(key)
      },
      setItem: (key: string, value: string): void => {
        setCookie(key, value)
      },
      removeItem: (key: string): void => {
        removeCookie(key)
      },
    }
  } else {
    // Fallback to localStorage for local development
    console.log('[SSO DEBUG] Storage: Używanie localStorage (Development mode)')
    return {
      getItem: (key: string): string | null => {
        try {
          return localStorage.getItem(key)
        } catch {
          return null
        }
      },
      setItem: (key: string, value: string): void => {
        try {
          localStorage.setItem(key, value)
        } catch (error) {
          console.error('[SSO DEBUG] Storage: Error setting localStorage:', error)
        }
      },
      removeItem: (key: string): void => {
        try {
          localStorage.removeItem(key)
        } catch (error) {
          console.error('[SSO DEBUG] Storage: Error removing from localStorage:', error)
        }
      },
    }
  }
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
    storage: createCookieStorage(),
  },
  global: {
    headers: {
      'X-Client-Info': 'domio-sso',
    },
  },
})
