/**
 * NotificationService - System Powiadomień Subskrypcji
 * 
 * Odpowiedzialność:
 * - Powiadomienia o blokadach subskrypcji
 * - Powiadomienia o zbliżającym się wygaśnięciu
 * - Powiadomienia o upgrade'ach
 * - Integracja z systemem e-mail i push notifications
 */

import { SupabaseClient } from '@supabase/supabase-js';
import {
  ModuleSubscription,
  AppModule
} from '../../types/monetization';

export interface NotificationRecipient {
  user_id: string;
  email: string;
  full_name?: string;
}

export interface NotificationPayload {
  type: NotificationTemplateType;
  subject: string;
  body: string;
  data: Record<string, any>;
  priority: 'low' | 'normal' | 'high' | 'urgent';
}

export type NotificationTemplateType = 
  | 'subscription_blocked'
  | 'subscription_expiring'
  | 'subscription_expired'
  | 'subscription_renewed'
  | 'subscription_upgraded'
  | 'trial_ending'
  | 'payment_required';

export interface NotificationTemplate {
  type: NotificationTemplateType;
  subject: (data: any) => string;
  body: (data: any) => string;
  priority: NotificationPayload['priority'];
}

export class NotificationService {
  // Szablony powiadomień w języku polskim
  private templates: Map<NotificationTemplateType, NotificationTemplate>;

  constructor(private supabase: SupabaseClient) {
    this.templates = this.initializeTemplates();
  }

  // =========================================================================
  // PUBLIC METHODS - Subscription Events
  // =========================================================================

  /**
   * Powiadamia o zablokowaniu subskrypcji (przekroczenie limitu lokali)
   */
  async notifySubscriptionBlocked(
    subscription: ModuleSubscription,
    reason: string
  ): Promise<void> {
    const recipients = await this.getOrgAdmins(subscription.purchaser_org_id);

    const payload = this.createNotification('subscription_blocked', {
      subscription_id: subscription.id,
      module: subscription.module,
      reason,
      paid_unit_count: subscription.paid_unit_count,
      current_unit_count: subscription.current_unit_count,
      upgrade_required: true
    });

    await this.sendToRecipients(recipients, payload);
  }

  /**
   * Powiadamia o zbliżającym się wygaśnięciu subskrypcji
   */
  async notifySubscriptionExpiring(
    subscription: ModuleSubscription,
    daysLeft: number
  ): Promise<void> {
    const recipients = await this.getOrgAdmins(subscription.purchaser_org_id);

    const payload = this.createNotification('subscription_expiring', {
      subscription_id: subscription.id,
      module: subscription.module,
      days_left: daysLeft,
      expires_at: subscription.expires_at,
      renewal_url: this.getRenewalUrl(subscription.id)
    });

    await this.sendToRecipients(recipients, payload);
  }

  /**
   * Powiadamia o wygaśnięciu subskrypcji
   */
  async notifySubscriptionExpired(subscription: ModuleSubscription): Promise<void> {
    const recipients = await this.getOrgAdmins(subscription.purchaser_org_id);

    const payload = this.createNotification('subscription_expired', {
      subscription_id: subscription.id,
      module: subscription.module,
      expired_at: subscription.expires_at,
      renewal_url: this.getRenewalUrl(subscription.id)
    });

    await this.sendToRecipients(recipients, payload);
  }

  /**
   * Powiadamia o pomyślnym odnowieniu subskrypcji
   */
  async notifySubscriptionRenewed(subscription: ModuleSubscription): Promise<void> {
    const recipients = await this.getOrgAdmins(subscription.purchaser_org_id);

    const payload = this.createNotification('subscription_renewed', {
      subscription_id: subscription.id,
      module: subscription.module,
      new_expires_at: subscription.expires_at,
      amount_paid: subscription.amount_paid
    });

    await this.sendToRecipients(recipients, payload);
  }

  /**
   * Powiadamia o upgrade'zie subskrypcji
   */
  async notifySubscriptionUpgraded(
    subscription: ModuleSubscription,
    oldUnitCount: number,
    newUnitCount: number,
    additionalPayment: number
  ): Promise<void> {
    const recipients = await this.getOrgAdmins(subscription.purchaser_org_id);

    const payload = this.createNotification('subscription_upgraded', {
      subscription_id: subscription.id,
      module: subscription.module,
      old_unit_count: oldUnitCount,
      new_unit_count: newUnitCount,
      additional_payment: additionalPayment
    });

    await this.sendToRecipients(recipients, payload);
  }

  /**
   * Powiadamia o zbliżającym się końcu trial
   */
  async notifyTrialEnding(
    orgId: string,
    module: AppModule,
    daysLeft: number
  ): Promise<void> {
    const recipients = await this.getOrgAdmins(orgId);

    const payload = this.createNotification('trial_ending', {
      module,
      days_left: daysLeft,
      purchase_url: this.getPurchaseUrl(module)
    });

    await this.sendToRecipients(recipients, payload);
  }

