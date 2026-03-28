import { useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { LayoutDashboard, Menu, Shield, X } from 'lucide-react'
import { ThemeToggle } from './ThemeToggle'
import domioLogo from '../../../lovable-design/src/assets/domio-logo.jpg'
import { supabase } from '../../lib/supabase'

type NavbarProps = {
  isAuthenticated: boolean
}

const ctaDesktopClass =
  'gradient-brand text-primary-foreground border-0 rounded-md px-4 py-2 text-sm font-medium inline-flex items-center justify-center'
const ctaMobileClass =
  'block w-full rounded-md px-4 py-2 text-center font-medium gradient-brand text-primary-foreground'

export function Navbar({ isAuthenticated }: NavbarProps) {
  const [mobileOpen, setMobileOpen] = useState(false)
  const location = useLocation()
  const navigate = useNavigate()
  const pathname = location.pathname
  const isLanding = pathname === '/'

  const handleLogout = async () => {
    try {
      await supabase.auth.signOut()
      navigate('/login')
    } catch (error) {
      console.error('[Navbar] Błąd wylogowania:', error)
      navigate('/login')
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

    if (pathname === '/dashboard') {
      return (
        <button
          type="button"
          className={className}
          onClick={() => {
            closeMobile()
            void handleLogout()
          }}
        >
          Wyloguj się
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
            <>
              <a href="#domio-modules" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
                Moduły
              </a>
              <a href="#residents" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
                Mieszkańcy
              </a>
              <a href="#business" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
                Firmy
              </a>
            </>
          )}
          {isAuthenticated && (
            <>
              <Link to="/dashboard" className="text-sm text-muted-foreground hover:text-foreground transition-colors flex items-center gap-1">
                <LayoutDashboard className="h-4 w-4" /> Panel
              </Link>
              <Link to="/admin" className="text-sm text-muted-foreground hover:text-foreground transition-colors flex items-center gap-1">
                <Shield className="h-4 w-4" /> Admin
              </Link>
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
            <>
              <a href="#domio-modules" className="block text-sm text-muted-foreground" onClick={closeMobile}>
                Moduły
              </a>
              <a href="#residents" className="block text-sm text-muted-foreground" onClick={closeMobile}>
                Mieszkańcy
              </a>
              <a href="#business" className="block text-sm text-muted-foreground" onClick={closeMobile}>
                Firmy
              </a>
            </>
          )}
          <div className="pt-1">
            <ThemeToggle />
          </div>
          {isAuthenticated && (
            <>
              <Link to="/dashboard" className="block text-sm text-muted-foreground" onClick={closeMobile}>
                Panel
              </Link>
              <Link to="/admin" className="block text-sm text-muted-foreground" onClick={closeMobile}>
                Admin
              </Link>
            </>
          )}
          {renderCta('mobile')}
        </div>
      )}
    </nav>
  )
}
