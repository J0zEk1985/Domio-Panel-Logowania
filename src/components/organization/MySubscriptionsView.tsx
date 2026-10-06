/**
 * MySubscriptionsView
 * 
 * Display active module subscriptions for the organization
 * Shows status, expiration, and upgrade/renew actions
 */

import { useState, useEffect } from 'react'
import { CreditCard, AlertTriangle, Calendar, CheckCircle2, XCircle, Clock } from 'lucide-react'
import { toast } from 'sonner'
import { supabase } from '../../lib/supabase'
import { useSubscriptions } from '../../hooks/useMonetization'
import type { ModuleSubscription, BillingInterval } from '../../types/monetization'
import {
  MODULE_DISPLAY_NAMES,
  SUBSCRIPTION_STATUS_LABELS,
  BILLING_INTERVAL_LABELS,
} from '../../types/monetization'
import SubscriptionUpgradeModal from './SubscriptionUpgradeModal'

export default function MySubscriptionsView() {
  const [selectedOrgId, setSelectedOrgId] = useState<string | null>(null)
  const [upgradeModalOpen, setUpgradeModalOpen] = useState(false)
  const [selectedSubscription, setSelectedSubscription] = useState<ModuleSubscription | null>(null)

  const { subscriptions, loading, fetchSubscriptions, cancelSubscription, renewSubscription } =
    useSubscriptions({ org_id: selectedOrgId ?? undefined })

  useEffect(() => {
    const loadUserOrg = async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser()
      if (!user) return

      const { data: memberships } = await supabase
        .from('memberships')
        .select('organization_id, role')
        .eq('user_id', user.id)
        .in('role', ['admin', 'owner'])
        .limit(1)
        .single()

      if (memberships?.organization_id) {
        setSelectedOrgId(memberships.organization_id)
      }
    }

    void loadUserOrg()
  }, [])

  useEffect(() => {
    if (selectedOrgId) {
      void fetchSubscriptions()
    }
  }, [selectedOrgId, fetchSubscriptions])

  const handleCancel = async (id: string) => {
    if (!window.confirm('Czy na pewno anulować tę subskrypcję?')) return

    const result = await cancelSubscription(id)
    if (result.success) {
      toast.success('Subskrypcja anulowana')
    } else {
      toast.error(result.error ?? 'Nie udało się anulować subskrypcji')
    }
  }

  const handleRenew = async (id: string, interval: BillingInterval) => {
    const result = await renewSubscription(id, interval)
    if (result.success) {
      toast.success('Subskrypcja odnowiona')
    } else {
      toast.error(result.error ?? 'Nie udało się odnowić subskrypcji')
    }
  }

  const openUpgradeModal = (subscription: ModuleSubscription) => {
    setSelectedSubscription(subscription)
    setUpgradeModalOpen(true)
  }

  const closeUpgradeModal = () => {
    setUpgradeModalOpen(false)
    setSelectedSubscription(null)
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active':
        return <CheckCircle2 className="h-5 w-5 text-green-600" />
      case 'blocked_pending_payment':
        return <AlertTriangle className="h-5 w-5 text-amber-600" />
      case 'expired':
      case 'cancelled':
        return <XCircle className="h-5 w-5 text-red-600" />
      default:
        return <Clock className="h-5 w-5 text-muted-foreground" />
    }
  }

  const getStatusBadgeClass = (status: string): string => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800 border-green-200'
      case 'blocked_pending_payment':
        return 'bg-amber-100 text-amber-800 border-amber-200'
      case 'expired':
      case 'cancelled':
        return 'bg-red-100 text-red-800 border-red-200'
      default:
        return 'bg-muted text-muted-foreground border-border'
    }
  }

  const formatDate = (dateString: string | null): string => {
    if (!dateString) return '—'
    return new Date(dateString).toLocaleDateString('pl-PL', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    })
  }

  const formatPrice = (price: number): string => {
    return `${price.toFixed(2)} zł`
  }

  const isExpiringSoon = (sub: ModuleSubscription): boolean => {
    if (!sub.expires_at || sub.status !== 'active') return false
    const daysUntilExpiry = Math.ceil(
      (new Date(sub.expires_at).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
    )
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0
  }

  const needsUpgrade = (sub: ModuleSubscription): boolean => {
    return (
      sub.status === 'blocked_pending_payment' &&
      sub.paid_unit_count != null &&
      sub.current_unit_count != null &&
      sub.current_unit_count > sub.paid_unit_count
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <CreditCard className="h-6 w-6 text-primary" />
        <h2 className="font-display text-2xl font-semibold">Moje subskrypcje</h2>
      </div>

      {loading ? (
        <div className="bento-card p-8 text-center text-muted-foreground">Ładowanie subskrypcji...</div>
      ) : subscriptions.length === 0 ? (
        <div className="bento-card p-8 text-center text-muted-foreground">
          Brak aktywnych subskrypcji. Odwiedź sklep, aby zakupić nowe moduły.
        </div>
      ) : (
        <div className="space-y-4">
          {subscriptions.map((sub) => (
            <div
              key={sub.id}
              className={`bento-card p-6 space-y-4 ${
                needsUpgrade(sub) ? 'border-2 border-amber-500/50' : ''
              }`}
            >
              <div className="flex items-start justify-between">
                <div className="flex items-start gap-3">
                  {getStatusIcon(sub.status)}
                  <div>
                    <h3 className="font-semibold text-lg">{MODULE_DISPLAY_NAMES[sub.module]}</h3>
                    <p className="text-sm text-muted-foreground">
                      {BILLING_INTERVAL_LABELS[sub.billing_interval]}
                    </p>
                  </div>
                </div>
                <span
                  className={`inline-flex rounded-full px-3 py-1 text-xs font-medium border ${getStatusBadgeClass(
                    sub.status
                  )}`}
                >
                  {SUBSCRIPTION_STATUS_LABELS[sub.status]}
                </span>
              </div>

              {needsUpgrade(sub) && (
                <div className="bg-amber-50 border border-amber-200 rounded-lg p-4 flex items-start gap-3">
                  <AlertTriangle className="h-5 w-5 text-amber-600 mt-0.5 flex-shrink-0" />
                  <div className="flex-1">
                    <p className="text-sm font-medium text-amber-900">Subskrypcja wymaga dopłaty</p>
                    <p className="text-xs text-amber-800 mt-1">
                      Liczba lokali mieszkalnych wzrosła z {sub.paid_unit_count} do {sub.current_unit_count}.
                      Dokonaj dopłaty, aby odblokować dostęp.
                    </p>
                  </div>
                  <button
                    onClick={() => openUpgradeModal(sub)}
                    className="px-4 py-2 bg-amber-600 text-white rounded-md text-sm font-medium hover:bg-amber-700 flex-shrink-0"
                  >
                    Dopłać
                  </button>
                </div>
              )}

              {isExpiringSoon(sub) && sub.status === 'active' && (
                <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 flex items-start gap-3">
                  <Calendar className="h-5 w-5 text-blue-600 mt-0.5 flex-shrink-0" />
                  <div className="flex-1">
                    <p className="text-sm font-medium text-blue-900">Subskrypcja wygasa wkrótce</p>
                    <p className="text-xs text-blue-800 mt-1">
                      Wygasa: {formatDate(sub.expires_at)}. Odnów teraz, aby zachować ciągłość dostępu.
                    </p>
                  </div>
                  <button
                    onClick={() => void handleRenew(sub.id, sub.billing_interval)}
                    className="px-4 py-2 bg-blue-600 text-white rounded-md text-sm font-medium hover:bg-blue-700 flex-shrink-0"
                  >
                    Odnów
                  </button>
                </div>
              )}

              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                <div>
                  <p className="text-muted-foreground text-xs mb-1">Zakupiono</p>
                  <p className="font-medium">{formatDate(sub.purchased_at)}</p>
                </div>
                {sub.activated_at && (
                  <div>
                    <p className="text-muted-foreground text-xs mb-1">Aktywowano</p>
                    <p className="font-medium">{formatDate(sub.activated_at)}</p>
                  </div>
                )}
                {sub.expires_at && (
                  <div>
                    <p className="text-muted-foreground text-xs mb-1">Wygasa</p>
                    <p className="font-medium">{formatDate(sub.expires_at)}</p>
                  </div>
                )}
                <div>
                  <p className="text-muted-foreground text-xs mb-1">Kwota</p>
                  <p className="font-medium">{formatPrice(sub.amount_paid)}</p>
                </div>
              </div>

              {sub.paid_unit_count != null && (
                <div className="border-t border-border/60 pt-4">
                  <p className="text-sm text-muted-foreground mb-2">Jednostki mieszkalne</p>
                  <div className="flex items-center gap-4 text-sm">
                    <div>
                      <span className="font-medium">Opłacone:</span> {sub.paid_unit_count}
                    </div>
                    {sub.current_unit_count != null && (
                      <div>
                        <span className="font-medium">Aktualne:</span> {sub.current_unit_count}
                      </div>
                    )}
                  </div>
                </div>
              )}

              {sub.status === 'active' && !needsUpgrade(sub) && (
                <div className="border-t border-border/60 pt-4 flex gap-2">
                  <button
                    onClick={() => void handleCancel(sub.id)}
                    className="px-4 py-2 border border-border rounded-md text-sm hover:bg-muted"
                  >
                    Anuluj subskrypcję
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {upgradeModalOpen && selectedSubscription && (
        <SubscriptionUpgradeModal
          subscription={selectedSubscription}
          isOpen={upgradeModalOpen}
          onClose={closeUpgradeModal}
          onSuccess={() => {
            closeUpgradeModal()
            void fetchSubscriptions()
          }}
        />
      )}
    </div>
  )
}
