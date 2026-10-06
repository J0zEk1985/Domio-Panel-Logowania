/**
 * AccessControlService - Kontrola Dostępu do Modułów
 * 
 * Odpowiedzialność:
 * - Sprawdzanie dostępu do modułów (fast checks)
 * - Zarządzanie module_access_grants
 * - Manualne nadawanie dostępu (trial, promocje)
 * - Cache dla wydajności
 */

import { SupabaseClient } from '@supabase/supabase-js';
import {
  ModuleAccessGrant,
  AppModule,
  CheckAccessInput,
  CheckAccessResult
} from '../../types/monetization';

export interface ManualGrantInput {
  org_id: string;
  community_id?: string;
  module: AppModule;
  reason: string;
  expires_at?: string;
  granted_by: string; // User ID
}

export class AccessControlService {
  // In-memory cache dla szybkich sprawdzeń
  private accessCache: Map<string, { has_access: boolean; expires_at: number }> = new Map();
  private readonly CACHE_TTL_MS = 60000; // 1 minuta

  constructor(private supabase: SupabaseClient) {}

  // =========================================================================
  // PUBLIC METHODS - Access Checks
  // =========================================================================

  /**
   * Sprawdza czy org/community ma dostęp do modułu (z cache)
   */
  async hasAccess(input: CheckAccessInput): Promise<CheckAccessResult> {
    const cacheKey = this.getCacheKey(input);

    // Sprawdź cache
    const cached = this.accessCache.get(cacheKey);
    if (cached && Date.now() < cached.expires_at) {
      return {
        has_access: cached.has_access
      };
    }

    // Wywołaj funkcję bazodanową
    const { data, error } = await this.supabase.rpc('has_module_access', {
      p_org_id: input.org_id,
      p_community_id: input.community_id || null,
      p_module: input.module
    });

    if (error) {
      throw new Error(`Failed to check access: ${error.message}`);
    }

    const hasAccess = Boolean(data);

    // Cache result
    this.accessCache.set(cacheKey, {
      has_access: hasAccess,
      expires_at: Date.now() + this.CACHE_TTL_MS
    });

    // Pobierz szczegóły grantu jeśli ma dostęp
    let grant: ModuleAccessGrant | undefined;
    if (hasAccess) {
      const fetchedGrant = await this.getActiveGrant(input);
      grant = fetchedGrant ?? undefined;
    }

    return {
      has_access: hasAccess,
      grant,
      reason: hasAccess ? undefined : 'No active subscription or grant found'
    };
  }

  /**
   * Sprawdza dostęp dla wielu modułów naraz
   */
  async checkMultipleModules(
    orgId: string,
    communityId: string | undefined,
    modules: AppModule[]
  ): Promise<Record<AppModule, boolean>> {
    const results: Record<AppModule, boolean> = {} as any;

    await Promise.all(
      modules.map(async (module) => {
        const result = await this.hasAccess({
          org_id: orgId,
          community_id: communityId,
          module
        });
        results[module] = result.has_access;
      })
    );

    return results;
  }

  /**
   * Inwaliduje cache dla danego klucza
   */
  invalidateCache(input: CheckAccessInput): void {
    const cacheKey = this.getCacheKey(input);
    this.accessCache.delete(cacheKey);
  }

  /**
   * Czyści cały cache
   */
  clearCache(): void {
    this.accessCache.clear();
  }

  // =========================================================================
  // PUBLIC METHODS - Grant Management
  // =========================================================================

  /**
   * Pobiera aktywny grant dostępu
   */
  async getActiveGrant(input: CheckAccessInput): Promise<ModuleAccessGrant | null> {
    let query = this.supabase
      .from('module_access_grants')
      .select('*')
      .eq('org_id', input.org_id)
      .eq('module', input.module)
      .eq('is_granted', true)
      .is('revoked_at', null);

    if (input.community_id) {
      query = query.eq('community_id', input.community_id);
    } else {
      query = query.is('community_id', null);
    }

    const { data, error } = await query.single();

    if (error) {
      if (error.code === 'PGRST116') {
        return null; // Not found
      }
      throw new Error(`Failed to fetch grant: ${error.message}`);
    }

    // Sprawdź czy nie wygasł
    if (data.expires_at) {
      const now = new Date();
      const expires = new Date(data.expires_at);
      if (now > expires) {
        return null;
      }
    }

    return data;
  }

