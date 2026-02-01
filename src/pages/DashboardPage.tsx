import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import { Application } from '../types/database'

export default function DashboardPage() {
  const [apps, setApps] = useState<Application[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()

  useEffect(() => {
    const loadUserApps = async () => {
      try {
        const {
          data: { user },
        } = await supabase.auth.getUser()

        if (!user) {
          navigate('/login')
          return
        }

        console.log('[SSO DEBUG] User verified:', user.id)

        // Check if returnTo parameter exists (must match LoginPage.tsx which uses 'returnTo')
        const returnTo = searchParams.get('returnTo')
        if (returnTo) {
          console.log('[SSO DEBUG] Redirecting to returnTo:', returnTo)
          window.location.href = returnTo
          return
        }

        // --- Dispatcher: fleet vs cleaning access ---
        // 1. Fetch profile (fleet_role)
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('fleet_role')
          .eq('id', user.id)
          .maybeSingle()

        if (profileError) {
          console.log('[SSO DEBUG] Profile fetch error (fleet_role):', profileError.message)
        }
        const fleetRole = profile?.fleet_role ?? null
        console.log('[SSO DEBUG] fleet_role:', fleetRole ?? '(empty)')

        // 2. Fetch memberships (cleaning system roles)
        const { data: membershipsData, error: membershipsError } = await supabase
          .from('memberships')
          .select('role')
          .eq('user_id', user.id)

        if (membershipsError) {
          console.log('[SSO DEBUG] Memberships fetch error:', membershipsError.message)
        }
        const membershipCount = membershipsData?.length ?? 0
        console.log('[SSO DEBUG] memberships count:', membershipCount, membershipCount ? `(roles: ${membershipsData!.map((m) => m.role).join(', ')})` : '')

        // 3. Dispatcher condition
        const hasFleetAccess = fleetRole === 'admin' || fleetRole === 'driver'
        const hasCleaningAccess = membershipCount > 0
        console.log('[SSO DEBUG] hasFleetAccess:', hasFleetAccess, '| hasCleaningAccess:', hasCleaningAccess)

        if (hasFleetAccess && !hasCleaningAccess) {
          console.log('[SSO DEBUG] Redirecting fleet-only user to flota.domio.com.pl')
          window.location.href = 'https://flota.domio.com.pl'
          return
        }

        console.log('[SSO DEBUG] User has dashboard access, loading applications')

        // 4. Fetch applications (only when not redirected)
        const { data: appsData, error: appsError } = await supabase
          .from('applications')
          .select('*')
          .eq('is_active', true)
          .order('name', { ascending: true })

        if (appsError) throw appsError

        setApps(appsData || [])
      } catch (err) {
        // Ignore AbortError from tab suspension
        if (err instanceof Error && err.name === 'AbortError') {
          console.log('[DashboardPage] Request aborted (tab suspended)')
        } else {
          console.error('Error loading apps:', err)
          setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas ładowania aplikacji')
        }
      } finally {
        setLoading(false)
      }
    }

    loadUserApps()
  }, [navigate, searchParams])

  const handleAppClick = (app: Application) => {
    if (app.domain_url) {
      window.location.href = app.domain_url
    } else if (app.api_url) {
      window.location.href = app.api_url
    }
  }

  const handleLogout = async () => {
    // Optimistic logout: clear local state immediately, redirect to Hub with logout=true, then sign out in background
    // 1. Clear localStorage immediately
    try {
      const keysToRemove: string[] = []
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i)
        if (key && (key.startsWith('sb-') || key.includes('supabase') || key.includes('domio-auth'))) {
          keysToRemove.push(key)
        }
      }
      keysToRemove.forEach((key) => localStorage.removeItem(key))
    } catch (error) {
      console.error('[DashboardPage] Error clearing localStorage:', error)
    }

    // 2. Redirect immediately to Hub (login page) with logout=true parameter
    // Use window.location.href to force full page reload and proper cleanup
    window.location.href = '/login?logout=true'

    // 3. Sign out in background (non-blocking) - will be handled by LoginPage
    supabase.auth.signOut().catch((error) => {
      console.error('[DashboardPage] Error during background signOut:', error)
    })
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Moje aplikacje</h1>
          <button
            onClick={handleLogout}
            disabled={false}
            className="px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-500 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Wyloguj się
          </button>
        </div>

        {loading && (
          <div className="text-center py-12">
            <div className="text-lg">Ładowanie aplikacji...</div>
          </div>
        )}

        {error && (
          <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
            {error}
          </div>
        )}

        {!loading && !error && (
          apps.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-gray-500 text-lg">Brak dostępnych aplikacji</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {apps.map((app) => (
                <div
                  key={app.id}
                  onClick={() => handleAppClick(app)}
                  className="bg-white rounded-lg shadow-md p-6 cursor-pointer hover:shadow-lg transition-shadow"
                >
                  <h2 className="text-xl font-semibold text-gray-900 mb-2">{app.name}</h2>
                  <div className="flex items-center justify-between mt-4">
                    <span className="text-sm text-gray-600">
                      {app.is_free ? 'Darmowa' : 'Płatna'}
                    </span>
                    <svg
                      className="w-5 h-5 text-gray-400"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </div>
                </div>
              ))}
            </div>
          )
        )}
      </div>
    </div>
  )
}
