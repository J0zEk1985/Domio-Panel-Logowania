import { Navbar } from '../components/landing/Navbar'
import { HeroSection } from '../components/landing/HeroSection'
import { ValueProposition } from '../components/landing/ValueProposition'
import { BentoGrid } from '../components/landing/BentoGrid'
import { Footer } from '../components/landing/Footer'

type LandingPageProps = {
  isAuthenticated: boolean
}

export default function LandingPage({ isAuthenticated }: LandingPageProps) {
  return (
    <div className="min-h-screen bg-background text-foreground">
      <Navbar isAuthenticated={isAuthenticated} />
      <HeroSection isAuthenticated={isAuthenticated} />
      <ValueProposition />
      <BentoGrid />
      <Footer />
    </div>
  )
}