  /**
   * Powiadamia o wymaganej płatności
   */
  async notifyPaymentRequired(
    subscription: ModuleSubscription,
    amount: number,
    reason: string
  ): Promise<void> {
    const recipients = await this.getOrgAdmins(subscription.purchaser_org_id);

    const payload = this.createNotification('payment_required', {
      subscription_id: subscription.id,
      module: subscription.module,
      amount,
      reason,
      payment_url: this.getPaymentUrl(subscription.id)
    });

    await this.sendToRecipients(recipients, payload);
  }

  // =========================================================================
  // PUBLIC METHODS - Batch Notifications
  // =========================================================================

  /**
   * Wysyła powiadomienia o zbliżającym się wygaśnięciu dla wszystkich subskrypcji
   */
  async sendExpiryReminders(daysThreshold: number = 7): Promise<number> {
    const thresholdDate = new Date();
    thresholdDate.setDate(thresholdDate.getDate() + daysThreshold);

    const { data, error } = await this.supabase
      .from('module_subscriptions')
      .select('*')
      .eq('status', 'active')
      .not('expires_at', 'is', null)
      .lte('expires_at', thresholdDate.toISOString())
      .gte('expires_at', new Date().toISOString());

    if (error) {
      console.error('Failed to fetch expiring subscriptions:', error);
      return 0;
    }

    let count = 0;
    for (const subscription of data || []) {
      try {
        const daysLeft = this.calculateDaysLeft(subscription.expires_at!);
        await this.notifySubscriptionExpiring(subscription, daysLeft);
        count++;
      } catch (error) {
        console.error(`Failed to send expiry reminder for subscription ${subscription.id}:`, error);
      }
    }

    return count;
  }

  // =========================================================================
  // PRIVATE METHODS - Notification Creation
  // =========================================================================

  private createNotification(
    type: NotificationTemplateType,
    data: Record<string, any>
  ): NotificationPayload {
    const template = this.templates.get(type);
    if (!template) {
      throw new Error(`Unknown notification template: ${type}`);
    }

    return {
      type,
      subject: template.subject(data),
      body: template.body(data),
      data,
      priority: template.priority
    };
  }

  private initializeTemplates(): Map<NotificationTemplateType, NotificationTemplate> {
    const templates = new Map<NotificationTemplateType, NotificationTemplate>();

    // Blokada subskrypcji
    templates.set('subscription_blocked', {
      type: 'subscription_blocked',
      priority: 'urgent',
      subject: (data) => `⚠️ Subskrypcja ${this.getModuleName(data.module)} została zablokowana`,
      body: (data) => `
Witaj,

Twoja subskrypcja modułu ${this.getModuleName(data.module)} została automatycznie zablokowana.

Powód: ${data.reason}

Szczegóły:
- Opłacone lokale: ${data.paid_unit_count}
- Aktualna liczba lokali: ${data.current_unit_count}

Aby odblokować dostęp, wykonaj dopłatę za dodatkowe lokale.

Przejdź do panelu zarządzania subskrypcjami, aby wykonać upgrade.

Pozdrawiamy,
Zespół DOMIO
      `.trim()
    });

    // Zbliżające się wygaśnięcie
    templates.set('subscription_expiring', {
      type: 'subscription_expiring',
      priority: 'high',
      subject: (data) => `⏰ Subskrypcja ${this.getModuleName(data.module)} wygasa za ${data.days_left} dni`,
      body: (data) => `
Witaj,

Twoja subskrypcja modułu ${this.getModuleName(data.module)} wygasa za ${data.days_left} dni.

Data wygaśnięcia: ${new Date(data.expires_at).toLocaleDateString('pl-PL')}

Odnów subskrypcję już teraz, aby uniknąć przerwy w dostępie:
${data.renewal_url}

Pozdrawiamy,
Zespół DOMIO
      `.trim()
    });

    // Wygaśnięcie
    templates.set('subscription_expired', {
      type: 'subscription_expired',
      priority: 'urgent',
      subject: (data) => `❌ Subskrypcja ${this.getModuleName(data.module)} wygasła`,
      body: (data) => `
Witaj,

Twoja subskrypcja modułu ${this.getModuleName(data.module)} wygasła.

Data wygaśnięcia: ${new Date(data.expired_at).toLocaleDateString('pl-PL')}

Dostęp do modułu został zablokowany. Aby przywrócić dostęp, odnów subskrypcję:
${data.renewal_url}

Pozdrawiamy,
Zespół DOMIO
      `.trim()
    });

    // Odnowienie
    templates.set('subscription_renewed', {
      type: 'subscription_renewed',
      priority: 'normal',
      subject: (data) => `✅ Subskrypcja ${this.getModuleName(data.module)} została odnowiona`,
      body: (data) => `
Witaj,

Twoja subskrypcja modułu ${this.getModuleName(data.module)} została pomyślnie odnowiona.

Nowa data wygaśnięcia: ${new Date(data.new_expires_at).toLocaleDateString('pl-PL')}
Zapłacona kwota: ${data.amount_paid} PLN

Dziękujemy za zaufanie!

Zespół DOMIO
      `.trim()
    });

    // Upgrade
    templates.set('subscription_upgraded', {
      type: 'subscription_upgraded',
      priority: 'normal',
      subject: (data) => `⬆️ Subskrypcja ${this.getModuleName(data.module)} została rozszerzona`,
      body: (data) => `
Witaj,

Twoja subskrypcja modułu ${this.getModuleName(data.module)} została pomyślnie rozszerzona.

Liczba lokali: ${data.old_unit_count} → ${data.new_unit_count}
Dopłata: ${data.additional_payment} PLN

Dostęp do modułu został przywrócony.

Pozdrawiamy,
Zespół DOMIO
      `.trim()
    });

    // Trial ending
    templates.set('trial_ending', {
      type: 'trial_ending',
      priority: 'high',
      subject: (data) => `⏰ Okres próbny ${this.getModuleName(data.module)} kończy się za ${data.days_left} dni`,
      body: (data) => `
Witaj,

Twój okres próbny modułu ${this.getModuleName(data.module)} kończy się za ${data.days_left} dni.

Aby kontynuować korzystanie z modułu, wykup pełną subskrypcję:
${data.purchase_url}

Pozdrawiamy,
Zespół DOMIO
      `.trim()
    });

    // Payment required
    templates.set('payment_required', {
      type: 'payment_required',
      priority: 'urgent',
      subject: (data) => `💳 Wymagana płatność - ${this.getModuleName(data.module)}`,
      body: (data) => `
Witaj,

Wymagana jest płatność dla subskrypcji modułu ${this.getModuleName(data.module)}.

Kwota do zapłaty: ${data.amount} PLN
Powód: ${data.reason}

Dokonaj płatności, aby przywrócić dostęp:
${data.payment_url}

Pozdrawiamy,
Zespół DOMIO
      `.trim()
    });

    return templates;
  }