  /**
   * Pobiera wszystkie granty dla org
   */
  async getOrgGrants(orgId: string): Promise<ModuleAccessGrant[]> {
    const { data, error } = await this.supabase
      .from('module_access_grants')
      .select('*')
      .eq('org_id', orgId)
      .eq('is_granted', true)
      .is('revoked_at', null)
      .order('granted_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch org grants: ${error.message}`);
    }

    return data || [];
  }

  /**
   * Pobiera wszystkie granty dla community
   */
  async getCommunityGrants(communityId: string): Promise<ModuleAccessGrant[]> {
    const { data, error } = await this.supabase
      .from('module_access_grants')
      .select('*')
      .eq('community_id', communityId)
      .eq('is_granted', true)
      .is('revoked_at', null)
      .order('granted_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch community grants: ${error.message}`);
    }

    return data || [];
  }

  // =========================================================================
  // PUBLIC METHODS - Manual Grants (Trial, Promotions, Special Deals)
  // =========================================================================

  /**
   * Manualnie nadaje dostęp do modułu (np. trial, promocja)
   */
  async grantManualAccess(input: ManualGrantInput): Promise<ModuleAccessGrant> {
    this.validateManualGrantInput(input);

    const { data, error } = await this.supabase
      .from('module_access_grants')
      .insert({
        org_id: input.org_id,
        community_id: input.community_id || null,
        module: input.module,
        is_granted: true,
        granted_by_subscription_id: null,
        is_manual_grant: true,
        manual_grant_reason: input.reason,
        manual_granted_by: input.granted_by,
        granted_at: new Date().toISOString(),
        expires_at: input.expires_at || null
      })
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to grant manual access: ${error.message}`);
    }

    // Inwaliduj cache
    this.invalidateCache({
      org_id: input.org_id,
      community_id: input.community_id,
      module: input.module
    });

    return data;
  }

  /**
   * Odbiera manualne nadanie dostępu
   */
  async revokeManualGrant(grantId: string): Promise<void> {
    const grant = await this.getGrantById(grantId);
    if (!grant) {
      throw new Error('Grant not found');
    }

    if (!grant.is_manual_grant) {
      throw new Error('Cannot revoke non-manual grant. Cancel the subscription instead.');
    }

    const { error } = await this.supabase
      .from('module_access_grants')
      .update({
        is_granted: false,
        revoked_at: new Date().toISOString()
      })
      .eq('id', grantId);

    if (error) {
      throw new Error(`Failed to revoke grant: ${error.message}`);
    }

    // Inwaliduj cache
    this.invalidateCache({
      org_id: grant.org_id,
      community_id: grant.community_id || undefined,
      module: grant.module
    });
  }

  /**
   * Przedłuża ważność manualnego grantu
   */
  async extendManualGrant(
    grantId: string,
    newExpiresAt: string
  ): Promise<ModuleAccessGrant> {
    const grant = await this.getGrantById(grantId);
    if (!grant) {
      throw new Error('Grant not found');
    }

    if (!grant.is_manual_grant) {
      throw new Error('Cannot extend non-manual grant');
    }

    const { data, error } = await this.supabase
      .from('module_access_grants')
      .update({
        expires_at: newExpiresAt
      })
      .eq('id', grantId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to extend grant: ${error.message}`);
    }

    // Inwaliduj cache
    this.invalidateCache({
      org_id: grant.org_id,
      community_id: grant.community_id || undefined,
      module: grant.module
    });

    return data;
  }

  // =========================================================================
  // PUBLIC METHODS - Trial Management
  // =========================================================================

  /**
   * Tworzy trial dostęp do modułu (7 dni)
   */
  async createTrial(
    orgId: string,
    communityId: string | undefined,
    module: AppModule,
    grantedBy: string,
    durationDays: number = 7
  ): Promise<ModuleAccessGrant> {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + durationDays);

    return this.grantManualAccess({
      org_id: orgId,
      community_id: communityId,
      module,
      reason: `Trial period: ${durationDays} days`,
      expires_at: expiresAt.toISOString(),
      granted_by: grantedBy
    });
  }

  /**
   * Sprawdza czy org ma aktywny trial dla modułu
   */
  async hasActiveTrial(
    orgId: string,
    module: AppModule,
    communityId?: string
  ): Promise<boolean> {
    const grant = await this.getActiveGrant({
      org_id: orgId,
      community_id: communityId,
      module
    });

    if (!grant || !grant.is_manual_grant) {
      return false;
    }

    return grant.manual_grant_reason?.toLowerCase().includes('trial') || false;
  }

  // =========================================================================
  // PUBLIC METHODS - Utilities
  // =========================================================================

  /**
   * Pobiera moduły dostępne dla org
   */
  async getAvailableModules(
    orgId: string,
    communityId?: string
  ): Promise<AppModule[]> {
    const grants = communityId
      ? await this.getCommunityGrants(communityId)
      : await this.getOrgGrants(orgId);

    return grants
      .filter(g => this.isGrantValid(g))
      .map(g => g.module);
  }

  /**
   * Sprawdza czy grant jest jeszcze ważny
   */
  isGrantValid(grant: ModuleAccessGrant): boolean {
    if (!grant.is_granted || grant.revoked_at) {
      return false;
    }

    if (grant.expires_at) {
      const now = new Date();
      const expires = new Date(grant.expires_at);
      if (now > expires) {
        return false;
      }
    }

    return true;
  }

  /**
   * Zwraca liczbę dni do wygaśnięcia grantu
   */
  getDaysUntilExpiry(grant: ModuleAccessGrant): number | null {
    if (!grant.expires_at) {
      return null;
    }

    const now = new Date();
    const expires = new Date(grant.expires_at);
    const diffTime = expires.getTime() - now.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    return diffDays;
  }

  // =========================================================================
  // PRIVATE METHODS
  // =========================================================================

  private getCacheKey(input: CheckAccessInput): string {
    return `${input.org_id}:${input.community_id || 'null'}:${input.module}`;
  }

  private async getGrantById(grantId: string): Promise<ModuleAccessGrant | null> {
    const { data, error } = await this.supabase
      .from('module_access_grants')
      .select('*')
      .eq('id', grantId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return null;
      }
      throw new Error(`Failed to fetch grant: ${error.message}`);
    }

    return data;
  }

  private validateManualGrantInput(input: ManualGrantInput): void {
    if (!input.org_id) {
      throw new Error('org_id is required');
    }

    if (!input.module) {
      throw new Error('module is required');
    }

    if (!input.reason || input.reason.trim().length === 0) {
      throw new Error('reason is required for manual grants');
    }

    if (!input.granted_by) {
      throw new Error('granted_by is required');
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

  // =========================================================================
  // BATCH OPERATIONS
  // =========================================================================

  /**
   * Usuwa wygasłe granty (cleanup job)
   */
  async revokeExpiredGrants(): Promise<number> {
    const now = new Date().toISOString();

    const { data, error } = await this.supabase
      .from('module_access_grants')
      .update({
        is_granted: false,
        revoked_at: now
      })
      .eq('is_granted', true)
      .is('revoked_at', null)
      .not('expires_at', 'is', null)
      .lt('expires_at', now)
      .select('id');

    if (error) {
      throw new Error(`Failed to revoke expired grants: ${error.message}`);
    }

    // Wyczyść cache po batch operacji
    this.clearCache();

    return (data || []).length;
  }
}

// =========================================================================
// FACTORY FUNCTION
// =========================================================================

export function createAccessControlService(supabase: SupabaseClient): AccessControlService {
  return new AccessControlService(supabase);
}
