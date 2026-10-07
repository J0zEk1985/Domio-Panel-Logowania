/**
 * SubscriptionsPage
 * 
 * Organization Admin page for managing module subscriptions
 * Tabs: Store (purchase new), My Subscriptions (view/manage active)
 */

import { useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { ShoppingCart, CreditCard } from 'lucide-react'
import { Navbar } from '../components/landing/Navbar'
import { Footer } from '../components/landing/Footer'
import SubscriptionStoreView from '../components/organization/SubscriptionStoreView'
import MySubscriptionsView from '../components/organization/MySubscriptionsView'

type SubTab = 'store' | 'my-subscriptions'

const tabs: { id: SubTab; label: string; icon: typeof ShoppingCart }[] = [
  { id: 'store', label: 'Sklep', icon: ShoppingCart },
  { id: 'my-subscriptions', label: 'Moje subskrypcje', icon: CreditCard },
]

export default function SubscriptionsPage() {
  const [activeTab, setActiveTab] = useState<SubTab>('store')
  const [searchParams] = useSearchParams()
  const focus = searchParams.get('focus') === 'developer_warranty' ? 'developer_warranty' : 'home'
  const pageTitle = focus === 'home' ? 'DOMIO Home' : 'Usterki deweloperskie'
  const pageDescription =
    focus === 'home'
      ? 'Wybierz wspólnotę i wykup aplikację mieszkańca. Cena zależy od liczby lokali mieszkalnych.'
      : 'Usługa dodatkowa modułu Domio Administracja. Po aktywacji funkcja włącza się w aplikacji Administracja.'

  return (
    <div className="min-h-screen flex flex-col">
      <Navbar />

      <div className="flex-1 container mx-auto px-4 py-8 max-w-6xl">
        <div className="mb-8">
          <h1 className="font-display text-3xl font-bold mb-2">{pageTitle}</h1>
          <p className="text-muted-foreground">{pageDescription}</p>
          <div className="mt-4 flex flex-wrap gap-2">
            <Link
              to="/subscriptions?focus=home"
              className={`inline-flex h-9 items-center rounded-md border px-3 text-sm font-medium ${
                focus === 'home' ? 'border-primary text-primary' : 'border-border text-muted-foreground hover:bg-muted/60'
              }`}
            >
              DOMIO Home
            </Link>
            <Link
              to="/subscriptions?focus=developer_warranty"
              className={`inline-flex h-9 items-center rounded-md border px-3 text-sm font-medium ${
                focus === 'developer_warranty'
                  ? 'border-primary text-primary'
                  : 'border-border text-muted-foreground hover:bg-muted/60'
              }`}
            >
              Usługi dodatkowe
            </Link>
          </div>
        </div>

        {/* Tabs */}
        <div className="border-b border-border mb-8">
          <div className="flex gap-1">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
                  activeTab === tab.id
                    ? 'border-primary text-primary'
                    : 'border-transparent text-muted-foreground hover:text-foreground'
                }`}
              >
                <tab.icon className="h-4 w-4" />
                {tab.label}
              </button>
            ))}
          </div>
        </div>

        {/* Tab Content */}
        <div>
          {activeTab === 'store' && <SubscriptionStoreView moduleFilter={focus} />}
          {activeTab === 'my-subscriptions' && <MySubscriptionsView />}
        </div>
      </div>

      <Footer />
    </div>
  )
}
