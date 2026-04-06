export type BillingModel = 'subscription' | 'commission'
export type ActionType = 'url' | 'code' | 'lead'

export type PartnerOfferRow = {
  id: string
  title: string
  description: string | null
  vendor_id: string
  billing_model: BillingModel
  action_type: ActionType
  action_value: string | null
  is_active: boolean
  target_locations: string[] | null
  icon_emoji: string | null
  bg_color: string | null
  image_url: string | null
  promote_on_board: boolean | null
}

export type VendorPartnerRow = {
  id: string
  name: string
  service_type: string | null
  contact_email: string | null
  contact_phone: string | null
  status: string | null
}

export type CleaningLocationRow = {
  id: string
  city: string | null
  address: string | null
}

