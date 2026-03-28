import { useEffect, useState, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '../lib/supabase'

type ProtectedRouteProps = {
  children: ReactNode
  /** When true, only users with profiles.platform_role === 'admin' may access the route. */
  requireAdmin?: boolean
}

export default function ProtectedRoute({ children, requireAdmin = false }: ProtectedRouteProps) {
  const navigate = useNavigate()
  const [phase, setPhase] = useState<'loading' | 'allowed' | 'denied'>('loading')

  useEffect(() => {
    let cancelled = false

    const run = async () => {
      try {
        const {
          data: { session },
        } = await supabase.auth.getSession()

        if (!session?.user?.id) {
          if (!cancelled) {
            navigate('/login?returnTo=/admin', { replace: true })
            setPhase('denied')
          }
          return
        }

        if (!requireAdmin) {
          if (!cancelled) setPhase('allowed')
          return
        }

        const { data: profile, error } = await supabase
          .from('profiles')
          .select('platform_role')
          .eq('id', session.user.id)
          .maybeSingle()

        if (error) {
          console.error('[ProtectedRoute] Failed to load profile for admin check:', error)
        }

        const role = (profile?.platform_role ?? '').toString().trim().toLowerCase()
        if (role !== 'admin') {
          if (!cancelled) {
            navigate('/dashboard', { replace: true, state: { noAdminAccess: true } })
            setPhase('denied')
          }
          return
        }

        if (!cancelled) setPhase('allowed')
      } catch (e) {
        console.error('[ProtectedRoute] Unexpected error:', e)
        if (!cancelled) {
          navigate('/dashboard', { replace: true, state: { noAdminAccess: true } })
          setPhase('denied')
        }
      }
    }

    void run()
    return () => {
      cancelled = true
    }
  }, [navigate, requireAdmin])

  if (phase === 'loading') {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-lg">Ładowanie...</div>
      </div>
    )
  }

  if (phase === 'allowed') {
    return <>{children}</>
  }

  return null
}
