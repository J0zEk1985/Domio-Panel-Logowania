import { useEffect, useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { LayoutDashboard, Building2, Menu, Shield, X } from 'lucide-react'
import { ThemeToggle } from './ThemeToggle'
import domioLogo from '../../../lovable-design/src/assets/domio-logo.jpg'
import { supabase } from '../../lib/supabase'

const ctaDesktopClass =
  'gradient-brand text-primary-foreground border-0 rounded-md px-4 py-2 text-sm font-medium inline-flex items-center justify-center disabled:opacity-60 disabled:pointer-events-none'
const ctaMobileClass =
  'block w-full rounded-md px-4 py-2 text-center font-medium gradient-brand text-primary-foreground disabled:opacity-60 disabled:pointer-events-none'

async function loadPlatformAdmin(userId: string | undefined): Promise<boolean> {
  if (!userId) return false
  const { data, error } = await supabase.from('profiles').select('platform_role').eq('id', userId).maybeSingle()
  if (error) {
    console.error('[Navbar] platform_role:', error)
    return false
  }
  return (data?.platform_role ?? '').toString().trim().toLowerCase() === 'admin'
}

export function Navbar() {
  const [mobileOpen, setMobileOpen] = useState(false)
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [isPlatformAdmin, setIsPlatformAdmin] = useState(false)
  const [isLoggingOut, setIsLoggingOut] = useState(false)
  const location = useLocation()
  const navigate = useNavigate()
  const pathname = location.pathname
  const isLanding = pathname === '/'

  useEffect(() => {
    let cancelled = false
    const syncAuth = async (userId: string | undefined) => {
      const admin = await loadPlatformAdmin(userId)
      if (!cancelled) {
        setIsAuthenticated(!!userId)
        setIsPlatformAdmin(admin)
      }
    }
    void supabase.auth.getSession().then(({ data: { session } }) => {
      void syncAuth(session?.user?.id)
    })
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      void syncAuth(session?.user?.id)
    })
    return () => {
      cancelled = true
      subscription.unsubscribe()
    }
  }, [])

  const handleLogout = async () => {
    setIsLoggingOut(true)
    try {
      await supabase.auth.signOut()
      navigate('/login')
    } catch (error) {
      console.error('[Navbar] Błąd wylogowania:', error)
      navigate('/login')
    } finally {
      setIsLoggingOut(false)
    }
  }

  const closeMobile = () => setMobileOpen(false)

  const renderCta = (variant: 'desktop' | 'mobile') => {
    const desktop = variant === 'desktop'
    const className = desktop ? ctaDesktopClass : ctaMobileClass

    if (!isAuthenticated) {
      return (
        <Link to="/login" className={className} onClick={desktop ? undefined : closeMobile}>
          Zaloguj się
        </Link>
      )
    }

    if (pathname === '/dashboard' || pathname === '/firma') {
      return (
        <button
          type="button"
          className={className}
          disabled={isLoggingOut}
          aria-busy={isLoggingOut}
          onClick={() => {
            closeMobile()
            void handleLogout()
          }}
        >
          {isLoggingOut ? 'Wylogowywanie…' : 'Wyloguj się'}
        </button>
      )
    }

    return (
      <Link to="/dashboard" className={className} onClick={desktop ? undefined : closeMobile}>
        Przejdź do panelu
      </Link>
    )
  }

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 glass-strong">
      <div className="container mx-auto flex items-center justify-between h-16 px-4">
        <Link to="/" className="flex items-center gap-2">
          <img src={domioLogo} alt="DOMIO" className="h-8 w-8 rounded-lg object-cover" />
          <span className="font-display font-bold text-xl gradient-brand-text">DOMIO</span>
        </Link>

        <div className="hidden md:flex items-center gap-3">
          {isLanding && (
            <a href="#domio-modules" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
              Moduły
            </a>
          )}
          {isAuthenticated && (
            <>
              <Link to="/dashboard" className="text-sm text-muted-foreground hover:text-foreground transition-colors flex items-center gap-1">
                <LayoutDashboard className="h-4 w-4" /> Panel
              </Link>
              <Link to="/firma" className="text-sm text-muted-foreground hover:text-foreground transition-colors flex items-center gap-1">
                <Building2 className="h-4 w-4" /> Firma
              </Link>
              {isPlatformAdmin ? (
                <Link to="/admin" className="text-sm text-muted-foreground hover:text-foreground transition-colors flex items-center gap-1">
                  <Shield className="h-4 w-4" /> Admin
                </Link>
              ) : null}
            </>
          )}
          <ThemeToggle />
          {renderCta('desktop')}
        </div>

        <button
          type="button"
          onClick={() => setMobileOpen((value) => !value)}
          className="md:hidden rounded-md border border-border px-3 py-2 text-sm"
          aria-expanded={mobileOpen}
          aria-label="Przełącz menu"
        >
          {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
        </button>
      </div>

      {mobileOpen && (
        <div className="md:hidden border-t border-border/50 p-4 space-y-3 glass-strong">
          {isLanding && (
            <a href="#domio-modules" className="block text-sm text-muted-foreground" onClick={closeMobile}>
              Moduły
            </a>
          )}
          <div className="pt-1">
            <ThemeToggle />
          </div>
          {isAuthenticated && (
            <>
              <Link to="/dashboard" className="block text-sm text-muted-foreground" onClick={closeMobile}>
                Panel
              </Link>
              <Link to="/firma" className="block text-sm text-muted-foreground" onClick={closeMobile}>
                Firma
              </Link>
              {isPlatformAdmin ? (
                <Link to="/admin" className="block text-sm text-muted-foreground" onClick={closeMobile}>
                  Admin
                </Link>
              ) : null}
            </>
          )}
          {renderCta('mobile')}
        </div>
      )}
    </nav>
  )
}
