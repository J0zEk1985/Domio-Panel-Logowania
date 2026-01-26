import { useState, FormEvent, useEffect, useRef } from 'react'
import { useNavigate, Link, useSearchParams } from 'react-router-dom'
import { supabase } from '../lib/supabase'

const isValidDomioSubdomain = (url: string): boolean => {
  try {
    const urlObj = new URL(url)
    const hostname = urlObj.hostname
    return hostname === 'domio.com.pl' || hostname.endsWith('.domio.com.pl')
  } catch {
    return false
  }
}

/**
 * Hard reset function - completely clears session, cookies, and localStorage
 * Used when 403 error occurs or logout=true parameter is detected
 */
const performHardReset = async (): Promise<void> => {
  try {
    // Sign out from Supabase (local scope only)
    await supabase.auth.signOut({ scope: 'local' })
  } catch (error) {
    console.error('[LoginPage] Error during signOut:', error)
  }

  try {
    // Manually remove cookies from parent domain (Supabase library sometimes lacks permissions)
    const cookiesToRemove = [
      'sb-access-token',
      'sb-refresh-token',
      'domio-auth-token',
    ]
    
    cookiesToRemove.forEach((cookieName) => {
      // Remove from parent domain
      document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=.domio.com.pl;`
      // Remove from current domain
      document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`
    })
  } catch (error) {
    console.error('[LoginPage] Error removing cookies:', error)
  }

  try {
    // Clear localStorage under session key
    localStorage.removeItem('domio-auth-token')
    // Clear all Supabase-related keys
    const keysToRemove: string[] = []
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i)
      if (key && (key.startsWith('sb-') || key.includes('supabase') || key.includes('domio-auth'))) {
        keysToRemove.push(key)
      }
    }
    keysToRemove.forEach((key) => localStorage.removeItem(key))
  } catch (error) {
    console.error('[LoginPage] Error clearing localStorage:', error)
  }
}

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [isChecking, setIsChecking] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [returnTo, setReturnTo] = useState<string | null>(null)
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const lastRedirectedUserIdRef = useRef<string | null>(null)
  const hasCheckedRef = useRef(false)

  useEffect(() => {
    const returnToParam = searchParams.get('returnTo')
    if (returnToParam) setReturnTo(returnToParam)
    if (searchParams.get('error') === 'no_membership') {
      setError('Brak uprawnień do tej firmy.')
    }
  }, [searchParams])

  // Session verification using getUser() - server-side token validation
  useEffect(() => {
    if (hasCheckedRef.current) return
    hasCheckedRef.current = true

    const verifySession = async () => {
      try {
        setIsChecking(true)
        setError(null)

        // Check if logout parameter is present - perform hard reset first
        const logoutParam = searchParams.get('logout')
        if (logoutParam === 'true') {
          await performHardReset()
          // Remove logout parameter from URL
          const newSearchParams = new URLSearchParams(searchParams)
          newSearchParams.delete('logout')
          const newSearch = newSearchParams.toString()
          const newUrl = newSearch ? `?${newSearch}` : window.location.pathname
          window.history.replaceState({}, '', newUrl)
        }

        // Use getUser() to force server-side token validation
        const { data: userData, error: userError } = await supabase.auth.getUser()

        // Handle 403 Forbidden or any error
        if (userError || !userData?.user) {
          // If error status is 403 or token is invalid, perform hard reset
          const is403 = userError?.status === 403 || userError?.message?.toLowerCase().includes('forbidden')
          const isInvalidToken = userError?.message?.toLowerCase().includes('jwt') || 
                                 userError?.message?.toLowerCase().includes('token') ||
                                 userError?.message?.toLowerCase().includes('expired')

          if (is403 || isInvalidToken) {
            await performHardReset()
          }
          
          // Stop checking and show login form
          setIsChecking(false)
          return
        }

        // User is authenticated - check if we should redirect
        const userId = userData.user.id
        if (userId && lastRedirectedUserIdRef.current !== userId) {
          const returnToParam = searchParams.get('returnTo') || returnTo
          const target = returnToParam && isValidDomioSubdomain(returnToParam)
            ? returnToParam
            : '/dashboard'

          lastRedirectedUserIdRef.current = userId
          
          if (target.startsWith('http')) {
            window.location.replace(target)
          } else {
            navigate(target, { replace: true })
          }
        } else {
          setIsChecking(false)
        }
      } catch (error) {
        // Ignore AbortError from tab suspension
        if (error instanceof Error && error.name === 'AbortError') {
          console.log('[LoginPage] Session verification aborted (tab suspended)')
          setIsChecking(false)
          return
        }
        console.error('[LoginPage] Error during session verification:', error)
        // On any error, perform hard reset and show login form
        await performHardReset()
        setIsChecking(false)
      } finally {
        // Ensure isChecking is set to false if we're not redirecting
        // This will be handled by the redirect or error cases above
      }
    }

    void verifySession()
  }, [searchParams, returnTo, navigate])

  const handleEmailLogin = async (e: FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    try {
      // If input doesn't contain @, treat it as staff identifier and append @staff.domio.com.pl
      let emailToUse = email.trim()
      if (!emailToUse.includes('@')) {
        emailToUse = `${emailToUse}@staff.domio.com.pl`
      }

      const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
        email: emailToUse,
        password,
      })

      if (signInError) throw signInError

      const userId = signInData.session?.user?.id
      if (!userId) {
        setError('Wystąpił błąd podczas logowania.')
        return
      }

      const targetOrgId = searchParams.get('orgId') ?? null
      const { data: profile } = await supabase
        .from('profiles')
        .select('account_type')
        .eq('id', userId)
        .maybeSingle()
      const accountType = (profile?.account_type ?? '').toString().toLowerCase()
      if (accountType === 'simplified') {
        const { data: membershipRows } = await supabase
          .from('memberships')
          .select('id, org_id')
          .eq('user_id', userId)
        if (!membershipRows || membershipRows.length === 0) {
          await supabase.auth.signOut()
          setError('Brak uprawnień do tej firmy.')
          return
        }
        if (targetOrgId) {
          const hasOrg = membershipRows.some((r) => r.org_id === targetOrgId)
          if (!hasOrg) {
            await supabase.auth.signOut()
            setError('Brak uprawnień do tej firmy.')
            return
          }
        }
      }

      // Get returnTo from search params and redirect accordingly
      const returnTo = searchParams.get('returnTo')
      if (returnTo && isValidDomioSubdomain(returnTo)) {
        // Use replace to force full page reload and proper cookie loading in the other subdomain
        window.location.replace(returnTo)
      } else {
        navigate('/dashboard')
      }
    } catch (err: unknown) {
      // Translate Supabase errors to Polish messages
      let errorMessage = 'Wystąpił nieoczekiwany błąd podczas logowania.'
      
      if (err && typeof err === 'object') {
        // Handle rate limit error (429)
        if ('status' in err && err.status === 429) {
          errorMessage = 'Zbyt wiele prób logowania. Spróbuj ponownie za chwilę.'
        } else if ('message' in err && typeof err.message === 'string') {
          const errorMsg = err.message.toLowerCase()
          
          // Invalid login credentials
          if (errorMsg.includes('invalid login credentials') || 
              errorMsg.includes('invalid credentials') ||
              errorMsg.includes('email') && errorMsg.includes('password')) {
            errorMessage = 'Nieprawidłowy e-mail/login lub hasło.'
          }
          // Email not confirmed
          else if (errorMsg.includes('email not confirmed') || 
                   errorMsg.includes('email_not_confirmed') ||
                   errorMsg.includes('email address not confirmed')) {
            errorMessage = 'Adres e-mail nie został jeszcze potwierdzony.'
          }
          // Too many requests (alternative check)
          else if (errorMsg.includes('too many requests') || 
                   errorMsg.includes('rate limit')) {
            errorMessage = 'Zbyt wiele prób logowania. Spróbuj ponownie za chwilę.'
          }
        }
      }
      
      setError(errorMessage)
    } finally {
      setLoading(false)
    }
  }

  const handleGoogleLogin = async () => {
    setLoading(true)
    setError(null)

    try {
      const finalRedirectTo = returnTo && isValidDomioSubdomain(returnTo)
        ? returnTo
        : `${window.location.origin}/dashboard`

      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: finalRedirectTo,
        },
      })

      if (error) throw error
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas logowania przez Google')
      setLoading(false)
    }
  }

  const handleFacebookLogin = async () => {
    setLoading(true)
    setError(null)

    try {
      const finalRedirectTo = returnTo && isValidDomioSubdomain(returnTo)
        ? returnTo
        : `${window.location.origin}/dashboard`

      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'facebook',
        options: {
          redirectTo: finalRedirectTo,
        },
      })

      if (error) throw error
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas logowania przez Facebook')
      setLoading(false)
    }
  }

  // Show loading state during session verification
  if (isChecking) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white px-4">
        <div className="w-full max-w-md">
          <div className="bg-white rounded-lg shadow-lg p-8 text-center">
            <div className="mb-4">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
            </div>
            <p className="text-gray-600">Weryfikacja sesji...</p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-white px-4">
      <div className="w-full max-w-md">
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Witaj ponownie</h1>
          <p className="text-gray-600 mb-8">Zaloguj się, aby uzyskać dostęp do swoich aplikacji</p>

          <form onSubmit={handleEmailLogin} className="space-y-6">
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                Email / Login
              </label>
              <input
                id="email"
                type="text"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="nazwa@przykład.pl lub Twój ID"
                required
                className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                Hasło
              </label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                required
                className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <div className="mt-2 text-right">
                <Link
                  to={returnTo ? `/forgot-password?returnTo=${encodeURIComponent(returnTo)}` : '/forgot-password'}
                  className="text-sm text-blue-600 hover:text-blue-800 font-medium"
                >
                  Zapomniałeś hasła?
                </Link>
              </div>
            </div>

            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-gray-800 text-white py-2 px-4 rounded-md hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Logowanie...' : 'Zaloguj się'}
            </button>
          </form>

          <div className="my-6 flex items-center">
            <div className="flex-1 border-t border-gray-300"></div>
            <span className="px-4 text-sm text-gray-500">LUB</span>
            <div className="flex-1 border-t border-gray-300"></div>
          </div>

          <div className="space-y-3">
            <button
              onClick={handleGoogleLogin}
              disabled={loading}
              className="w-full flex items-center justify-center gap-3 bg-white border border-gray-300 text-gray-700 py-2 px-4 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <svg className="w-5 h-5" viewBox="0 0 24 24">
                <path
                  fill="#4285F4"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                />
                <path
                  fill="#34A853"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                />
                <path
                  fill="#EA4335"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                />
              </svg>
              Zaloguj przez Google
            </button>

            <button
              onClick={handleFacebookLogin}
              disabled={loading}
              className="w-full flex items-center justify-center gap-3 bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24">
                <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
              </svg>
              Zaloguj przez Facebook
            </button>
          </div>

          <p className="mt-6 text-center text-sm text-gray-600">
            Nie masz konta?{' '}
            <Link
              to={returnTo ? `/signup?returnTo=${encodeURIComponent(returnTo)}` : '/signup'}
              className="text-blue-600 hover:text-blue-800 font-medium"
            >
              Zarejestruj się
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}
