/**
 * Monetization Utilities
 * 
 * Helper functions for monetization calculations, formatting, and validation
 */

import {
  PricingPlan,
  ModuleSubscription,
  BillingInterval,
  SubscriptionStatus,
  AppModule
} from '../types/monetization';

// =========================================================================
// PRICE CALCULATIONS
// =========================================================================

/**
 * Oblicza cenę dla planu unit-based (client-side calculation)
 * Match server-side logic: MAX(min_price, price_per_unit * unit_count)
 */
export function calculateUnitBasedPrice(
  plan: PricingPlan,
  unitCount: number
): number {
  if (!plan.is_unit_based || !plan.price_per_unit || !plan.min_price) {
    throw new Error('Invalid unit-based plan');
  }

  if (unitCount < 0) {
    throw new Error('Unit count must be >= 0');
  }

  const basePrice = plan.price_per_unit * unitCount;
  return Math.max(plan.min_price, basePrice);
}

/**
 * Oblicza oszczędność przy planie rocznym
 */
export function calculateYearlySavings(plan: PricingPlan): number {
  if (plan.is_unit_based || !plan.price_monthly || !plan.price_yearly) {
    return 0;
  }

  const yearlyFromMonthly = plan.price_monthly * 12;
  return Math.max(0, yearlyFromMonthly - plan.price_yearly);
}

/**
 * Oblicza procent oszczędności przy planie rocznym
 */
export function calculateSavingsPercent(plan: PricingPlan): number {
  const savings = calculateYearlySavings(plan);
  if (savings === 0 || !plan.price_monthly) {
    return 0;
  }

  const yearlyFromMonthly = plan.price_monthly * 12;
  return Math.round((savings / yearlyFromMonthly) * 100);
}

/**
 * Oblicza kwotę upgrade'u dla subskrypcji
 */
export function calculateUpgradeAmount(
  subscription: ModuleSubscription,
  plan: PricingPlan,
  newUnitCount: number
): number {
  if (!plan.is_unit_based || !subscription.paid_unit_count) {
    return 0;
  }

  if (newUnitCount <= subscription.paid_unit_count) {
    return 0;
  }

  const newTotalPrice = calculateUnitBasedPrice(plan, newUnitCount);
  const upgradeAmount = newTotalPrice - subscription.amount_paid;

  return Math.max(0, upgradeAmount);
}

// =========================================================================
// DATE CALCULATIONS
// =========================================================================

/**
 * Oblicza liczbę dni do wygaśnięcia
 */
export function getDaysUntilExpiry(expiresAt: string | null): number | null {
  if (!expiresAt) {
    return null;
  }

  const now = new Date();
  const expires = new Date(expiresAt);
  const diffTime = expires.getTime() - now.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  return diffDays;
}

/**
 * Sprawdza czy data wygaśnięcia jest blisko
 */
export function isExpiringSoon(
  expiresAt: string | null,
  daysThreshold: number = 30
): boolean {
  const daysLeft = getDaysUntilExpiry(expiresAt);
  if (daysLeft === null) {
    return false;
  }

  return daysLeft > 0 && daysLeft <= daysThreshold;
}

/**
 * Oblicza nową datę wygaśnięcia po odnowieniu
 */
export function calculateNewExpiryDate(
  currentExpiresAt: string | null,
  billingInterval: BillingInterval
): string {
  const baseDate = currentExpiresAt && new Date(currentExpiresAt) > new Date()
    ? new Date(currentExpiresAt)
    : new Date();

  if (billingInterval === 'monthly') {
    baseDate.setMonth(baseDate.getMonth() + 1);
  } else if (billingInterval === 'yearly') {
    baseDate.setFullYear(baseDate.getFullYear() + 1);
  }

  return baseDate.toISOString();
}

// =========================================================================
// STATUS CHECKS
// =========================================================================

/**
 * Sprawdza czy subskrypcja jest aktywna (biorąc pod uwagę expires_at)
 */
