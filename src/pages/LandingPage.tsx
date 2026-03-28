import { useEffect, useState } from 'react'
import { Navbar } from '../components/landing/Navbar'
import { HeroSection } from '../components/landing/HeroSection'
import { ValueProposition } from '../components/landing/ValueProposition'
import { BentoGrid } from '../components/landing/BentoGrid'
import { Footer } from '../components/landing/Footer'
import { supabase } from '../lib/supabase'

export default function LandingPage() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [cmsContent, setCmsContent] = useState<Record<string, string>>({})

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

  useEffect(() => {
    let cancelled = false
    void supabase
      .from('page_content')
      .select('content_key, content_value')
      .then(({ data, error }) => {
        if (cancelled) return
        if (error) {
          console.error('[LandingPage] page_content:', error)
          return
        }
        const contentMap = (data ?? []).reduce<Record<string, string>>((acc, row) => {
          acc[row.content_key] = row.content_value ?? ''
          return acc
        }, {})
        setCmsContent(contentMap)
      })
    return () => {
      cancelled = true
    }
  }, [])

  return (
    <div className="min-h-screen bg-background text-foreground">
      <Navbar />
      <HeroSection isAuthenticated={isAuthenticated} cmsContent={cmsContent} />
      <ValueProposition aboutText={cmsContent.about_text} />
      <BentoGrid />
      <Footer copyrightLine={cmsContent.footer_copyright} />
    </div>
  )
}
