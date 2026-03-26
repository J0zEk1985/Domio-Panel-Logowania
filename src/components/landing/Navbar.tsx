import { useState } from 'react'
import { Link } from 'react-router-dom'

type NavbarProps = {
  isAuthenticated: boolean
}

export function Navbar({ isAuthenticated }: NavbarProps) {
  const [mobileOpen, setMobileOpen] = useState(false)
  const ctaTarget = isAuthenticated ? '/dashboard' : '/login'

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 glass-strong">
      <div className="container mx-auto flex items-center justify-between h-16 px-4">
        <Link to="/" className="flex items-center gap-2">
          <img src="/logo ver 1.jpg" alt="DOMIO" className="h-8 w-8 rounded-lg object-cover" />
          <span className="font-display font-bold text-xl gradient-brand-text">DOMIO</span>
        </Link>

        <div className="hidden md:flex items-center gap-6">
          <a href="#ecosystem" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
            Ekosystem
          </a>
          <a href="#residents" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
            Mieszkańcy
          </a>
          <a href="#business" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
            Firmy
          </a>
          <Link to={ctaTarget} className="gradient-brand text-primary-foreground border-0 rounded-md px-4 py-2 text-sm font-medium">
            Zaloguj się
          </Link>
        </div>

        <button
          type="button"
          onClick={() => setMobileOpen((value) => !value)}
          className="md:hidden rounded-md border border-border px-3 py-2 text-sm"
          aria-expanded={mobileOpen}
          aria-label="Przełącz menu"
        >
          Menu
        </button>
      </div>

      {mobileOpen && (
        <div className="md:hidden border-t border-border/50 p-4 space-y-3 glass-strong">
          <a href="#ecosystem" className="block text-sm text-muted-foreground" onClick={() => setMobileOpen(false)}>
            Ekosystem
          </a>
          <a href="#residents" className="block text-sm text-muted-foreground" onClick={() => setMobileOpen(false)}>
            Mieszkańcy
          </a>
          <a href="#business" className="block text-sm text-muted-foreground" onClick={() => setMobileOpen(false)}>
            Firmy
          </a>
          <Link
            to={ctaTarget}
            className="block w-full rounded-md px-4 py-2 text-center font-medium gradient-brand text-primary-foreground"
            onClick={() => setMobileOpen(false)}
          >
            Zaloguj się
          </Link>
        </div>
      )}
    </nav>
  )
}
