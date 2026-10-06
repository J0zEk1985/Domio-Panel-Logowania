/**
 * SubscriptionService - Zarządzanie Subskrypcjami
 * 
 * Odpowiedzialność:
 * - CRUD operacje na module_subscriptions
 * - Zarządzanie cyklem życia subskrypcji
 * - Blokowanie/odblokowanie subskrypcji
 * - Odnowienia i upgrade'y
 * - Sprawdzanie statusu i dostępu
 */

import { SupabaseClient } from '@supabase/supabase-js';
import {
  ModuleSubscription,
  CreateSubscriptionInput,
  SubscriptionStatus,
  AppModule,
  SubscriptionEvent,
  SubscriptionEventType
} from '../../types/monetization';

export interface SubscriptionFilters {
  purchaser_org_id?: string;
  beneficiary_community_id?: string;
  module?: AppModule;
  status?: SubscriptionStatus;
  includeExpired?: boolean;
}

export interface SubscriptionWithDetails extends ModuleSubscription {
  plan?: any; // pricing_plan
  community?: any; // community
  org?: any; // organization
}

export class SubscriptionService {
  constructor(private supabase: SupabaseClient) {}

  // =========================================================================
  // PUBLIC METHODS - Query Operations
  // =========================================================================

  /**
   * Pobiera subskrypcje według filtrów
   */
  async getSubscriptions(
    filters: SubscriptionFilters = {}
  ): Promise<ModuleSubscription[]> {
    let query = this.supabase
      .from('module_subscriptions')
      .select('*')
      .order('created_at', { ascending: false });

    if (filters.purchaser_org_id) {
      query = query.eq('purchaser_org_id', filters.purchaser_org_id);
    }

    if (filters.beneficiary_community_id) {
      query = query.eq('beneficiary_community_id', filters.beneficiary_community_id);
    }

    if (filters.module) {
      query = query.eq('module', filters.module);
    }

    if (filters.status) {
      query = query.eq('status', filters.status);
    }

    if (!filters.includeExpired) {
      query = query.neq('status', 'expired' as SubscriptionStatus);
    }

    const { data, error } = await query;

    if (error) {
      throw new Error(`Failed to fetch subscriptions: ${error.message}`);
    }

    return data || [];
  }

  /**
   * Pobiera subskrypcję po ID
   */
  async getSubscriptionById(subscriptionId: string): Promise<ModuleSubscription | null> {
    const { data, error } = await this.supabase
      .from('module_subscriptions')
      .select('*')
      .eq('id', subscriptionId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return null; // Not found
      }
      throw new Error(`Failed to fetch subscription: ${error.message}`);
    }

