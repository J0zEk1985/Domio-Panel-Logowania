import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'

type HeroSectionProps = {
  isAuthenticated: boolean
}

export function HeroSection({ isAuthenticated }: HeroSectionProps) {
  const [scrollY, setScrollY] = useState(0)
  const ctaTarget = isAuthenticated ? '/dashboard' : '/login'

  useEffect(() => {
    const onScroll = () => {
      setScrollY(window.scrollY)
    }

    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  const logoStyle = useMemo(() => {
    const progress = Math.min(scrollY / 400, 1)
    const scale = 1 - progress * 0.7
    const opacity = 1 - Math.min(scrollY / 300, 1)
    const translateY = -progress * 200
    return { transform: `translateY(${translateY}px) scale(${scale})`, opacity }
  }, [scrollY])

  return (
    <section className="relative min-h-screen flex flex-col items-center justify-center overflow-hidden px-4 pt-16">
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 rounded-full bg-primary/5 blur-3xl animate-float" />
        <div
          className="absolute bottom-1/4 right-1/4 w-80 h-80 rounded-full bg-accent/5 blur-3xl animate-float"
          style={{ animationDelay: '3s' }}
        />
      </div>

      <div className="mb-8 transition-transform duration-100" style={logoStyle}>
        <div className="relative">
          <div className="absolute inset-0 rounded-3xl bg-primary/20 blur-2xl animate-glow" />
          <img src="/logo ver 1.jpg" alt="DOMIO Logo" className="relative w-40 h-40 md:w-56 md:h-56 rounded-3xl object-cover shadow-2xl" />
        </div>
      </div>

      <div className="text-center max-w-3xl">
        <h1 className="font-display text-5xl md:text-7xl font-bold tracking-tight mb-4">
          <span className="gradient-brand-text">DOMIO</span>
          <br />
          <span className="text-foreground">Ecosystem Hub</span>
        </h1>
        <p className="text-lg md:text-xl text-muted-foreground max-w-xl mx-auto mb-8 text-balance">
          Jeden ekosystem aplikacji dla mieszkańców i firm. Zarządzaj, kontroluj, rozwijaj - wszystko w jednym miejscu.
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Link to={ctaTarget} className="gradient-brand text-primary-foreground border-0 px-8 py-3 rounded-md text-base font-medium">
            Wejdź do Hub
          </Link>
          <a href="#ecosystem" className="px-8 py-3 rounded-md text-base font-medium border border-border hover:bg-muted/40">
            Odkryj ekosystem
          </a>
        </div>
      </div>
    </section>
  )
}
