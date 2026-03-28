import { useState } from 'react'
import { useParams, Link, Navigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ArrowLeft, Layers, CheckCircle2 } from 'lucide-react'
import { Navbar } from '../components/landing/Navbar'
import { Footer } from '../components/landing/Footer'
import { getModuleBySlug } from '../data/modules'
import { PricingSection, type PricingPlan } from '../components/module/PricingSection'
import { CheckoutDrawer } from '../components/module/CheckoutDrawer'

const btnPrimary = 'inline-flex items-center justify-center rounded-md px-6 py-3 text-sm font-medium gradient-brand text-primary-foreground border-0 shadow-sm hover:opacity-95 transition-opacity'
const btnGhost = 'inline-flex items-center justify-center gap-2 rounded-md px-6 py-3 text-sm font-medium border border-border bg-transparent hover:bg-muted/60 transition-colors'

export default function ModuleDetail() {
  const { slug } = useParams<{ slug: string }>()
  const mod = slug ? getModuleBySlug(slug) : undefined
  const [checkoutOpen, setCheckoutOpen] = useState(false)
  const [selectedPlan, setSelectedPlan] = useState<PricingPlan | null>(null)
  const [selectedYearly, setSelectedYearly] = useState(false)

  const handleSelectPlan = (plan: PricingPlan, yearly: boolean) => {
    setSelectedPlan(plan)
    setSelectedYearly(yearly)
    setCheckoutOpen(true)
  }

  if (!mod) return <Navigate to="/" replace />
  if (mod.comingSoon) return <Navigate to="/" replace />

  const Icon = mod.icon

  return (
    <div className="min-h-screen bg-background">
      <Navbar />

      <section className="pt-32 pb-20 px-4">
        <div className="container mx-auto max-w-5xl">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            <motion.div
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ duration: 0.5, delay: 0.1 }}
              className={`inline-flex p-5 rounded-2xl bg-muted ${mod.color} mb-6`}
            >
              <Icon className="h-12 w-12" />
            </motion.div>
            <h1 className="font-display text-4xl md:text-6xl font-bold mb-4">{mod.name}</h1>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto mb-8">{mod.tagline}</p>
            <p className="text-muted-foreground max-w-xl mx-auto mb-10">{mod.description}</p>
            <div className="flex items-center justify-center gap-4 flex-wrap">
              <Link to="/dashboard" className={btnPrimary}>
                Rozpocznij za darmo
              </Link>
              <Link to="/#domio-modules" className={btnGhost}>
                <ArrowLeft className="h-4 w-4" /> Wróć do przeglądu modułów
              </Link>
            </div>
          </motion.div>
        </div>
      </section>

      {mod.features.length > 0 && (
        <section className="py-20 px-4">
          <div className="container mx-auto max-w-6xl">
            <motion.h2
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="font-display text-3xl md:text-4xl font-bold text-center mb-4"
            >
              Kluczowe <span className="gradient-brand-text">funkcje</span>
            </motion.h2>
            <p className="text-muted-foreground text-center mb-12 max-w-md mx-auto">Wszystko, czego potrzebujesz, w jednym module.</p>
            <motion.div
              initial="hidden"
              whileInView="show"
              viewport={{ once: true, amount: 0.2 }}
              variants={{ hidden: { opacity: 0 }, show: { opacity: 1, transition: { staggerChildren: 0.08 } } }}
              className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
            >
              {mod.features.map((feat) => {
                const FeatIcon = feat.icon
                return (
                  <motion.div
                    key={feat.title}
                    variants={{ hidden: { opacity: 0, y: 20 }, show: { opacity: 1, y: 0 } }}
                    whileHover={{ y: -4, scale: 1.02 }}
                    className="bento-card"
                  >
                    <div className={`p-3 rounded-xl bg-muted ${mod.color} w-fit mb-3`}>
                      <FeatIcon className="h-5 w-5" />
                    </div>
                    <h3 className="font-display font-semibold text-lg mb-1">{feat.title}</h3>
                    <p className="text-sm text-muted-foreground">{feat.description}</p>
                  </motion.div>
                )
              })}
            </motion.div>
          </div>
        </section>
      )}

      {mod.useCases.length > 0 && (
        <section className="py-20 px-4">
          <div className="container mx-auto max-w-5xl">
            <motion.h2
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="font-display text-3xl md:text-4xl font-bold text-center mb-4"
            >
              Dla kogo jest <span className="gradient-brand-text">{mod.name}</span>?
            </motion.h2>
            <p className="text-muted-foreground text-center mb-12 max-w-md mx-auto">Rozwiązania dopasowane do każdego użytkownika.</p>
            <div className="grid md:grid-cols-2 gap-6">
              {mod.useCases.map((uc, i) => {
                const UcIcon = uc.icon
                return (
                  <motion.div
                    key={uc.audience}
                    initial={{ opacity: 0, x: i === 0 ? -30 : 30 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.6 }}
                    className="bento-card relative overflow-hidden group"
                  >
                    <div className="absolute top-0 right-0 w-32 h-32 bg-primary/5 rounded-full blur-2xl group-hover:bg-primary/10 transition-colors" />
                    <div className="relative">
                      <div className={`p-3 rounded-xl bg-muted ${mod.color} w-fit mb-4`}>
                        <UcIcon className="h-7 w-7" />
                      </div>
                      <h3 className="font-display text-2xl font-bold mb-4">
                        Dla {uc.audience === 'Mieszkańcy' ? 'Mieszkańców' : uc.audience}
                      </h3>
                      <ul className="space-y-3">
                        {uc.benefits.map((b) => (
                          <li key={b} className="flex items-start gap-2 text-muted-foreground">
                            <CheckCircle2 className="h-5 w-5 text-primary shrink-0 mt-0.5" />
                            <span>{b}</span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  </motion.div>
                )
              })}
            </div>
          </div>
        </section>
      )}

      {mod.integrations.length > 0 && (
        <section className="py-20 px-4">
          <div className="container mx-auto max-w-4xl">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="bento-card text-center"
            >
              <div className="inline-flex p-3 rounded-xl bg-muted text-primary mb-4">
                <Layers className="h-7 w-7" />
              </div>
              <h2 className="font-display text-2xl md:text-3xl font-bold mb-3">
                Pełna integracja z <span className="gradient-brand-text">platformą DOMIO</span>
              </h2>
              <p className="text-muted-foreground mb-8 max-w-lg mx-auto">
                Jeden login, jedno konto — wszystkie moduły połączone w jednej spójnej platformie.
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 max-w-lg mx-auto">
                {mod.integrations.map((int) => (
                  <div key={int} className="flex items-center gap-2 text-sm text-muted-foreground bg-muted/50 rounded-xl px-4 py-3">
                    <CheckCircle2 className="h-4 w-4 text-primary shrink-0" />
                    <span>{int}</span>
                  </div>
                ))}
              </div>
            </motion.div>
          </div>
        </section>
      )}

      <PricingSection moduleName={mod.name} moduleSlug={mod.slug} onSelectPlan={handleSelectPlan} />

      <section className="py-16 px-4">
        <div className="container mx-auto max-w-3xl text-center">
          <motion.div initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }}>
            <h2 className="font-display text-2xl md:text-3xl font-bold mb-4">
              Gotowy na <span className="gradient-brand-text">{mod.name}</span>?
            </h2>
            <p className="text-muted-foreground mb-8">Zacznij korzystać już dziś — bez zobowiązań.</p>
            <Link to="/dashboard" className={btnPrimary}>
              Rozpocznij za darmo
            </Link>
          </motion.div>
        </div>
      </section>

      <CheckoutDrawer
        open={checkoutOpen}
        onOpenChange={setCheckoutOpen}
        moduleName={mod.name}
        plan={selectedPlan}
        yearly={selectedYearly}
      />

      <Footer />
    </div>
  )
}
