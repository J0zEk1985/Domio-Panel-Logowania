import { motion, useScroll, useTransform } from 'framer-motion'
import { ArrowDown } from 'lucide-react'
import { Link } from 'react-router-dom'
import domioLogo from '../../../lovable-design/src/assets/domio-logo.jpg'

type HeroSectionProps = {
  isAuthenticated: boolean
}

export function HeroSection({ isAuthenticated }: HeroSectionProps) {
  const ctaTarget = isAuthenticated ? '/dashboard' : '/login'
  const { scrollY } = useScroll()
  const logoScale = useTransform(scrollY, [0, 400], [1, 0.3])
  const logoOpacity = useTransform(scrollY, [0, 300], [1, 0])
  const logoY = useTransform(scrollY, [0, 400], [0, -200])
  const textY = useTransform(scrollY, [0, 300], [0, -50])
  const textOpacity = useTransform(scrollY, [0, 250], [1, 0])

  return (
    <section className="relative min-h-screen flex flex-col items-center justify-center overflow-hidden px-4 pt-16">
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 rounded-full bg-primary/5 blur-3xl animate-float" />
        <div
          className="absolute bottom-1/4 right-1/4 w-80 h-80 rounded-full bg-accent/5 blur-3xl animate-float"
          style={{ animationDelay: '3s' }}
        />
      </div>

      <motion.div style={{ scale: logoScale, opacity: logoOpacity, y: logoY }} className="mb-8">
        <div className="relative">
          <div className="absolute inset-0 rounded-3xl bg-primary/20 blur-2xl animate-glow" />
          <img src={domioLogo} alt="DOMIO Logo" className="relative w-40 h-40 md:w-56 md:h-56 rounded-3xl object-cover shadow-2xl" />
        </div>
      </motion.div>

      <motion.div style={{ y: textY, opacity: textOpacity }} className="text-center max-w-3xl">
        <h1 className="font-display text-5xl md:text-7xl font-bold tracking-tight mb-4">
          <span className="gradient-brand-text">DOMIO</span>
        </h1>
        <p className="text-lg md:text-xl text-muted-foreground max-w-xl mx-auto mb-8 text-balance">
          Jeden ekosystem aplikacji dla mieszkańców i firm. Zarządzaj usługami, zespołami i procesami w jednym, szybkim panelu.
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Link to={ctaTarget} className="gradient-brand text-primary-foreground border-0 px-8 py-3 rounded-md text-base font-medium">
            Zaloguj się
          </Link>
          <a href="#ecosystem" className="px-8 py-3 rounded-md text-base font-medium border border-border hover:bg-muted/40">
            Odkryj DOMIO
          </a>
        </div>
      </motion.div>

      <motion.div className="absolute bottom-8" animate={{ y: [0, 10, 0] }} transition={{ duration: 2, repeat: Infinity }}>
        <ArrowDown className="h-6 w-6 text-muted-foreground" />
      </motion.div>
    </section>
  )
}