  // =========================================================================
  // PRIVATE METHODS - Recipients & Sending
  // =========================================================================

  private async getOrgAdmins(orgId: string): Promise<NotificationRecipient[]> {
    const { data, error } = await this.supabase
      .from('memberships')
      .select(`
        user_id,
        profiles:user_id (email, full_name)
      `)
      .eq('org_id', orgId)
      .in('role', ['owner', 'wlasciciel', 'admin', 'administrator']);

    if (error) {
      console.error('Failed to fetch org admins:', error);
      return [];
    }

    return (data || [])
      .filter((m: any) => m.profiles && !Array.isArray(m.profiles))
      .map((m: any) => ({
        user_id: m.user_id,
        email: m.profiles.email,
        full_name: m.profiles.full_name || ''
      }));
  }

  private async sendToRecipients(
    recipients: NotificationRecipient[],
    payload: NotificationPayload
  ): Promise<void> {
    // TODO: Integracja z systemem powiadomień
    // Obecnie tylko logowanie do konsoli

    console.log('=== NOTIFICATION ===');
    console.log('Type:', payload.type);
    console.log('Priority:', payload.priority);
    console.log('Subject:', payload.subject);
    console.log('Recipients:', recipients.length);
    console.log('Body:', payload.body);
    console.log('====================');

    // W przyszłości:
    // - Wysyłka e-mail przez email service
    // - Push notifications przez push service
    // - In-app notifications przez notification center
    // - Slack/Discord webhooks (opcjonalnie)

    // Przykład: Zapisz do tabeli notifications (jeśli istnieje)
    /*
    for (const recipient of recipients) {
      await this.supabase.from('notifications').insert({
        user_id: recipient.user_id,
        type: payload.type,
        subject: payload.subject,
        body: payload.body,
        data: payload.data,
        priority: payload.priority,
        status: 'pending'
      });
    }
    */
  }

  // =========================================================================
  // PRIVATE METHODS - Helpers
  // =========================================================================

  private getModuleName(module: AppModule): string {
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

  private getRenewalUrl(subscriptionId: string): string {
    // TODO: Użyj rzeczywistego URL z konfiguracji
    return `https://panel.domio.pl/subscriptions/${subscriptionId}/renew`;
  }

  private getPurchaseUrl(module: AppModule): string {
    return `https://panel.domio.pl/subscriptions/purchase?module=${module}`;
  }

  private getPaymentUrl(subscriptionId: string): string {
    return `https://panel.domio.pl/subscriptions/${subscriptionId}/payment`;
  }

  private calculateDaysLeft(expiresAt: string): number {
    const now = new Date();
    const expires = new Date(expiresAt);
    const diffTime = expires.getTime() - now.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  }
}

// =========================================================================
// FACTORY FUNCTION
// =========================================================================

export function createNotificationService(supabase: SupabaseClient): NotificationService {
  return new NotificationService(supabase);
}
