# Funkcjonalność tłumaczenia notatek koordynatora

## Opis

System umożliwia tłumaczenie treści z pola `coordinator_notes` z polskiego na ukraiński za pomocą przycisku "Przetłumacz".

## Komponenty

### 1. `CoordinatorNotes` (`src/components/CoordinatorNotes.tsx`)

Komponent wyświetlający notatki koordynatora z funkcją tłumaczenia.

**Użycie:**
```tsx
import { CoordinatorNotes } from '../components/CoordinatorNotes'

<CoordinatorNotes notes={task.coordinator_notes} />
```

**Właściwości:**
- `notes: string | null | undefined` - tekst notatek koordynatora
- `className?: string` - dodatkowe klasy CSS

### 2. `TranslateButton` (`src/components/TranslateButton.tsx`)

Standalone przycisk do tłumaczenia tekstu.

**Użycie:**
```tsx
import { TranslateButton } from '../components/TranslateButton'

<TranslateButton 
  text={notes} 
  onTranslationComplete={(translated) => setTranslated(translated)} 
/>
```

### 3. Hook `useTranslateText` (`src/hooks/useTranslateText.ts`)

Hook do tłumaczenia tekstu przy użyciu MyMemory API.

**Użycie:**
```tsx
import { useTranslateText } from '../hooks/useTranslateText'

const { translate, loading, translatedText, error } = useTranslateText()

await translate('Tekst do przetłumaczenia', 'pl', 'uk')
```

## Integracja z i18next

System używa i18next do tłumaczenia interfejsu użytkownika (nazwy przycisków, etykiet).

**Konfiguracja:** `src/lib/i18n.ts`

**Dostępne klucze tłumaczeń:**
- `translate` - "Przetłumacz" / "Перекласти"
- `autoTranslation` - "Tłumaczenie automatyczne" / "Автоматичний переклад"
- `translating` - "Tłumaczenie..." / "Переклад..."
- `translationError` - "Błąd tłumaczenia" / "Помилка перекладу"

## API tłumaczeń

System używa **MyMemory Translation API** (https://mymemory.translated.net/):
- Darmowe (bez API key)
- Ma limity rate (ok. 100 zapytań/dzień dla darmowego planu)
- Obsługuje tłumaczenie PL → UA

## Przykład użycia w PropertyDetailSheet lub TaskCard

```tsx
import { CoordinatorNotes } from '../components/CoordinatorNotes'

function TaskCard({ task }) {
  return (
    <div>
      <h3>{task.title}</h3>
      {task.coordinator_notes && (
        <div>
          <h4>Notatki koordynatora:</h4>
          <CoordinatorNotes notes={task.coordinator_notes} />
        </div>
      )}
    </div>
  )
}
```

## Uwagi

- Tłumaczenie wymaga połączenia z internetem
- MyMemory API ma limity rate dla darmowego planu
- Tłumaczenie jest wykonywane na żądanie (po kliknięciu przycisku)
- Przetłumaczony tekst jest wyświetlany pod oryginalnym tekstem
