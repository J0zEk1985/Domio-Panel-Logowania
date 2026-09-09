import {
  Sparkles,
  Car,
  Building2,
  Wrench,
  ShieldCheck,
  Cpu,
  Leaf,
  Lock,
  ClipboardList,
  Bell,
  BarChart3,
  Calendar,
  MapPin,
  Fuel,
  Users,
  FileText,
  Home,
  Warehouse,
  QrCode,
  Megaphone,
  MessageSquare,
  ClipboardCheck,
  Package,
} from 'lucide-react'
import type { LucideIcon } from 'lucide-react'

export interface ModuleFeature {
  title: string
  description: string
  icon: LucideIcon
}

export interface ModuleUseCase {
  audience: string
  icon: LucideIcon
  benefits: string[]
}

export interface ModuleData {
  slug: string
  name: string
  tagline: string
  description: string
  shortDescription?: string
  cta?: string
  icon: LucideIcon
  color: string
  listedOnLanding?: boolean
  comingSoon?: boolean
  features: ModuleFeature[]
  useCases: ModuleUseCase[]
  integrations: string[]
}

export const modules: ModuleData[] = [
  {
    slug: 'cleaning',
    name: 'Domio Cleaning',
    tagline: 'Sprzątanie nieruchomości pod pełną kontrolą.',
    description:
      'Planuj pracę zespołu, śledź postęp na mapie i rozliczaj godziny — od checklisty na obiekcie po magazyn środków i zgłoszenia usterek.',
    shortDescription: 'Planowanie i kontrola usług porządkowych: harmonogramy, mapa obiektów, zespół i magazyn.',
    cta: 'Więcej o Cleaning',
    icon: Sparkles,
    color: 'text-primary',
    listedOnLanding: true,
    features: [
      {
        title: 'Centrum dowodzenia z mapą',
        description: 'Status obiektów na żywo, alerty i aktywność zespołu w jednym widoku.',
        icon: MapPin,
      },
      {
        title: 'Harmonogramy SOP i zadania',
        description: 'Sekcje, personel, dni wolne oraz automatyczne planowanie pracy z wyprzedzeniem.',
        icon: Calendar,
      },
      {
        title: 'Aplikacja terenowa z checklistą',
        description: 'Dzisiejsze obiekty, odhaczanie czynności, start i koniec wizyty oraz notatki.',
        icon: ClipboardList,
      },
      {
        title: 'Weryfikacja obecności',
        description: 'Check-in i check-out z GPS oraz opcjonalnym kodem QR na obiekcie.',
        icon: QrCode,
      },
      {
        title: 'Zgłoszenia usterek ze zdjęciem',
        description: 'Pracownik zgłasza usterkę z terenu; koordynator przekazuje ją dalej, rozwiązuje lub odrzuca.',
        icon: ClipboardCheck,
      },
      {
        title: 'Magazyn i ewidencja sprzętu',
        description: 'Katalog środków, zapotrzebowania z obiektów oraz zdawanie i przyjmowanie sprzętu.',
        icon: Warehouse,
      },
    ],
    useCases: [
      {
        audience: 'Firmy sprzątające',
        icon: Building2,
        benefits: [
          'Widzisz postęp sprzątania na mapie bez dzwonienia do zespołu',
          'Konfigurujesz budynki, sekcje, pracowników i harmonogramy w jednym miejscu',
          'Obsługujesz usterki z terenu i zapotrzebowania magazynowe',
          'Rozliczasz godziny i wypłaty pracowników',
        ],
      },
      {
        audience: 'Pracownicy terenowi',
        icon: Users,
        benefits: [
          'Widzisz tylko przypisane obiekty i zadania na dziś',
          'Odhaczasz listę czynności i kończysz wizytę',
          'Potwierdzasz obecność GPS lub QR i zgłaszasz usterkę ze zdjęciem',
          'Zamawiasz środki i w sezonie rejestrujesz odśnieżanie',
        ],
      },
    ],
    integrations: [
      'Single Sign-On z Panelem DOMIO',
      'Usterki przekazywane do Serwis DOMIO',
      'Wspólny rejestr budynków z Administracją',
      'Opcjonalny status sprzątania w Domio Home',
    ],
  },
  {
    slug: 'flota',
    name: 'Domio Flota',
    tagline: 'Pojazdy, kierowcy i koszty w jednym panelu.',
    description:
      'Rejestr pojazdów, tankowania, terminy przeglądów i ubezpieczeń oraz koszty paliwa i napraw — bez rozproszonych arkuszy.',
    shortDescription: 'Zarządzanie pojazdami, kierowcami, paliwem i terminami serwisowymi.',
    cta: 'Zarządzaj Flotą',
    icon: Car,
    color: 'text-accent',
    listedOnLanding: true,
    features: [
      {
        title: 'Rejestr pojazdów',
        description: 'Numery, przebieg, przypisany kierowca oraz terminy przeglądu i ubezpieczenia.',
        icon: Car,
      },
      {
        title: 'Tankowania',
        description: 'Logi paliwa z kosztami — kierowca dodaje tankowanie z poziomu aplikacji.',
        icon: Fuel,
      },
      {
        title: 'Koszty i spalanie',
        description: 'Podsumowanie wydatków na paliwo i naprawy oraz średnie spalanie w wybranym okresie.',
        icon: BarChart3,
      },
      {
        title: 'Terminy i alerty',
        description: 'Przypomnienia o przeglądzie, OC/AC i oponach zbliżających się do deadline’u.',
        icon: Bell,
      },
      {
        title: 'Dokumenty pojazdu',
        description: 'Polisa i dowód rejestracyjny dostępne do podglądu w karcie pojazdu.',
        icon: FileText,
      },
      {
        title: 'Kierowcy',
        description: 'Przypisanie pojazdu, aktualizacja przebiegu i wgląd we własne terminy oraz dokumenty.',
        icon: Users,
      },
    ],
    useCases: [
      {
        audience: 'Administratorzy floty',
        icon: Building2,
        benefits: [
          'Masz rejestr pojazdów, kierowców i dokumentów w jednym miejscu',
          'Śledzisz koszty paliwa i napraw w wybranym okresie',
          'Dostajesz alerty o zbliżających się przeglądach i ubezpieczeniach',
          'Przypisujesz pojazdy i kontrolujesz przebiegi',
        ],
      },
      {
        audience: 'Kierowcy',
        icon: Users,
        benefits: [
          'Widzisz przypisany pojazd, terminy i dokumenty',
          'Dodajesz tankowanie i aktualizujesz przebieg',
          'Otrzymujesz przypomnienia o przeglądzie i ubezpieczeniu',
          'Nie potrzebujesz osobnych arkuszy ani maili',
        ],
      },
    ],
    integrations: [
      'Single Sign-On z Panelem DOMIO',
      'Wspólna sesja organizacji DOMIO',
      'Przechowywanie dokumentów pojazdu',
      'Szablony powiadomień o terminach',
    ],
  },
  {
    slug: 'serwis',
    name: 'Domio Serwis',
    tagline: 'Zgłoszenia, naprawy i protokoły bez opóźnień.',
    description:
      'Jedna skrzynka zgłoszeń z QR, administracji i sprzątania. Dyspozytor przydziela prace, technik raportuje ze zdjęciami, a rozliczenie zamyka protokół.',
    shortDescription: 'Obsługa zgłoszeń, usterek i zadań technicznych z historią, zdjęciami i protokołem.',
    cta: 'Poznaj Serwis',
    icon: Wrench,
    color: 'text-primary',
    listedOnLanding: true,
    features: [
      {
        title: 'Skrzynka zgłoszeń',
        description: 'Kolejka z QR mieszkańca, administracji, sprzątania i dyspozytora — z przypisaniem lub giełdą wewnętrzną.',
        icon: ClipboardList,
      },
      {
        title: 'Panel technika',
        description: 'Zlecenia dostępne, aktywne i zakończone; sortowanie m.in. po odległości; raport ze zdjęciami.',
        icon: Wrench,
      },
      {
        title: 'Mapa budynków i zleceń',
        description: 'Podgląd aktywnych obiektów i pracy zespołu na mapie.',
        icon: MapPin,
      },
      {
        title: 'Protokół i rozliczenia',
        description: 'Protokół PDF, materiały i dopłaty — pod rozliczenie usługi, nie czynszu.',
        icon: FileText,
      },
      {
        title: 'Przeglądy lokalowe',
        description: 'Kampanie przeglądów oraz wykonanie w terenie z potwierdzeniem obecności mieszkańca.',
        icon: ClipboardCheck,
      },
      {
        title: 'Publiczne zgłoszenie QR',
        description: 'Formularz usterki ze zdjęciami bez logowania, gdy budynek ma włączony dostęp.',
        icon: QrCode,
      },
    ],
    useCases: [
      {
        audience: 'Firmy serwisowe',
        icon: Building2,
        benefits: [
          'Jedna skrzynka zgłoszeń z wielu źródeł',
          'Mapa, zespół i historia zleceń w jednym panelu',
          'Protokoły PDF pod rozliczenie wykonanej usługi',
          'Przeglądy lokalowe planowane i rozliczane w terenie',
        ],
      },
      {
        audience: 'Technicy',
        icon: Users,
        benefits: [
          'Jasna kolejka dnia i giełda dostępnych zleceń',
          'Raport naprawy ze zdjęciami i notatką głosową',
          'Sortowanie zleceń m.in. po odległości',
          'Weryfikacja GPS przy starcie pracy',
        ],
      },
    ],
    integrations: [
      'Single Sign-On z Panelem DOMIO',
      'Zgłoszenia z Administracji i Cleaning',
      'Formularz QR i statusy w Domio Home',
      'Mapy i adresy Google Places',
    ],
  },
  {
    slug: 'administracja',
    name: 'Domio Administracja',
    tagline: 'Wspólnoty, budynki i zgłoszenia w jednym miejscu.',
    description:
      'Zarządzaj wspólnotami i nieruchomościami: triage usterek, umowy, przeglądy c-KOB, zadania zespołu oraz komunikaty dla mieszkańców.',
    shortDescription: 'Zarządzanie wspólnotami i budynkami: zgłoszenia, umowy, przeglądy i komunikacja z mieszkańcami.',
    cta: 'Poznaj Administrację',
    icon: Building2,
    color: 'text-accent',
    listedOnLanding: true,
    features: [
      {
        title: 'Pulpit zgodności',
        description: 'Zaległe usterki, pominięte sprzątanie, wygasające przeglądy i umowy oraz alerty weryfikacji podmiotów.',
        icon: BarChart3,
      },
      {
        title: 'Triage zgłoszeń',
        description: 'Akceptacja, odrzucenie, przypisanie personelu lub delegacja do partnera — ze zdjęciami.',
        icon: ClipboardList,
      },
      {
        title: 'Budynki i wspólnoty',
        description: 'Karty nieruchomości: zespół, zadania, umowy, automatyzacje, QR Serwisu i przeglądy lokalowe.',
        icon: Building2,
      },
      {
        title: 'Umowy i firmy',
        description: 'Rejestr umów z kontrahentami oraz dane firm powiązanych z organizacją.',
        icon: FileText,
      },
      {
        title: 'Przeglądy c-KOB',
        description: 'Globalny rejestr protokołów oraz synchronizacja z c-KOB.',
        icon: ClipboardCheck,
      },
      {
        title: 'Tablica ogłoszeń i kiosk',
        description: 'Publikacja komunikatów dla mieszkańców oraz wyświetlanie na ekranie / portalu zarządu.',
        icon: Megaphone,
      },
    ],
    useCases: [
      {
        audience: 'Zarządcy',
        icon: Building2,
        benefits: [
          'Widzisz ryzyka budynku: usterki, sprzątanie, umowy i przeglądy',
          'Obsługujesz triage zgłoszeń i delegujesz je do partnerów',
          'Prowadzisz umowy, zespół i automatyzacje per nieruchomość',
          'Komunikujesz się z mieszkańcami przez tablicę ogłoszeń',
        ],
      },
      {
        audience: 'Zespół administracji',
        icon: Users,
        benefits: [
          'Masz wspólny rejestr wspólnot, budynków i zadań',
          'Szybko tworzysz zgłoszenia i ogłoszenia z terenu',
          'Korzystasz z QR Serwisu bez osobnego procesu papierowego',
          'Śledzisz przeglądy i terminy w jednym kalendarzu',
        ],
      },
    ],
    integrations: [
      'Single Sign-On z Panelem DOMIO',
      'Cykl zgłoszeń z Serwis DOMIO',
      'Statusy sprzątania z Cleaning DOMIO',
      'Komunikaty e-board w Domio Home',
    ],
  },
  {
    slug: 'home',
    name: 'Domio Home',
    tagline: 'Życie budynku w jednej aplikacji mieszkańca.',
    description:
      'Komunikaty administracji, zgłaszanie i śledzenie usterek, tablica sąsiedzka oraz oferty lokalnych partnerów — bez rezerwacji usług i bez panelu czynszowego.',
    shortDescription: 'Aplikacja mieszkańca: komunikaty, usterki, tablica sąsiedzka i oferty partnerów.',
    cta: 'Poznaj Home',
    icon: Home,
    color: 'text-primary',
    listedOnLanding: true,
    features: [
      {
        title: 'Pulpit mieszkańca',
        description: 'Komunikaty administracji, skróty tablicy sąsiedzkiej, ostatnie usterki i przeglądy lokalu.',
        icon: Home,
      },
      {
        title: 'Zgłoszenia usterek',
        description: 'Formularz Serwisu oraz lista własnych i widocznych usterek budynku.',
        icon: Wrench,
      },
      {
        title: 'Tablica sąsiedzka',
        description: 'Ogłoszenia, pomoc, wydarzenia i oferty z komentarzami.',
        icon: MessageSquare,
      },
      {
        title: 'Oferty partnerów',
        description: 'Lokalne promocje z kodem i linkiem zewnętrznym — bez rezerwacji w aplikacji.',
        icon: Package,
      },
      {
        title: 'Status sprzątania',
        description: 'Data ostatniego zakończonego sprzątania, gdy zarządca włączy podgląd dla budynku.',
        icon: Sparkles,
      },
      {
        title: 'Przeglądy lokalu',
        description: 'Harmonogram przeglądu oraz zgłoszenie obecności „Jestem w domu”.',
        icon: Calendar,
      },
    ],
    useCases: [
      {
        audience: 'Mieszkańcy',
        icon: Home,
        benefits: [
          'Czytasz komunikaty administracji w jednym miejscu',
          'Zgłaszasz usterki i śledzisz ich status',
          'Korzystasz z tablicy sąsiedzkiej i ofert partnerów',
          'Potwierdzasz obecność przy zaplanowanym przeglądzie lokalu',
        ],
      },
      {
        audience: 'Zarządcy',
        icon: Building2,
        benefits: [
          'Publikujesz komunikaty, które mieszkaniec widzi na pulpicie',
          'Mieszkańcy zgłaszają usterki bez papieru i maili',
          'Możesz pokazać status ostatniego sprzątania',
          'Ułatwiasz obecność przy przeglądach lokali',
        ],
      },
    ],
    integrations: [
      'Single Sign-On z Panelem DOMIO',
      'Zgłoszenia w Serwis DOMIO',
      'Komunikaty z Administracji DOMIO',
      'Opcjonalny status sprzątania z Cleaning',
    ],
  },
  {
    slug: 'nieruchomosci',
    name: 'Nieruchomości DOMIO',
    tagline: 'Kompleksowe zarządzanie nieruchomościami.',
    description: 'Kompleksowe zarządzanie nieruchomościami i najemcami.',
    icon: Building2,
    color: 'text-muted-foreground',
    comingSoon: true,
    features: [],
    useCases: [],
    integrations: [],
  },
  {
    slug: 'biznes',
    name: 'Domio Biznes',
    tagline: 'Skaluj operacje i obsługę klientów.',
    description: 'Rozwijaj obsługę klientów, automatyzuj procesy i skaluj operacje w jednej platformie.',
    icon: Building2,
    color: 'text-muted-foreground',
    comingSoon: true,
    features: [],
    useCases: [],
    integrations: [],
  },
  {
    slug: 'bezpieczenstwo',
    name: 'Bezpieczeństwo DOMIO',
    tagline: 'Kontrola dostępu i monitoring 24/7.',
    description: 'System kontroli dostępu i monitoring bezpieczeństwa.',
    icon: ShieldCheck,
    color: 'text-muted-foreground',
    comingSoon: true,
    features: [],
    useCases: [],
    integrations: [],
  },
  {
    slug: 'smart-home',
    name: 'Smart Home DOMIO',
    tagline: 'Inteligentne zarządzanie domem.',
    description: 'Inteligentne zarządzanie domem — automatyka, czujniki i sterowanie.',
    icon: Cpu,
    color: 'text-muted-foreground',
    comingSoon: true,
    features: [],
    useCases: [],
    integrations: [],
  },
  {
    slug: 'eko',
    name: 'Eko DOMIO',
    tagline: 'Ekologiczne rozwiązania dla nieruchomości.',
    description: 'Ekologiczne rozwiązania — zarządzanie odpadami i energia odnawialna.',
    icon: Leaf,
    color: 'text-muted-foreground',
    comingSoon: true,
    features: [],
    useCases: [],
    integrations: [],
  },
  {
    slug: 'ochrona-danych',
    name: 'Ochrona Danych',
    tagline: 'Bezpieczeństwo danych osobowych.',
    description: 'Bezpieczne przechowywanie i zarządzanie danymi osobowymi (RODO).',
    icon: Lock,
    color: 'text-muted-foreground',
    comingSoon: true,
    features: [],
    useCases: [],
    integrations: [],
  },
]

export function getModuleBySlug(slug: string): ModuleData | undefined {
  return modules.find((m) => m.slug === slug)
}

export function getLandingModules(): ModuleData[] {
  return modules.filter((m) => m.listedOnLanding)
}

export function audienceHeading(audience: string): string {
  const map: Record<string, string> = {
    Mieszkańcy: 'Mieszkańców',
    Firmy: 'Firm',
    Zarządcy: 'Zarządców',
    Technicy: 'Techników',
    Kierowcy: 'Kierowców',
    'Firmy sprzątające': 'Firm sprzątających',
    'Firmy serwisowe': 'Firm serwisowych',
    'Pracownicy terenowi': 'Pracowników terenowych',
    'Administratorzy floty': 'Administratorów floty',
    'Zespół administracji': 'Zespołu administracji',
  }
  return map[audience] ?? audience
}
