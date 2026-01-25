import { Routes, Route, Navigate } from 'react-router-dom'
import { useEffect, useState } from 'react'
import { supabase } from './lib/supabase'
import LoginPage from './pages/LoginPage'
import SignupPage from './pages/SignupPage'
import DashboardPage from './pages/DashboardPage'
import TermsPage from './pages/TermsPage'
import PrivacyPage from './pages/PrivacyPage'

function App() {
  const [session, setSession] = useState<unknown>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    console.log('[SSO DEBUG] App: Inicjalizacja aplikacji Hub...')
    
    const checkInitialSession = async () => {
      try {
        // Log all cookies for debugging
        console.log('[SSO DEBUG] App: Wszystkie ciastka:', document.cookie)
        
        // Try to get session from cookies
        const { data: { session }, error } = await supabase.auth.getSession()
        
        console.log('[SSO DEBUG] App: Wynik getSession:', {
          hasSession: !!session,
          userId: session?.user?.id,
          error: error?.message,
        })
        
        // If session is empty, try to refresh it (forces reading from cookie)
        if (!session) {
          console.log('[SSO DEBUG] App: Sesja pusta, próba odświeżenia z ciastek...')
          const { data: { session: refreshedSession }, error: refreshError } = await supabase.auth.refreshSession()
          
          if (refreshError) {
            console.log('[SSO DEBUG] App: Błąd odświeżania sesji:', refreshError.message)
          }
          
          if (refreshedSession) {
            console.log('[SSO DEBUG] App: Sesja odświeżona z ciastek:', refreshedSession.user?.id)
            setSession(refreshedSession)
            setLoading(false)
            return
          }
        }
        
        setSession(session)
        setLoading(false)
      } catch (error) {
        console.error('[SSO DEBUG] App: Błąd podczas sprawdzania sesji:', error)
        setLoading(false)
      }
    }

    // Check session immediately
    checkInitialSession()

    // Listen for auth state changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      console.log('[SSO DEBUG] App: Auth state changed:', event, session?.user?.id)
      setSession(session)
    })

    return () => subscription.unsubscribe()
  }, [])

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-lg">Ładowanie...</div>
      </div>
    )
  }

  // CRITICAL: For login route, always render LoginPage - it will handle returnTo redirect logic
  // LoginPage checks if user has session and redirects to returnTo if present
  // This prevents App from auto-redirecting to /dashboard and losing returnTo parameter
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
