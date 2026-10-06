/**
 * Shared types for Monetization Edge Functions
 * Re-export from main types with adjustments for Edge Functions
 */

export type AppModule = 
  | 'admin'
  | 'cleaning'
  | 'maintenance'
  | 'home'
  | 'fleet'
  | 'developer_warranty';

export type SubscriptionStatus = 
  | 'active'
  | 'blocked_pending_payment'
  | 'expired'
  | 'cancelled'
  | 'suspended';

export type BillingInterval = 
  | 'monthly'
  | 'yearly'
  | 'one_time';

export type PaymentStatus = 
  | 'pending'
  | 'completed'
  | 'failed'
  | 'cancelled';

// Request types
export interface CalculatePriceRequest {
  plan_id: string;
  billing_interval: BillingInterval;
  community_id?: string;
  unit_count?: number;
}

export interface PurchaseSubscriptionRequest {
  plan_id: string;
  beneficiary_community_id?: string;
  billing_interval: BillingInterval;
  payment_method?: string;
  invoice_entity_community_id?: string;
}

export interface UpgradeSubscriptionRequest {
  subscription_id: string;
  payment_method?: string;
}

export interface CheckAccessRequest {
  org_id: string;
  community_id?: string;
  module: AppModule;
}

export interface GrantTrialRequest {
  org_id: string;
  community_id?: string;
  module: AppModule;
  duration_days?: number;
}

// Response types
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: any;
  };
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination?: {
    page: number;
    per_page: number;
    total: number;
    total_pages: number;
  };
}