    return data;
  }

  /**
   * Pobiera subskrypcję z pełnymi szczegółami (joins)
   */
  async getSubscriptionWithDetails(
    subscriptionId: string
  ): Promise<SubscriptionWithDetails | null> {
    const { data, error } = await this.supabase
      .from('module_subscriptions')
      .select(`
        *,
        plan:module_pricing_plans(*),
        community:communities(*),
        org:organizations(*)
      `)
      .eq('id', subscriptionId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return null;
      }
      throw new Error(`Failed to fetch subscription details: ${error.message}`);
    }

    return data;
  }

  /**
   * Pobiera aktywne subskrypcje dla org
   */
  async getActiveSubscriptionsForOrg(orgId: string): Promise<ModuleSubscription[]> {
    return this.getSubscriptions({
      purchaser_org_id: orgId,
      status: 'active'
    });
  }

  /**
   * Pobiera aktywne subskrypcje dla community
   */
  async getActiveSubscriptionsForCommunity(
    communityId: string
  ): Promise<ModuleSubscription[]> {
    return this.getSubscriptions({
      beneficiary_community_id: communityId,
      status: 'active'
    });
  }

  /**
   * Pobiera subskrypcje zbliżające się do wygaśnięcia
   */
  async getExpiringSoon(daysThreshold: number = 30): Promise<ModuleSubscription[]> {
    const thresholdDate = new Date();
    thresholdDate.setDate(thresholdDate.getDate() + daysThreshold);

    const { data, error } = await this.supabase
      .from('module_subscriptions')
      .select('*')
      .eq('status', 'active' as SubscriptionStatus)
      .not('expires_at', 'is', null)
      .lte('expires_at', thresholdDate.toISOString())
      .order('expires_at', { ascending: true });

    if (error) {
      throw new Error(`Failed to fetch expiring subscriptions: ${error.message}`);
    }

    return data || [];
  }

  // =========================================================================
  // PUBLIC METHODS - Lifecycle Management
  // =========================================================================

  /**
   * Tworzy nową subskrypcję
   */
  async createSubscription(input: CreateSubscriptionInput): Promise<ModuleSubscription> {
    // Walidacja
    this.validateSubscriptionInput(input);

    const { data, error } = await this.supabase
      .from('module_subscriptions')
      .insert({
        purchaser_org_id: input.purchaser_org_id,
        beneficiary_community_id: input.beneficiary_community_id || null,
        invoice_entity_community_id: input.invoice_entity_community_id || null,
        plan_id: input.plan_id,
        module: input.module,
        status: 'active', // Domyślnie aktywna po utworzeniu
        billing_interval: input.billing_interval,
        amount_paid: input.amount_paid,
        paid_unit_count: input.paid_unit_count || null,
        expires_at: input.expires_at || null,
        purchase_metadata: input.purchase_metadata || {}
      })
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create subscription: ${error.message}`);
    }

    return data;
  }

  /**
   * Aktywuje subskrypcję (jeśli była zawieszona)
   */
  async activateSubscription(subscriptionId: string): Promise<ModuleSubscription> {
    const subscription = await this.getSubscriptionById(subscriptionId);
    if (!subscription) {
      throw new Error('Subscription not found');
    }

    if (subscription.status === 'active') {
      return subscription; // Already active
    }

    const { data, error } = await this.supabase
      .from('module_subscriptions')
      .update({
        status: 'active' as SubscriptionStatus,
        activated_at: new Date().toISOString()
      })
      .eq('id', subscriptionId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to activate subscription: ${error.message}`);
    }

    return data;
  }

  /**
   * Zawiesza subskrypcję (admin action)
   */
  async suspendSubscription(subscriptionId: string): Promise<ModuleSubscription> {
    const { data, error } = await this.supabase
      .from('module_subscriptions')
      .update({
        status: 'suspended' as SubscriptionStatus
      })
      .eq('id', subscriptionId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to suspend subscription: ${error.message}`);
    }

    return data;
  }

  /**
   * Anuluje subskrypcję
   */
  async cancelSubscription(subscriptionId: string): Promise<ModuleSubscription> {
    const { data, error } = await this.supabase
      .from('module_subscriptions')
      .update({
        status: 'cancelled' as SubscriptionStatus,
        cancelled_at: new Date().toISOString()
      })
      .eq('id', subscriptionId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to cancel subscription: ${error.message}`);
    }

    return data;
  }

  /**
   * Odblokuje subskrypcję po dopłacie
   */
  async unblockSubscription(
    subscriptionId: string,
    newPaidUnitCount: number,
    additionalPayment: number
  ): Promise<ModuleSubscription> {
    const subscription = await this.getSubscriptionById(subscriptionId);
    if (!subscription) {
      throw new Error('Subscription not found');
    }

    if (subscription.status !== 'blocked_pending_payment') {
      throw new Error('Subscription is not blocked');
    }

    if (newPaidUnitCount <= (subscription.paid_unit_count || 0)) {
      throw new Error('New unit count must be greater than current paid count');
    }

    const { data, error } = await this.supabase
      .from('module_subscriptions')
      .update({
        status: 'active' as SubscriptionStatus,
        paid_unit_count: newPaidUnitCount,
        amount_paid: subscription.amount_paid + additionalPayment,
        blocked_at: null,
        blocked_reason: null,
        purchase_metadata: {
          ...subscription.purchase_metadata,
          upgrade_history: [
            ...(subscription.purchase_metadata.upgrade_history || []),
            {
              from_units: subscription.paid_unit_count,
              to_units: newPaidUnitCount,
              additional_payment: additionalPayment,
              upgraded_at: new Date().toISOString()
            }
          ]
        }
      })
      .eq('id', subscriptionId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to unblock subscription: ${error.message}`);
    }

    // Odtwórz access grant
    await this.restoreAccessGrant(subscriptionId);

    return data;
  }

  /**
   * Odnawia subskrypcję (renewal)
   */
  async renewSubscription(
    subscriptionId: string,
    newExpiresAt: string,
    amountPaid: number
  ): Promise<ModuleSubscription> {
    const subscription = await this.getSubscriptionById(subscriptionId);
    if (!subscription) {
      throw new Error('Subscription not found');
    }

    const { data, error } = await this.supabase
      .from('module_subscriptions')
      .update({
        status: 'active' as SubscriptionStatus,
        expires_at: newExpiresAt,
        amount_paid: subscription.amount_paid + amountPaid,
        purchase_metadata: {
          ...subscription.purchase_metadata,
          renewal_history: [
            ...(subscription.purchase_metadata.renewal_history || []),
            {
              previous_expires_at: subscription.expires_at,
              new_expires_at: newExpiresAt,
              amount_paid: amountPaid,
              renewed_at: new Date().toISOString()
            }
          ]
        }
      })
      .eq('id', subscriptionId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to renew subscription: ${error.message}`);
    }

    return data;
  }

  // =========================================================================
  // PUBLIC METHODS - Status Checks
  // =========================================================================

  /**
   * Sprawdza czy subskrypcja jest aktywna
   */
  isActive(subscription: ModuleSubscription): boolean {
    if (subscription.status !== 'active') {
      return false;
    }

    // Sprawdź czy nie wygasła
    if (subscription.expires_at) {
      const now = new Date();
      const expires = new Date(subscription.expires_at);
      if (now > expires) {
        return false;
      }
    }

    return true;
  }

  /**
   * Sprawdza czy subskrypcja jest zablokowana
   */
  isBlocked(subscription: ModuleSubscription): boolean {
    return subscription.status === 'blocked_pending_payment';
  }

  /**
   * Sprawdza czy subskrypcja wymaga upgrade'u (przekroczono limitu lokali)
   */
  needsUpgrade(subscription: ModuleSubscription): boolean {
    if (!subscription.paid_unit_count || !subscription.current_unit_count) {
      return false;
    }

    return subscription.current_unit_count > subscription.paid_unit_count;
  }

  /**
   * Zwraca liczbę dni do wygaśnięcia
   */
  getDaysUntilExpiry(subscription: ModuleSubscription): number | null {
    if (!subscription.expires_at) {
      return null;
    }

    const now = new Date();
    const expires = new Date(subscription.expires_at);
    const diffTime = expires.getTime() - now.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    return diffDays;
  }

  /**
   * Sprawdza czy subskrypcja wygasa wkrótce
   */
  isExpiringSoon(subscription: ModuleSubscription, daysThreshold: number = 30): boolean {
    const daysLeft = this.getDaysUntilExpiry(subscription);
    if (daysLeft === null) {
      return false;
    }

    return daysLeft > 0 && daysLeft <= daysThreshold;
  }

  // =========================================================================
  // PUBLIC METHODS - Events & Audit
  // =========================================================================

  /**
   * Pobiera historię zdarzeń dla subskrypcji
   */
  async getSubscriptionEvents(subscriptionId: string): Promise<SubscriptionEvent[]> {
    const { data, error } = await this.supabase
      .from('subscription_events')
      .select('*')
      .eq('subscription_id', subscriptionId)
      .order('triggered_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch subscription events: ${error.message}`);
    }

    return data || [];
  }

  /**
   * Loguje zdarzenie subskrypcji (manual event logging)
   */
  async logEvent(
    subscriptionId: string,
    eventType: SubscriptionEventType,
    eventData: Record<string, any> = {}
  ): Promise<void> {
    const { error } = await this.supabase
      .from('subscription_events')
      .insert({
        subscription_id: subscriptionId,
        event_type: eventType,
        event_data: eventData
      });

    if (error) {
      // Don't throw - logging failure shouldn't break the flow
      console.error('Failed to log subscription event:', error);
    }
  }

  // =========================================================================
  // PUBLIC METHODS - Statistics
  // =========================================================================

  /**
   * Zwraca statystyki subskrypcji dla org
   */
  async getOrgSubscriptionStats(orgId: string): Promise<{
    total: number;
    active: number;
    blocked: number;
    expiring_soon: number;
    by_module: Record<AppModule, number>;
  }> {
    const subscriptions = await this.getSubscriptions({
      purchaser_org_id: orgId,
      includeExpired: false
    });

    const stats = {
      total: subscriptions.length,
      active: 0,
      blocked: 0,
      expiring_soon: 0,
      by_module: {} as Record<AppModule, number>
    };

    subscriptions.forEach(sub => {
      if (this.isActive(sub)) {
        stats.active++;
      }

      if (this.isBlocked(sub)) {
        stats.blocked++;
      }

      if (this.isExpiringSoon(sub)) {
        stats.expiring_soon++;
      }

      stats.by_module[sub.module] = (stats.by_module[sub.module] || 0) + 1;
    });

    return stats;
  }

  // =========================================================================
  // PRIVATE METHODS
  // =========================================================================

  private validateSubscriptionInput(input: CreateSubscriptionInput): void {
    if (!input.purchaser_org_id) {
      throw new Error('purchaser_org_id is required');
    }

    if (!input.plan_id) {
      throw new Error('plan_id is required');
    }

    if (!input.module) {
      throw new Error('module is required');
    }

    if (!input.billing_interval) {
      throw new Error('billing_interval is required');
    }

    if (input.amount_paid < 0) {
      throw new Error('amount_paid must be >= 0');
    }

    if (input.paid_unit_count !== undefined && input.paid_unit_count < 0) {
      throw new Error('paid_unit_count must be >= 0');
    }

    // Walidacja dat
    if (input.expires_at) {
      const expires = new Date(input.expires_at);
      const now = new Date();
      if (expires < now) {
        throw new Error('expires_at cannot be in the past');
      }
    }
  }

  private async restoreAccessGrant(subscriptionId: string): Promise<void> {
    const subscription = await this.getSubscriptionById(subscriptionId);
    if (!subscription) {
      return;
    }

    // Update istniejącego grantu lub stwórz nowy
    const { error } = await this.supabase
      .from('module_access_grants')
      .update({
        is_granted: true,
        revoked_at: null
      })
      .eq('granted_by_subscription_id', subscriptionId);

    if (error) {
      console.error('Failed to restore access grant:', error);
    }
  }

  // =========================================================================
  // BATCH OPERATIONS
  // =========================================================================

  /**
   * Wygasza wszystkie subskrypcje, które przekroczyły expires_at
   */
  async expireOutdatedSubscriptions(): Promise<number> {
    const now = new Date().toISOString();

    const { data, error } = await this.supabase
      .from('module_subscriptions')
      .update({
        status: 'expired' as SubscriptionStatus
      })
      .eq('status', 'active' as SubscriptionStatus)
      .not('expires_at', 'is', null)
      .lt('expires_at', now)
      .select('id');

    if (error) {
      throw new Error(`Failed to expire subscriptions: ${error.message}`);
    }

    return (data || []).length;
  }
}

// =========================================================================
// FACTORY FUNCTION
// =========================================================================

export function createSubscriptionService(supabase: SupabaseClient): SubscriptionService {
  return new SubscriptionService(supabase);
}
