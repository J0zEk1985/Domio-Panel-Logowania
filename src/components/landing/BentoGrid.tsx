import { motion } from 'framer-motion'
import { Building2, CarFront, Sparkles, Wrench } from 'lucide-react'

const modules = [
  {
    slug: 'cleaning',
    name: 'Domio Cleaning',
    description: 'Planowanie i kontrola usług porządkowych dla nieruchomości, osiedli i klientów biznesowych.',
    cta: 'Więcej o Cleaning',
    icon: Sparkles,
    iconClass: 'text-primary',
  },
  {
    slug: 'fleet',
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
    <section id="ecosystem" className="py-24 px-4">
      <div className="container mx-auto max-w-6xl">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="font-display text-3xl md:text-5xl font-bold mb-4">
            Ekosystem <span className="gradient-brand-text">DOMIO</span>
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
              <motion.article
                key={mod.slug}
                whileHover={{ y: -6, scale: 1.02 }}
                transition={{ duration: 0.2 }}
                className="bento-card hover:shadow-2xl hover:shadow-primary/20"
              >
                <div className="flex items-start gap-4">
                  <div className={`p-3 rounded-xl bg-muted ${mod.iconClass}`}>
                    <Icon className="h-6 w-6" />
                  </div>
                  <div className="flex-1">
                    <h3 className="font-display font-semibold text-lg mb-2">{mod.name}</h3>
                    <p className="text-sm text-muted-foreground mb-5">{mod.description}</p>
                    <button type="button" className="rounded-md border border-border px-3 py-2 text-sm hover:bg-muted/60 transition-colors">
                      {mod.cta}
                    </button>
                  </div>
                </div>
              </motion.article>
            )
          })}
        </motion.div>
      </div>
    </section>
  )
}
