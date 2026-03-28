import { useEffect, useState } from 'react'
import { Navbar } from '../components/landing/Navbar'
import { HeroSection } from '../components/landing/HeroSection'
import { ValueProposition } from '../components/landing/ValueProposition'
import { BentoGrid } from '../components/landing/BentoGrid'
import { Footer } from '../components/landing/Footer'
import { supabase } from '../lib/supabase'

export default function LandingPage() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)

  useEffect(() => {
    let cancelled = false
    void supabase.auth.getSession().then(({ data: { session } }) => {
      if (!cancelled) setIsAuthenticated(!!session)
    })
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setIsAuthenticated(!!session)
    })
    return () => {
      cancelled = true
      subscription.unsubscribe()
    }
  }, [])

  return (
    <div className="min-h-screen bg-background text-foreground">
      <Navbar />
      <HeroSection isAuthenticated={isAuthenticated} />
      <ValueProposition />
      <BentoGrid />
      <Footer />
    </div>
  )
}