export function isSubscriptionActive(subscription: ModuleSubscription): boolean {
  if (subscription.status !== 'active') {
    return false;
  }

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
export function isSubscriptionBlocked(subscription: ModuleSubscription): boolean {
  return subscription.status === 'blocked_pending_payment';
}

/**
 * Sprawdza czy subskrypcja wymaga upgrade'u
 */
export function needsUpgrade(subscription: ModuleSubscription): boolean {
  if (!subscription.paid_unit_count || !subscription.current_unit_count) {
    return false;
  }

  return subscription.current_unit_count > subscription.paid_unit_count;
}

/**
 * Zwraca najbardziej krytyczny status subskrypcji
 */
export function getSubscriptionHealthStatus(
  subscription: ModuleSubscription
): 'healthy' | 'expiring_soon' | 'blocked' | 'expired' | 'needs_upgrade' {
  if (isSubscriptionBlocked(subscription)) {
    return 'blocked';
  }

  if (needsUpgrade(subscription)) {
    return 'needs_upgrade';
  }

  if (subscription.status === 'expired') {
    return 'expired';
  }

  if (isExpiringSoon(subscription.expires_at, 7)) {
    return 'expiring_soon';
  }

  return 'healthy';
}

// =========================================================================
// FORMATTING
// =========================================================================

/**
 * Formatuje kwotę w PLN
 */
export function formatPrice(amount: number, currency: string = 'PLN'): string {
  return new Intl.NumberFormat('pl-PL', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount);
}

/**
 * Formatuje datę w formacie polskim
 */
export function formatDate(date: string | null): string {
  if (!date) {
    return 'Brak daty';
  }

  return new Date(date).toLocaleDateString('pl-PL', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
}

/**
 * Formatuje datę i czas w formacie polskim
 */
export function formatDateTime(date: string | null): string {
  if (!date) {
    return 'Brak daty';
  }

  return new Date(date).toLocaleString('pl-PL', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}

/**
 * Formatuje status subskrypcji (polskie etykiety)
 */
export function formatSubscriptionStatus(status: SubscriptionStatus): string {
  const labels: Record<SubscriptionStatus, string> = {
    active: 'Aktywna',
    blocked_pending_payment: 'Zablokowana - wymaga dopłaty',
    expired: 'Wygasła',
    cancelled: 'Anulowana',
    suspended: 'Zawieszona'
  };

  return labels[status] || status;
}

/**
 * Formatuje nazwę modułu
 */
export function formatModuleName(module: AppModule): string {
  const names: Record<AppModule, string> = {
    home: 'DOMIO Home',
    admin: 'Administracja',
    cleaning: 'Cleaning',
    maintenance: 'Serwis',
    fleet: 'Flota',
    developer_warranty: 'Usterki Deweloperskie'
  };

  return names[module] || module;
}

/**
 * Formatuje billing interval
 */
export function formatBillingInterval(interval: BillingInterval): string {
  const labels: Record<BillingInterval, string> = {
    monthly: 'Miesięczny',
    yearly: 'Roczny',
    one_time: 'Jednorazowy'
  };

  return labels[interval] || interval;
}

// =========================================================================
// VALIDATION
// =========================================================================

/**
 * Waliduje dane planu cenowego
 */
export function validatePricingPlan(plan: Partial<PricingPlan>): string[] {
  const errors: string[] = [];

  if (!plan.display_name || plan.display_name.trim().length === 0) {
    errors.push('Nazwa planu jest wymagana');
  }

  if (!plan.module) {
    errors.push('Moduł jest wymagany');
  }

  if (plan.is_unit_based) {
    if (!plan.price_per_unit || plan.price_per_unit <= 0) {
      errors.push('Cena za lokal musi być większa niż 0');
    }
    if (!plan.min_price || plan.min_price <= 0) {
      errors.push('Minimalna kwota musi być większa niż 0');
    }
  } else {
    if (!plan.price_monthly && !plan.price_yearly) {
      errors.push('Wymagana cena miesięczna lub roczna');
    }
  }

  if (plan.available_from && plan.available_until) {
    const from = new Date(plan.available_from);
    const until = new Date(plan.available_until);
    if (from > until) {
      errors.push('Data rozpoczęcia musi być wcześniejsza niż data zakończenia');
    }
  }

  return errors;
}

/**
 * Sprawdza czy plan jest dostępny w danym momencie
 */
export function isPlanAvailable(plan: PricingPlan, atDate?: Date): boolean {
  if (!plan.is_active) {
    return false;
  }

  const checkDate = atDate || new Date();

  if (plan.available_from) {
    const from = new Date(plan.available_from);
    if (checkDate < from) {
      return false;
    }
  }

  if (plan.available_until) {
    const until = new Date(plan.available_until);
    if (checkDate > until) {
      return false;
    }
  }

  return true;
}

// =========================================================================
// COMPARISON & SORTING
// =========================================================================

/**
 * Porównuje dwa plany według ceny (dla unit-based używa min_price)
 */
export function comparePlansByPrice(a: PricingPlan, b: PricingPlan): number {
  const priceA = a.is_unit_based ? (a.min_price || 0) : (a.price_monthly || 0);
  const priceB = b.is_unit_based ? (b.min_price || 0) : (b.price_monthly || 0);

  return priceA - priceB;
}

/**
 * Sortuje subskrypcje według priorytetu (blocked > expiring > active)
 */
export function sortSubscriptionsByPriority(
  a: ModuleSubscription,
  b: ModuleSubscription
): number {
  const priorityOrder: Record<SubscriptionStatus, number> = {
    blocked_pending_payment: 1,
    expired: 2,
    suspended: 3,
    active: 4,
    cancelled: 5
  };

  const priorityA = priorityOrder[a.status] || 99;
  const priorityB = priorityOrder[b.status] || 99;

  if (priorityA !== priorityB) {
    return priorityA - priorityB;
  }

  // Jeśli ten sam status, sortuj po dacie wygaśnięcia
  if (a.expires_at && b.expires_at) {
    return new Date(a.expires_at).getTime() - new Date(b.expires_at).getTime();
  }

  return 0;
}

// =========================================================================
// UI HELPERS
// =========================================================================

/**
 * Zwraca kolor CSS dla statusu subskrypcji
 */
export function getSubscriptionStatusColor(status: SubscriptionStatus): string {
  const colors: Record<SubscriptionStatus, string> = {
    active: 'green',
    blocked_pending_payment: 'red',
    expired: 'gray',
    cancelled: 'gray',
    suspended: 'orange'
  };

  return colors[status] || 'gray';
}

/**
 * Zwraca ikonę emoji dla statusu subskrypcji
 */
export function getSubscriptionStatusIcon(status: SubscriptionStatus): string {
  const icons: Record<SubscriptionStatus, string> = {
    active: '✅',
    blocked_pending_payment: '🚫',
    expired: '❌',
    cancelled: '⛔',
    suspended: '⏸️'
  };

  return icons[status] || '❓';
}

/**
 * Generuje opis statusu subskrypcji dla użytkownika
 */
export function getSubscriptionStatusDescription(
  subscription: ModuleSubscription
): string {
  if (isSubscriptionBlocked(subscription)) {
    return `Subskrypcja zablokowana. ${subscription.blocked_reason || 'Wymaga dopłaty.'}`;
  }

  if (needsUpgrade(subscription)) {
    return `Przekroczono limit lokali (${subscription.current_unit_count}/${subscription.paid_unit_count}). Wymagana dopłata.`;
  }

  if (subscription.status === 'expired') {
    return `Subskrypcja wygasła ${formatDate(subscription.expires_at)}. Odnów subskrypcję aby przywrócić dostęp.`;
  }

  const daysLeft = getDaysUntilExpiry(subscription.expires_at);
  if (daysLeft !== null && daysLeft <= 7 && daysLeft > 0) {
    return `Subskrypcja wygasa za ${daysLeft} dni. Rozważ odnowienie.`;
  }

  if (subscription.status === 'active') {
    if (subscription.expires_at) {
      return `Subskrypcja aktywna do ${formatDate(subscription.expires_at)}.`;
    }
    return 'Subskrypcja aktywna.';
  }

  return formatSubscriptionStatus(subscription.status);
}

// =========================================================================
// URL HELPERS
// =========================================================================

/**
 * Generuje URL do zarządzania subskrypcją
 */
export function getSubscriptionManagementUrl(subscriptionId: string): string {
  return `/subscriptions/${subscriptionId}`;
}

/**
 * Generuje URL do zakupu modułu
 */
export function getPurchaseUrl(module: AppModule): string {
  return `/subscriptions/purchase?module=${module}`;
}

/**
 * Generuje URL do upgrade'u subskrypcji
 */
export function getUpgradeUrl(subscriptionId: string): string {
  return `/subscriptions/${subscriptionId}/upgrade`;
}

/**
 * Generuje URL do odnowienia subskrypcji
 */
export function getRenewalUrl(subscriptionId: string): string {
  return `/subscriptions/${subscriptionId}/renew`;
}
