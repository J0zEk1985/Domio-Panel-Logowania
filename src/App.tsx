import { Routes, Route, Navigate } from 'react-router-dom'
import { useEffect, useState } from 'react'
import type { Session } from '@supabase/supabase-js'
import { supabase } from './lib/supabase'
import LoginPage from './pages/LoginPage'
import SignupPage from './pages/SignupPage'
import DashboardPage from './pages/DashboardPage'
import TermsPage from './pages/TermsPage'
import PrivacyPage from './pages/PrivacyPage'
import ForgotPasswordPage from './pages/ForgotPasswordPage'
import ResetPasswordPage from './pages/ResetPasswordPage'
import ChangePasswordPage from './pages/ChangePasswordPage'

function App() {
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)

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
        window.location.href = '/login?error=no_membership'
        return true
      } catch {
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
          if (currentPath !== '/change-password') {
            window.location.href = '/change-password'
          }
        }
      } catch (error) {
        console.error('[App] Błąd podczas sprawdzania is_first_login:', error)
      }
    }

    let cancelled = false
    let sub: { unsubscribe: () => void } | null = null

    const setupAuth = async () => {
      try {
        const { data } = await supabase.auth.getSession()
        const initialSession = data?.session ?? null
        if (!initialSession) {
          const { error: refreshError } = await supabase.auth.refreshSession()
          if (refreshError) {
            const msg = (refreshError.message ?? '').toLowerCase()
            const isExpiredOrInvalid =
              msg.includes('expired') ||
              (msg.includes('refresh') && msg.includes('invalid')) ||
              (msg.includes('jwt') && msg.includes('expired'))
            if (isExpiredOrInvalid) await supabase.auth.signOut()
            setLoading(false)
          }
        }
      } catch (e) {
        console.error('[App] Błąd inicjalizacji auth:', e)
        setLoading(false)
      }
    }

    void setupAuth().then(() => {
      if (cancelled) return
      const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
        setSession(session)
        setLoading(false)

        if (session?.user?.id && (event === 'SIGNED_IN' || event === 'INITIAL_SESSION')) {
          try {
            if (await checkSimplifiedMembership(session.user.id)) return
            await checkFirstLoginAndRedirect(session.user.id)
          } catch (e) {
            console.error('[App] Błąd w onAuthStateChange:', e)
          }
        }
      })
      sub = subscription
    })

    return () => {
      cancelled = true
      sub?.unsubscribe()
    }
  }, [])

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-lg">Ładowanie...</div>
      </div>
    )
  }

  return (
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
      <Route path="/regulamin" element={<TermsPage />} />
      <Route path="/polityka-prywatnosci" element={<PrivacyPage />} />
      <Route path="/" element={<Navigate to="/login" replace />} />
    </Routes>
  )
}

export default App
