import { Routes, Route, Navigate, useLocation } from 'react-router-dom'
import { useEffect, useState } from 'react'
import type { Session } from '@supabase/supabase-js'
import { Toaster } from 'sonner'
import { supabase } from './lib/supabase'
import LoginPage from './pages/LoginPage'
import SignupPage from './pages/SignupPage'
import DashboardPage from './pages/DashboardPage'
import TermsPage from './pages/TermsPage'
import PrivacyPage from './pages/PrivacyPage'
import ForgotPasswordPage from './pages/ForgotPasswordPage'
import ResetPasswordPage from './pages/ResetPasswordPage'
import ChangePasswordPage from './pages/ChangePasswordPage'
import LandingPage from './pages/LandingPage'
import ModuleDetail from './pages/ModuleDetail'
import AdminPage from './pages/AdminPage'
import ProtectedRoute from './components/ProtectedRoute'

/** Paths where we never force redirect to /login after auth edge cases (e.g. simplified account without org). */
const PUBLIC_PATHS = new Set([
  '/',
  '/login',
  '/signup',
  '/forgot-password',
  '/reset-password',
  '/regulamin',
  '/polityka-prywatnosci',
])

function isPublicPath(pathname: string): boolean {
  if (pathname.startsWith('/module/')) return true
  return PUBLIC_PATHS.has(pathname)
}

function App() {
  const location = useLocation()
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)

  const currentPath = location.pathname
  const isPublic = isPublicPath(currentPath)

  useEffect(() => {
    /** Simplified users must have at least one membership; otherwise signOut and redirect to login. */
    const checkSimplifiedMembership = async (userId: string): Promise<boolean> => {
      try {
        const { data: profile } = await supabase
          .from('profiles')
          .select('account_type')
          .eq('id', userId)
          .maybeSingle()
        const accountType = (profile?.account_type ?? '').toString().toLowerCase()
        if (accountType !== 'simplified') return false
        const { data: rows } = await supabase
          .from('memberships')
          .select('id')
          .eq('user_id', userId)
        if (rows && rows.length > 0) return false
        await supabase.auth.signOut()
        const path = window.location.pathname
        if (!isPublicPath(path)) {
          window.location.href = '/login?error=no_membership'
        }
        return true
      } catch (error) {
        // Ignore AbortError from tab suspension
        if (error instanceof Error && error.name === 'AbortError') {
          console.log('[App] Membership check aborted (tab suspended)')
        }
        return false
      }
    }

    const checkFirstLoginAndRedirect = async (userId: string) => {
      try {
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('is_first_login')
          .eq('id', userId)
          .single()

        if (profileError) {
          console.error('[App] Błąd pobierania profilu:', profileError)
          return
        }

        if (profile?.is_first_login === true) {
          const currentPath = window.location.pathname
          // Landing at `/` always stays visible; DashboardPage enforces password change when entering the panel.
          if (currentPath !== '/change-password' && currentPath !== '/') {
            window.location.href = '/change-password'
          }
        }
      } catch (error) {
        // Ignore AbortError from tab suspension
        if (error instanceof Error && error.name === 'AbortError') {
          console.log('[App] First login check aborted (tab suspended)')
        } else {
          console.error('[App] Błąd podczas sprawdzania is_first_login:', error)
        }
      }
    }

    let cancelled = false
    let sub: { unsubscribe: () => void } | null = null

    const setupAuth = async () => {
      try {
        const { data } = await supabase.auth.getSession()
        const initialSession = data?.session ?? null
        setSession(initialSession)
        if (!initialSession) {
          const { error: refreshError } = await supabase.auth.refreshSession()
          if (refreshError) {
            const msg = (refreshError.message ?? '').toLowerCase()
            const isExpiredOrInvalid =
              msg.includes('expired') ||
              (msg.includes('refresh') && msg.includes('invalid')) ||
              (msg.includes('jwt') && msg.includes('expired'))
            if (isExpiredOrInvalid) await supabase.auth.signOut()
          }
        }
      } catch (e) {
        // Ignore AbortError from tab suspension
        if (e instanceof Error && e.name === 'AbortError') {
          console.log('[App] Request aborted (tab suspended)')
        } else {
          console.error('[App] Błąd inicjalizacji auth:', e)
        }
      } finally {
        // Always clear initial gate so UI never stays stuck (tab wake / slow INITIAL_SESSION)
        setLoading(false)
      }
    }

    /** Wake from suspended tab: refresh session client without blocking the main thread. */
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible') {
        void supabase.auth.getSession()
      }
    }
    document.addEventListener('visibilitychange', handleVisibilityChange)

    void setupAuth().then(() => {
      if (cancelled) return
      const {
        data: { subscription },
      } = supabase.auth.onAuthStateChange((event, session) => {
        // TOKEN_REFRESHED, USER_UPDATED, INITIAL_SESSION, SIGNED_IN, SIGNED_OUT, etc. — always sync React
        setSession(session)
        setLoading(false)

        if (event === 'SIGNED_OUT' || !session?.user?.id) {
          return
        }

        void (async () => {
          if (event !== 'SIGNED_IN' && event !== 'INITIAL_SESSION') {
            return
          }
          try {
            if (await checkSimplifiedMembership(session.user.id)) return
            await checkFirstLoginAndRedirect(session.user.id)
          } catch (e) {
            console.error('[App] Błąd w onAuthStateChange:', e)
          }
        })()
      })
      sub = subscription
    })

    return () => {
      cancelled = true
      sub?.unsubscribe()
      document.removeEventListener('visibilitychange', handleVisibilityChange)
    }
  }, [])

  // Global loading only for protected routes — public pages render immediately while auth resolves in background
  if (loading && !isPublic) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-lg">Ładowanie...</div>
      </div>
    )
  }

  return (
    <>
      <Toaster position="top-center" richColors closeButton />
    <Routes>
      <Route
        path="/login"
        element={<LoginPage />}
      />
      <Route
        path="/signup"
        element={session ? <Navigate to="/dashboard" replace /> : <SignupPage />}
      />
      <Route
        path="/forgot-password"
        element={<ForgotPasswordPage />}
      />
      <Route
        path="/reset-password"
        element={<ResetPasswordPage />}
      />
      <Route
        path="/change-password"
        element={session ? <ChangePasswordPage /> : <Navigate to="/login" replace />}
      />
      <Route
        path="/dashboard"
        element={session ? <DashboardPage /> : <Navigate to="/login" replace />}
      />
      <Route
        path="/admin"
        element={
          <ProtectedRoute requireAdmin={true}>
            <AdminPage />
          </ProtectedRoute>
        }
      />
      <Route path="/regulamin" element={<TermsPage />} />
      <Route path="/polityka-prywatnosci" element={<PrivacyPage />} />
      <Route path="/module/:slug" element={<ModuleDetail />} />
      <Route path="/" element={<LandingPage />} />
    </Routes>
    </>
  )
}

export default App
