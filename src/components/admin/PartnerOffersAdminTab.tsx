import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../../lib/supabase'
import PartnerOffersSubTab from './PartnerOffersSubTab'
import VendorPartnersSubTab from './VendorPartnersSubTab'
import type { CleaningLocationRow, PartnerOfferRow, VendorPartnerRow } from './partnerOffersTypes'

type AdminPartnerOffersTab = 'offers' | 'vendors'

export default function PartnerOffersAdminTab() {
  const [offers, setOffers] = useState<PartnerOfferRow[]>([])
  const [partners, setPartners] = useState<VendorPartnerRow[]>([])
  const [locations, setLocations] = useState<CleaningLocationRow[]>([])
  const [interactionsCount, setInteractionsCount] = useState<number>(0)
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<AdminPartnerOffersTab>('offers')

  const loadAll = useCallback(async () => {
    setLoadError(null)
    try {
      const [offersRes, partnersRes, interactionsRes, locationsRes] = await Promise.all([
        supabase
          .from('partner_offers')
          .select(
            'id, title, description, vendor_id, billing_model, action_type, action_value, is_active, target_locations, icon_emoji, bg_color, image_url',
          )
          .order('title'),
        supabase.from('vendor_partners').select('id, name, service_type, contact_email, contact_phone, status').order('name'),
        supabase.from('offer_interactions').select('*', { count: 'exact', head: true }),
        supabase.from('cleaning_locations').select('id, city, address').order('city').order('address'),
      ])

      if (offersRes.error) {
        console.error('[PartnerOffersAdminTab] partner_offers:', offersRes.error)
        setLoadError('Nie udało się pobrać ofert partnerskich.')
        setOffers([])
      } else {
        setOffers((offersRes.data as PartnerOfferRow[] | null) ?? [])
      }

      if (partnersRes.error) {
        console.error('[PartnerOffersAdminTab] vendor_partners:', partnersRes.error)
        setLoadError((prev) => prev ?? 'Nie udało się pobrać listy partnerów.')
        setPartners([])
      } else {
        setPartners((partnersRes.data as VendorPartnerRow[] | null) ?? [])
      }

      if (interactionsRes.error) {
        console.error('[PartnerOffersAdminTab] offer_interactions count:', interactionsRes.error)
        setLoadError((prev) => prev ?? 'Nie udało się pobrać metryk interakcji.')
        setInteractionsCount(0)
      } else {
        setInteractionsCount(interactionsRes.count ?? 0)
      }

      if (locationsRes.error) {
        console.error('[PartnerOffersAdminTab] cleaning_locations:', locationsRes.error)
        setLoadError((prev) => prev ?? 'Nie udało się pobrać lokalizacji.')
        setLocations([])
      } else {
        setLocations((locationsRes.data as CleaningLocationRow[] | null) ?? [])
      }
    } catch (e) {
      console.error('[PartnerOffersAdminTab] loadAll:', e)
      setLoadError('Wystąpił nieoczekiwany błąd podczas ładowania danych ofert.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadAll()
  }, [loadAll])

  return (
    <div className="space-y-5">
      {loadError && (
        <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
          {loadError}
        </div>
      )}

      <div className="inline-flex p-1 rounded-xl bg-muted gap-1">
        <button
          type="button"
          onClick={() => setActiveTab('offers')}
          className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'offers' ? 'bg-background text-foreground shadow-sm' : 'text-muted-foreground hover:text-foreground'
          }`}
        >
          Lista Ofert
        </button>
        <button
          type="button"
          onClick={() => setActiveTab('vendors')}
          className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'vendors'
              ? 'bg-background text-foreground shadow-sm'
              : 'text-muted-foreground hover:text-foreground'
          }`}
        >
          Katalog Firm
        </button>
      </div>

      {activeTab === 'offers' && (
        <PartnerOffersSubTab
          offers={offers}
          partners={partners}
          locations={locations}
          interactionsCount={interactionsCount}
          loading={loading}
          onRefresh={loadAll}
        />
      )}

      {activeTab === 'vendors' && (
        <VendorPartnersSubTab
          vendors={partners}
          loading={loading}
          onRefresh={loadAll}
        />
      )}
    </div>
  )
}
