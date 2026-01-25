import { useState, FormEvent, useEffect } from 'react'
import { useNavigate, Link, useSearchParams } from 'react-router-dom'
import { supabase } from '../lib/supabase'

// Helper function to validate if URL is a valid *.domio.com.pl subdomain
const isValidDomioSubdomain = (url: string): boolean => {
  try {
    const urlObj = new URL(url)
    const hostname = urlObj.hostname
    // Check if hostname ends with .domio.com.pl or is exactly domio.com.pl
    return hostname === 'domio.com.pl' || hostname.endsWith('.domio.com.pl')
  } catch {
    return false
  }
}

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [returnTo, setReturnTo] = useState<string | null>(null)
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()

  // Store returnTo in component state to prevent it from "escaping" during password input
  useEffect(() => {
    const returnToParam = searchParams.get('returnTo')
    if (returnToParam) {
      setReturnTo(returnToParam)
    }
  }, [searchParams])

  // CRITICAL: Check if user is already logged in and redirect accordingly
  // This is the gatekeeper - if user has session and came from Cleaning, redirect back immediately
  useEffect(() => {
    const checkSession = async () => {
      console.log('[SSO DEBUG] LoginPage: Sprawdzanie sesji przy wejściu na stronę logowania...')
      
      try {
        // First, try to get session from cookies
        const { data: { session }, error } = await supabase.auth.getSession()
        
        console.log('[SSO DEBUG] LoginPage: Wynik getSession:', {
          hasSession: !!session,
          userId: session?.user?.id,
          error: error?.message,
        })
        
        // If no session, try to refresh (forces reading from cookie)
        if (!session) {
          console.log('[SSO DEBUG] LoginPage: Sesja pusta, próba odświeżenia z ciastek...')
          const { data: { session: refreshedSession }, error: refreshError } = await supabase.auth.refreshSession()
          
          if (refreshError) {
            console.log('[SSO DEBUG] LoginPage: Błąd odświeżania sesji:', refreshError.message)
          }
          
          if (refreshedSession) {
            console.log('[SSO DEBUG] LoginPage: Sesja odświeżona z ciastek:', refreshedSession.user?.id)
            
            // User has session - check returnTo and redirect
            const returnToParam = searchParams.get('returnTo')
            if (returnToParam && isValidDomioSubdomain(returnToParam)) {
              console.log('[SSO DEBUG] LoginPage: Przekierowanie do returnTo:', returnToParam)
              window.location.replace(returnToParam)
              return
            } else {
              console.log('[SSO DEBUG] LoginPage: Przekierowanie do dashboard (brak returnTo)')
              navigate('/dashboard')
              return
            }
          }
        } else {
          // Session found - check returnTo and redirect immediately
          const returnToParam = searchParams.get('returnTo')
          if (returnToParam && isValidDomioSubdomain(returnToParam)) {
            console.log('[SSO DEBUG] LoginPage: Użytkownik ma sesję, przekierowanie do returnTo:', returnToParam)
            window.location.replace(returnToParam)
            return
          } else {
            console.log('[SSO DEBUG] LoginPage: Użytkownik ma sesję, przekierowanie do dashboard')
            navigate('/dashboard')
            return
          }
        }
      } catch (error) {
        console.error('[SSO DEBUG] LoginPage: Błąd podczas sprawdzania sesji:', error)
      }
    }
    
    checkSession()
  }, [searchParams, navigate])

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

      const { error } = await supabase.auth.signInWithPassword({
        email: emailToUse,
        password,
      })

      if (error) throw error

      // Get returnTo from search params and redirect accordingly
      const returnTo = searchParams.get('returnTo')
      if (returnTo && isValidDomioSubdomain(returnTo)) {
        // Use replace to force full page reload and proper cookie loading in the other subdomain
        window.location.replace(returnTo)
      } else {
        navigate('/dashboard')
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas logowania')
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
