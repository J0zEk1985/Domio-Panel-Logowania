/**
 * ModuleAccessGate
 * 
 * Route guard component for checking module access
 * Blocks access if user doesn't have active subscription
 */

import { useEffect, useState, type ReactNode } from 'react'
import { Navigate } from 'react-router-dom'
import { Lock, AlertTriangle } from 'lucide-react'
import { supabase } from '../lib/supabase'
import { monetizationApi } from '../hooks/useMonetization'
import type { AppModule } from '../types/monetization'
import { MODULE_DISPLAY_NAMES } from '../types/monetization'

interface Props {
  module: AppModule
  communityId?: string
  children: ReactNode
  fallbackPath?: string
  showBlockedMessage?: boolean
}

export default function ModuleAccessGate({
  module,
  communityId,
  children,
  fallbackPath = '/dashboard',
  showBlockedMessage = true,
}: Props) {
  const [checking, setChecking] = useState(true)
  const [hasAccess, setHasAccess] = useState<boolean | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const checkAccess = async () => {
      setChecking(true)
      setError(null)

      try {
        // Get user's organization
        const {
          data: { user },
        } = await supabase.auth.getUser()
        if (!user) {
          setHasAccess(false)
          setChecking(false)
          return
        }

        const { data: memberships } = await supabase
          .from('memberships')
          .select('organization_id')
          .eq('user_id', user.id)
          .limit(1)
          .single()

        if (!memberships?.organization_id) {
          setHasAccess(false)
          setChecking(false)
          return
        }

        // Check module access
        const result = await monetizationApi.checkAccess({
          org_id: memberships.organization_id,
          community_id: communityId,
          module,
        })

        if (result.error) {
          setError(result.error)
          setHasAccess(false)
        } else {
          setHasAccess(result.data?.has_access ?? false)
        }
      } catch (err) {
        console.error('[ModuleAccessGate] check access error:', err)
        setError('Wystąpił błąd podczas sprawdzania dostępu')
        setHasAccess(false)
      } finally {
        setChecking(false)
      }
    }

    void checkAccess()
  }, [module, communityId])

  if (checking) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center space-y-4">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto" />
          <p className="text-muted-foreground">Sprawdzanie dostępu...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-screen p-4">
        <div className="bento-card p-8 max-w-md text-center space-y-4">
          <AlertTriangle className="h-12 w-12 text-destructive mx-auto" />
          <h2 className="text-xl font-semibold">Błąd weryfikacji dostępu</h2>
          <p className="text-muted-foreground">{error}</p>
          <a
            href={fallbackPath}
            className="inline-block px-4 py-2 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:opacity-90"
          >
            Powrót do panelu
          </a>
        </div>
      </div>
    )
  }

  if (!hasAccess) {
    if (!showBlockedMessage) {
      return <Navigate to={fallbackPath} replace />
    }

    return (
      <div className="flex items-center justify-center min-h-screen p-4">
        <div className="bento-card p-8 max-w-md text-center space-y-4">
          <Lock className="h-12 w-12 text-amber-600 mx-auto" />
          <h2 className="text-xl font-semibold">Brak dostępu do modułu</h2>
          <p className="text-muted-foreground">
            Nie masz aktywnej subskrypcji modułu <strong>{MODULE_DISPLAY_NAMES[module]}</strong>.
          </p>
          <p className="text-sm text-muted-foreground">
            Aby uzyskać dostęp, zakup subskrypcję w sklepie lub skontaktuj się z administratorem organizacji.
          </p>
          <div className="flex gap-3 justify-center">
            <a
              href="/subscriptions/store"
              className="px-4 py-2 bg-primary text-primary-foreground rounded-md text-sm font-medium hover:opacity-90"
            >
              Przejdź do sklepu
            </a>
            <a
              href={fallbackPath}
              className="px-4 py-2 border border-border rounded-md text-sm hover:bg-muted"
            >
              Powrót do panelu
            </a>
          </div>
        </div>
      </div>
    )
  }

  return <>{children}</>
}
