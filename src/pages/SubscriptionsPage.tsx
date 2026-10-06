/**
 * SubscriptionsPage
 * 
 * Organization Admin page for managing module subscriptions
 * Tabs: Store (purchase new), My Subscriptions (view/manage active)
 */

import { useState } from 'react'
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

  return (
    <div className="min-h-screen flex flex-col">
      <Navbar />

      <div className="flex-1 container mx-auto px-4 py-8 max-w-6xl">
        <div className="mb-8">
          <h1 className="font-display text-3xl font-bold mb-2">Subskrypcje modułów</h1>
          <p className="text-muted-foreground">
            Zakup i zarządzaj subskrypcjami modułów DOMIO dla Twojej organizacji.
          </p>
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
          {activeTab === 'store' && <SubscriptionStoreView />}
          {activeTab === 'my-subscriptions' && <MySubscriptionsView />}
        </div>
      </div>

      <Footer />
    </div>
  )
}
