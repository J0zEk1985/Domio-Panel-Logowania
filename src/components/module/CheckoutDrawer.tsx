import { useState } from 'react'
import { createPortal } from 'react-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { Lock, CheckCircle2, CreditCard, Smartphone, Building2, X } from 'lucide-react'
import type { PricingPlan } from './PricingSection'

interface CheckoutDrawerProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  moduleName: string
  plan: PricingPlan | null
  yearly: boolean
}

function CheckoutContent({
  moduleName,
  plan,
  yearly,
  onClose,
}: {
  moduleName: string
  plan: PricingPlan
  yearly: boolean
  onClose: () => void
}) {
  const [paymentMethod, setPaymentMethod] = useState('card')
  const [processing, setProcessing] = useState(false)
  const [success, setSuccess] = useState(false)

  const price = yearly ? plan.yearlyPrice : plan.monthlyPrice
  const cycle = yearly ? 'Rocznie' : 'Miesięcznie'

  const handlePay = () => {
    setProcessing(true)
    setTimeout(() => {
      setProcessing(false)
      setSuccess(true)
    }, 1800)
  }

  const paymentOptions = [
    { value: 'card', label: 'Karta kredytowa', icon: CreditCard },
    { value: 'blik', label: 'BLIK', icon: Smartphone },
    { value: 'payu', label: 'PayU / Przelewy24', icon: Building2 },
  ] as const

  return (
    <div className="p-6 space-y-6 max-h-[80vh] overflow-y-auto">
      <AnimatePresence mode="wait">
        {success ? (
          <motion.div
            key="success"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="flex flex-col items-center justify-center py-12 text-center"
          >
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: 'spring', stiffness: 200, delay: 0.2 }}
              className="p-4 rounded-full bg-primary/10 mb-6"
            >
              <CheckCircle2 className="h-12 w-12 text-primary" />
            </motion.div>
            <h3 className="font-display text-2xl font-bold mb-2">Płatność zakończona!</h3>
            <p className="text-muted-foreground mb-6">
              {moduleName} — {plan.name} został aktywowany.
            </p>
            <button
              type="button"
              onClick={onClose}
              className="rounded-md px-6 py-2 gradient-brand text-primary-foreground text-sm font-medium"
            >
              Gotowe
            </button>
          </motion.div>
        ) : (
          <motion.div key="form" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="space-y-6">
            <div className="rounded-xl bg-muted/50 border border-border/50 p-4 space-y-2">
              <h4 className="font-display font-semibold text-sm text-muted-foreground uppercase tracking-wider">Podsumowanie zamówienia</h4>
              <div className="flex justify-between items-center">
                <div>
                  <p className="font-semibold">{moduleName}</p>
                  <p className="text-sm text-muted-foreground">
                    Plan {plan.name} · {cycle}
                  </p>
                </div>
                <p className="font-display text-xl font-bold">{price} zł</p>
              </div>
            </div>

            <div className="space-y-3">
              <p className="text-sm font-semibold">Metoda płatności</p>
              <div className="grid gap-2">
                {paymentOptions.map((m) => (
                  <label
                    key={m.value}
                    className={`flex items-center gap-3 rounded-xl border px-4 py-3 cursor-pointer transition-colors ${
                      paymentMethod === m.value ? 'border-primary bg-primary/5' : 'border-border/50 bg-muted/30 hover:bg-muted/50'
                    }`}
                  >
                    <input
                      type="radio"
                      name="payment-method"
                      value={m.value}
                      checked={paymentMethod === m.value}
                      onChange={() => setPaymentMethod(m.value)}
                      className="h-4 w-4 accent-primary"
                    />
                    <m.icon className="h-4 w-4 text-muted-foreground shrink-0" />
                    <span className="text-sm font-medium">{m.label}</span>
                  </label>
                ))}
              </div>
            </div>

            <div className="space-y-3">
              <p className="text-sm font-semibold">Dane do faktury</p>
              <input
                type="text"
                placeholder="Imię i nazwisko"
                className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              />
              <input
                type="text"
                placeholder="Firma (opcjonalnie)"
                className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              />
              <input
                type="text"
                placeholder="NIP (opcjonalnie)"
                className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              />
            </div>

            <button
              type="button"
              onClick={handlePay}
              disabled={processing}
              className="w-full flex items-center justify-center gap-2 rounded-md py-3 gradient-brand text-primary-foreground text-sm font-medium disabled:opacity-60"
            >
              <Lock className="h-4 w-4" />
              {processing ? 'Przetwarzanie...' : `Potwierdź i zapłać · ${price} zł`}
            </button>
            <p className="text-xs text-center text-muted-foreground">Płatność jest bezpieczna i szyfrowana SSL.</p>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

export function CheckoutDrawer({ open, onOpenChange, moduleName, plan, yearly }: CheckoutDrawerProps) {
  if (!plan) return null

  const content = (
    <CheckoutContent moduleName={moduleName} plan={plan} yearly={yearly} onClose={() => onOpenChange(false)} />
  )

  const modal = (
    <AnimatePresence>
      {open && (
        <motion.div
          className="fixed inset-0 z-[100] flex items-end md:items-center justify-center p-0 md:p-4"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
        >
          <button
            type="button"
            className="absolute inset-0 bg-black/50"
            aria-label="Zamknij"
            onClick={() => onOpenChange(false)}
          />
          <motion.div
            role="dialog"
            aria-modal="true"
            initial={{ y: 40, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: 40, opacity: 0 }}
            transition={{ type: 'spring', damping: 28, stiffness: 320 }}
            className="relative z-[101] w-full md:max-w-lg max-h-[90vh] md:rounded-2xl rounded-t-2xl bg-card border border-border shadow-2xl overflow-hidden flex flex-col"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between px-4 py-3 border-b border-border shrink-0 md:rounded-t-2xl">
              <div>
                <h2 className="font-display font-semibold text-lg">Zamówienie</h2>
                <p className="text-xs text-muted-foreground">Dokończ zakup modułu</p>
              </div>
              <button
                type="button"
                onClick={() => onOpenChange(false)}
                className="rounded-md p-2 hover:bg-muted"
                aria-label="Zamknij"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            {content}
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )

  if (typeof document === 'undefined') return null
  return createPortal(modal, document.body)
}
