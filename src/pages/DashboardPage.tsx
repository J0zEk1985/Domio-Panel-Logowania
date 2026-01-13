import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import { UserAppAccess } from '../types/database'

export default function DashboardPage() {
  const [apps, setApps] = useState<UserAppAccess[]>([])
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

        // Check if return_to parameter exists
        const returnTo = searchParams.get('return_to')
        if (returnTo) {
          window.location.href = returnTo
          return
        }

        // Fetch user's accessible applications
        // Note: This assumes a user_app_access view exists in the database
        // If the view doesn't exist, you'll need to create it or use a different query
        // For now, I'll use a query that joins the necessary tables
        const { data: appsData, error: appsError } = await supabase
          .from('user_app_access')
          .select('*')
          .eq('user_id', user.id)

        if (appsError) {
          // If the view doesn't exist, try alternative query structure
          console.error('Error fetching apps:', appsError)
          
          // Fallback: Query applications directly (this is a simplified version)
          // In production, you should use the user_app_access view
          const { data: allApps, error: allAppsError } = await supabase
            .from('applications')
            .select('*')
            .eq('is_active', true)

          if (allAppsError) throw allAppsError

          // Transform to match UserAppAccess interface (simplified)
          setApps(
            (allApps || []).map((app) => ({
              user_id: user.id,
              app_id: app.id,
              app_name: app.name,
              app_domain_url: app.domain_url,
              app_api_url: app.api_url,
              org_id: '',
              org_name: '',
              subscription_status: 'active',
            }))
          )
        } else {
          setApps(appsData || [])
        }
      } catch (err) {
        console.error('Error loading apps:', err)
        setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas ładowania aplikacji')
      } finally {
        setLoading(false)
      }
    }

    loadUserApps()
  }, [navigate, searchParams])

  const handleAppClick = (app: UserAppAccess) => {
    if (app.app_domain_url) {
      window.location.href = app.app_domain_url
    } else if (app.app_api_url) {
      window.location.href = app.app_api_url
    }
  }

  const handleLogout = async () => {
    await supabase.auth.signOut()
    navigate('/login')
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-lg">Ładowanie aplikacji...</div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-red-600">{error}</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Moje aplikacje</h1>
          <button
            onClick={handleLogout}
            className="px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-500"
          >
            Wyloguj się
          </button>
        </div>

        {apps.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-500 text-lg">Brak dostępnych aplikacji</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {apps.map((app) => (
              <div
                key={app.app_id}
                onClick={() => handleAppClick(app)}
                className="bg-white rounded-lg shadow-md p-6 cursor-pointer hover:shadow-lg transition-shadow"
              >
                <h2 className="text-xl font-semibold text-gray-900 mb-2">{app.app_name}</h2>
                {app.org_name && (
                  <p className="text-sm text-gray-500 mb-4">Organizacja: {app.org_name}</p>
                )}
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">Status: {app.subscription_status}</span>
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
        )}
      </div>
    </div>
  )
}
