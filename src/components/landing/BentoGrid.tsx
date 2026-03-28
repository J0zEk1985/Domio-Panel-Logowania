import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import { Building2, CarFront, Sparkles, Wrench } from 'lucide-react'

const modules: {
  slug: string
  name: string
  description: string
  cta: string
  icon: typeof Sparkles
  iconClass: string
}[] = [
  {
    slug: 'cleaning',
    name: 'Domio Cleaning',
    description: 'Planowanie i kontrola usług porządkowych dla nieruchomości, osiedli i klientów biznesowych.',
    cta: 'Więcej o Cleaning',
    icon: Sparkles,
    iconClass: 'text-primary',
  },
  {
    slug: 'flota',
    name: 'Domio Flota',
    description: 'Zarządzanie pojazdami, kierowcami i harmonogramami serwisowymi bez rozproszonych narzędzi.',
    cta: 'Zarządzaj Flotą',
    icon: CarFront,
    iconClass: 'text-accent',
  },
  {
    slug: 'serwis',
    name: 'Domio Serwis',
    description: 'Obsługa zgłoszeń, usterek i zadań technicznych z pełną historią i statusem realizacji.',
    cta: 'Poznaj Serwis',
    icon: Wrench,
    iconClass: 'text-primary',
  },
  {
    slug: 'biznes',
    name: 'Domio Biznes',
    description: 'Rozwijaj obsługę klientów, automatyzuj procesy i skaluj operacje w jednej platformie.',
    cta: 'Sprawdź Moduł',
    icon: Building2,
    iconClass: 'text-accent',
  },
]

export function BentoGrid() {
  return (
    <section id="domio-modules" className="py-24 px-4">
      <div className="container mx-auto max-w-6xl">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="font-display text-3xl md:text-5xl font-bold mb-4">
            Moduły <span className="gradient-brand-text">DOMIO</span>
          </h2>
          <p className="text-muted-foreground text-lg max-w-md mx-auto">Modularna platforma, którą dopasowujesz do swoich potrzeb.</p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, amount: 0.2 }}
          transition={{ duration: 0.4 }}
          className="grid grid-cols-1 md:grid-cols-2 gap-4"
        >
          {modules.map((mod) => {
            const Icon = mod.icon
            return (
              <motion.div key={mod.slug} whileHover={{ y: -6, scale: 1.02 }} transition={{ duration: 0.2 }} className="group">
                <Link
                  to={`/module/${mod.slug}`}
                  className="block bento-card hover:shadow-2xl hover:shadow-primary/20 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring rounded-2xl"
                >
                  <div className="flex items-start gap-4">
                    <div className={`p-3 rounded-xl bg-muted ${mod.iconClass}`}>
                      <Icon className="h-6 w-6" />
                    </div>
                    <div className="flex-1">
                      <h3 className="font-display font-semibold text-lg mb-2">{mod.name}</h3>
                      <p className="text-sm text-muted-foreground mb-5">{mod.description}</p>
                      <span className="inline-block rounded-md border border-border px-3 py-2 text-sm group-hover:bg-muted/60 transition-colors">
                        {mod.cta}
                      </span>
                    </div>
                  </div>
                </Link>
              </motion.div>
            )
          })}
        </motion.div>
      </div>
    </section>
  )
}
