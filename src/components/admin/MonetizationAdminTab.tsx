/**
 * MonetizationAdminTab
 * 
 * Service Owner / SuperAdmin tab for managing module monetization
 */

import MonetizationPricingPlansSection from './MonetizationPricingPlansSection'

export default function MonetizationAdminTab() {
  return (
    <div className="space-y-8">
      <div>
        <h1 className="font-display text-3xl font-bold mb-2">Monetyzacja modułów</h1>
        <p className="text-muted-foreground">
          Zarządzaj planami cenowymi modułów DOMIO Home i Usterki Deweloperskie. Cenniki
          pozostałych aplikacji ustawiasz w zakładce Cennik i Promocje.
        </p>
      </div>

      <MonetizationPricingPlansSection />
    </div>
  )
}
