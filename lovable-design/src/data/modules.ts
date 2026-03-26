import {
  Sparkles, Car, Building2, Wrench, ShieldCheck, Cpu, Leaf, Lock,
  ClipboardList, Bell, BarChart3, Calendar, MapPin, Fuel, Users, FileText,
  Key, Home, Zap, Settings, Globe, Shield, Layers, RefreshCw
} from "lucide-react";
import type { LucideIcon } from "lucide-react";

export interface ModuleFeature {
  title: string;
  description: string;
  icon: LucideIcon;
}

export interface ModuleUseCase {
  audience: string;
  icon: LucideIcon;
  benefits: string[];
}

export interface ModuleData {
  slug: string;
  name: string;
  tagline: string;
  description: string;
  icon: LucideIcon;
  color: string;
  comingSoon?: boolean;
  features: ModuleFeature[];
  useCases: ModuleUseCase[];
  integrations: string[];
}

export const modules: ModuleData[] = [
  {
    slug: "cleaning",
    name: "Cleaning DOMIO",
    tagline: "Profesjonalne sprzątanie pod pełną kontrolą.",
    description: "Kompleksowe zarządzanie usługami sprzątania dla budynków, przestrzeni wspólnych i mieszkań prywatnych. Automatyzacja harmonogramów, raportowanie w czasie rzeczywistym i pełna transparentność.",
    icon: Sparkles,
    color: "text-primary",
    features: [
      { title: "Harmonogramy w czasie rzeczywistym", description: "Automatyczne planowanie zadań z dynamicznym przydzielaniem zespołów.", icon: Calendar },
      { title: "Śledzenie postępów", description: "Monitoruj status każdego zlecenia na żywo z poziomu aplikacji.", icon: MapPin },
      { title: "Automatyczne rozliczenia", description: "Fakturowanie i płatności generowane automatycznie po wykonaniu usługi.", icon: BarChart3 },
      { title: "Zarządzanie zadaniami", description: "Twórz, przydzielaj i zarządzaj zadaniami dla zespołów sprzątających.", icon: ClipboardList },
      { title: "Powiadomienia push", description: "Natychmiastowe alerty o statusie zleceń i zmianach w harmonogramie.", icon: Bell },
      { title: "Raporty i analizy", description: "Szczegółowe raporty efektywności, kosztów i satysfakcji klientów.", icon: FileText },
    ],
    useCases: [
      {
        audience: "Mieszkańcy",
        icon: Home,
        benefits: [
          "Zamawiaj sprzątanie jednym kliknięciem",
          "Śledź postęp usługi w aplikacji",
          "Oceniaj i dawaj feedback zespołom",
          "Automatyczne przypomnienia o zaplanowanych usługach",
        ],
      },
      {
        audience: "Firmy",
        icon: Building2,
        benefits: [
          "Zarządzaj wieloma zespołami i lokalizacjami",
          "Automatyzuj harmonogramy i rozliczenia",
          "Analizuj efektywność z dashboardami KPI",
          "Skaluj operacje bez dodatkowej administracji",
        ],
      },
    ],
    integrations: [
      "Single Sign-On (SSO) z DOMIO Hub",
      "Synchronizacja z Serwis DOMIO",
      "Integracja z Nieruchomości DOMIO",
      "API do systemów zewnętrznych",
    ],
  },
  {
    slug: "flota",
    name: "Flota DOMIO",
    tagline: "Inteligentne zarządzanie flotą pojazdów.",
    description: "Pełna kontrola nad flotą pojazdów — od rezerwacji po monitoring GPS w czasie rzeczywistym. Optymalizacja kosztów paliwa, automatyczne raporty i zarządzanie serwisem.",
    icon: Car,
    color: "text-accent",
    features: [
      { title: "Monitoring GPS na żywo", description: "Śledź lokalizację każdego pojazdu w czasie rzeczywistym na mapie.", icon: MapPin },
      { title: "System rezerwacji", description: "Intuicyjny kalendarz rezerwacji pojazdów dla pracowników i mieszkańców.", icon: Calendar },
      { title: "Zarządzanie paliwem", description: "Automatyczne śledzenie zużycia paliwa i optymalizacja kosztów.", icon: Fuel },
      { title: "Serwis i konserwacja", description: "Planowanie przeglądów, historia napraw i alerty o terminach.", icon: Wrench },
      { title: "Zarządzanie kierowcami", description: "Profile kierowców, uprawnienia i historia użytkowania pojazdów.", icon: Users },
      { title: "Raporty flotowe", description: "Kompleksowe raporty kosztów, przebiegów i efektywności floty.", icon: BarChart3 },
    ],
    useCases: [
      {
        audience: "Mieszkańcy",
        icon: Home,
        benefits: [
          "Rezerwuj pojazdy wspólnotowe online",
          "Sprawdzaj dostępność w czasie rzeczywistym",
          "Automatyczne rozliczenia za użytkowanie",
          "Historia swoich rezerwacji i przejazdów",
        ],
      },
      {
        audience: "Firmy",
        icon: Building2,
        benefits: [
          "Zarządzaj całą flotą z jednego panelu",
          "Optymalizuj koszty paliwa i serwisu",
          "Kontroluj uprawnienia i dostęp do pojazdów",
          "Generuj raporty dla księgowości automatycznie",
        ],
      },
    ],
    integrations: [
      "Single Sign-On (SSO) z DOMIO Hub",
      "Synchronizacja z Serwis DOMIO",
      "Integracja z Bezpieczeństwo DOMIO",
      "API do systemów telematycznych",
    ],
  },
  {
    slug: "nieruchomosci",
    name: "Nieruchomości DOMIO",
    tagline: "Kompleksowe zarządzanie nieruchomościami.",
    description: "Kompleksowe zarządzanie nieruchomościami i najemcami.",
    icon: Building2,
    color: "text-primary",
    features: [
      { title: "Zarządzanie najemcami", description: "Kompletna baza danych najemców z historią umów.", icon: Users },
      { title: "Rozliczenia czynszu", description: "Automatyczne generowanie faktur i śledzenie płatności.", icon: BarChart3 },
      { title: "Dokumentacja", description: "Cyfrowe archiwum umów, protokołów i dokumentów.", icon: FileText },
      { title: "Kalendarz wydarzeń", description: "Planowanie spotkań, przeglądów i terminów.", icon: Calendar },
      { title: "Kontrola dostępu", description: "Zarządzanie kluczami i uprawnieniami do budynków.", icon: Key },
      { title: "Raporty finansowe", description: "Szczegółowe analizy przychodów i kosztów nieruchomości.", icon: BarChart3 },
    ],
    useCases: [
      { audience: "Mieszkańcy", icon: Home, benefits: ["Dostęp do dokumentów online", "Zgłaszanie usterek", "Historia płatności", "Komunikacja z zarządcą"] },
      { audience: "Firmy", icon: Building2, benefits: ["Zarządzanie portfolio nieruchomości", "Automatyzacja rozliczeń", "Raporty dla inwestorów", "Optymalizacja kosztów"] },
    ],
    integrations: ["Single Sign-On (SSO) z DOMIO Hub", "Synchronizacja z Serwis DOMIO", "Integracja z Cleaning DOMIO", "API do systemów księgowych"],
  },
  {
    slug: "serwis",
    name: "Serwis DOMIO",
    tagline: "Zgłoszenia serwisowe bez opóźnień.",
    description: "Zgłoszenia serwisowe, naprawy i konserwacja techniczna.",
    icon: Wrench,
    color: "text-accent",
    features: [
      { title: "System ticketów", description: "Intuicyjne zgłaszanie i śledzenie usterek.", icon: ClipboardList },
      { title: "Priorytetyzacja", description: "Automatyczne nadawanie priorytetów zgłoszeniom.", icon: Zap },
      { title: "Przydzielanie techników", description: "Inteligentne dopasowanie specjalistów do zadań.", icon: Users },
      { title: "Historia serwisowa", description: "Pełna dokumentacja wszystkich napraw i przeglądów.", icon: FileText },
      { title: "Powiadomienia statusu", description: "Aktualizacje w czasie rzeczywistym o postępie napraw.", icon: Bell },
      { title: "Raporty techniczne", description: "Analizy awaryjności i kosztów utrzymania.", icon: BarChart3 },
    ],
    useCases: [
      { audience: "Mieszkańcy", icon: Home, benefits: ["Szybkie zgłaszanie usterek", "Śledzenie statusu naprawy", "Ocena wykonanej pracy", "Historia zgłoszeń"] },
      { audience: "Firmy", icon: Building2, benefits: ["Zarządzanie zespołami serwisowymi", "Optymalizacja czasu reakcji", "Analiza kosztów utrzymania", "Planowanie konserwacji"] },
    ],
    integrations: ["Single Sign-On (SSO) z DOMIO Hub", "Synchronizacja z Nieruchomości DOMIO", "Integracja z Cleaning DOMIO", "API do systemów CMMS"],
  },
  {
    slug: "bezpieczenstwo",
    name: "Bezpieczeństwo DOMIO",
    tagline: "Kontrola dostępu i monitoring 24/7.",
    description: "System kontroli dostępu i monitoring bezpieczeństwa.",
    icon: ShieldCheck,
    color: "text-primary",
    features: [
      { title: "Kontrola dostępu", description: "Zarządzanie kartami, kodami i uprawnieniami.", icon: Key },
      { title: "Monitoring wideo", description: "Integracja z systemami CCTV i podgląd na żywo.", icon: Shield },
      { title: "Alarmy i alerty", description: "Natychmiastowe powiadomienia o zdarzeniach.", icon: Bell },
      { title: "Logi dostępu", description: "Pełna historia wejść i wyjść.", icon: FileText },
      { title: "Zarządzanie uprawnieniami", description: "Granularne ustawienia dostępu per użytkownik.", icon: Settings },
      { title: "Raporty bezpieczeństwa", description: "Analizy incydentów i statystyki dostępu.", icon: BarChart3 },
    ],
    useCases: [
      { audience: "Mieszkańcy", icon: Home, benefits: ["Cyfrowy klucz w telefonie", "Historia dostępu", "Zarządzanie gośćmi", "Powiadomienia o wejściach"] },
      { audience: "Firmy", icon: Building2, benefits: ["Centralne zarządzanie dostępem", "Integracja z CCTV", "Audyt bezpieczeństwa", "Raportowanie incydentów"] },
    ],
    integrations: ["Single Sign-On (SSO) z DOMIO Hub", "Synchronizacja z Smart Home DOMIO", "Integracja z Nieruchomości DOMIO", "API do systemów SKD"],
  },
  {
    slug: "smart-home",
    name: "Smart Home DOMIO",
    tagline: "Inteligentne zarządzanie domem.",
    description: "Inteligentne zarządzanie domem — automatyka, czujniki i sterowanie.",
    icon: Cpu,
    color: "text-muted-foreground",
    comingSoon: true,
    features: [],
    useCases: [],
    integrations: [],
  },
  {
    slug: "eko",
    name: "Eko DOMIO",
    tagline: "Ekologiczne rozwiązania dla nieruchomości.",
    description: "Ekologiczne rozwiązania — zarządzanie odpadami i energia odnawialna.",
    icon: Leaf,
    color: "text-muted-foreground",
    comingSoon: true,
    features: [],
    useCases: [],
    integrations: [],
  },
  {
    slug: "ochrona-danych",
    name: "Ochrona Danych",
    tagline: "Bezpieczeństwo danych osobowych.",
    description: "Bezpieczne przechowywanie i zarządzanie danymi osobowymi (RODO).",
    icon: Lock,
    color: "text-muted-foreground",
    comingSoon: true,
    features: [],
    useCases: [],
    integrations: [],
  },
];

export function getModuleBySlug(slug: string): ModuleData | undefined {
  return modules.find((m) => m.slug === slug);
}
