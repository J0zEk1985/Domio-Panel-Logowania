import { useState } from "react";
import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "@/hooks/use-toast";
import { FileText, Scale, Cookie, Save, Upload } from "lucide-react";
import { cn } from "@/lib/utils";

interface LegalDoc {
  id: string;
  title: string;
  icon: React.ElementType;
  lastUpdated: string;
  content: string;
}

const initialDocs: LegalDoc[] = [
  {
    id: "terms",
    title: "Regulamin",
    icon: Scale,
    lastUpdated: "2025-01-15 14:30",
    content: `REGULAMIN PLATFORMY DOMIO\n\n§1. Postanowienia ogólne\n1. Niniejszy regulamin określa zasady korzystania z platformy DOMIO.\n2. Platforma jest prowadzona przez DOMIO sp. z o.o. z siedzibą w Warszawie.\n\n§2. Definicje\n1. Użytkownik — osoba fizyczna lub prawna korzystająca z Platformy.\n2. Moduł — pojedyncza usługa dostępna w ramach platformy DOMIO.\n\n§3. Warunki korzystania\n1. Korzystanie z Platformy wymaga rejestracji konta.\n2. Użytkownik zobowiązuje się do podania prawdziwych danych.\n3. Konto jest osobiste i nie może być udostępniane osobom trzecim.`,
  },
  {
    id: "privacy",
    title: "Polityka Prywatności (RODO)",
    icon: FileText,
    lastUpdated: "2025-02-01 10:00",
    content: `POLITYKA PRYWATNOŚCI — DOMIO\n\n1. Administrator danych\nAdministratorem danych osobowych jest DOMIO sp. z o.o.\n\n2. Cel przetwarzania\nDane osobowe przetwarzane są w celu świadczenia usług platformy, obsługi konta użytkownika oraz realizacji zobowiązań umownych.\n\n3. Podstawa prawna\nPrzetwarzanie odbywa się na podstawie art. 6 ust. 1 lit. b) RODO.\n\n4. Prawa użytkownika\nUżytkownik ma prawo dostępu do danych, ich sprostowania, usunięcia oraz przenoszenia.`,
  },
  {
    id: "cookies",
    title: "Polityka Cookies",
    icon: Cookie,
    lastUpdated: "2024-12-20 09:15",
    content: `POLITYKA COOKIES — DOMIO\n\n1. Czym są pliki cookies?\nPliki cookies to małe pliki tekstowe zapisywane na urządzeniu użytkownika.\n\n2. Jakie cookies wykorzystujemy?\n- Niezbędne — wymagane do prawidłowego działania platformy\n- Analityczne — pomagają zrozumieć sposób korzystania z serwisu\n- Marketingowe — umożliwiają dostosowanie treści reklamowych\n\n3. Zarządzanie cookies\nUżytkownik może zmienić ustawienia cookies w przeglądarce.`,
  },
];

export const LegalEditor = () => {
  const [docs, setDocs] = useState(initialDocs);
  const [activeDocId, setActiveDocId] = useState("terms");

  const activeDoc = docs.find((d) => d.id === activeDocId)!;

  const updateContent = (content: string) => {
    setDocs((prev) => prev.map((d) => (d.id === activeDocId ? { ...d, content } : d)));
  };

  const publishDoc = () => {
    const now = new Date().toISOString().slice(0, 16).replace("T", " ");
    setDocs((prev) => prev.map((d) => (d.id === activeDocId ? { ...d, lastUpdated: now } : d)));
    toast({ title: "Opublikowano", description: `Dokument "${activeDoc.title}" został zaktualizowany.` });
  };

  const saveDraft = () => {
    toast({ title: "Zapisano szkic", description: "Zmiany zostały zapisane jako wersja robocza." });
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex flex-col md:flex-row gap-6">
      {/* Sidebar */}
      <div className="md:w-64 shrink-0">
        <div className="bento-card space-y-1 p-3">
          {docs.map((doc) => (
            <button
              key={doc.id}
              onClick={() => setActiveDocId(doc.id)}
              className={cn(
                "w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-left transition-colors",
                activeDocId === doc.id
                  ? "bg-primary/10 text-primary font-medium"
                  : "text-muted-foreground hover:bg-muted/50"
              )}
            >
              <doc.icon className="h-4 w-4 shrink-0" />
              {doc.title}
            </button>
          ))}
        </div>
      </div>

      {/* Editor */}
      <div className="flex-1 bento-card">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6">
          <div>
            <h3 className="font-display text-lg font-semibold flex items-center gap-2">
              <activeDoc.icon className="h-5 w-5 text-primary" />
              {activeDoc.title}
            </h3>
            <p className="text-xs text-muted-foreground mt-1">
              Ostatnia aktualizacja: {activeDoc.lastUpdated}
            </p>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" onClick={saveDraft}>
              <Save className="h-4 w-4 mr-1" /> Zapisz szkic
            </Button>
            <Button size="sm" onClick={publishDoc}>
              <Upload className="h-4 w-4 mr-1" /> Opublikuj
            </Button>
          </div>
        </div>

        <div className="relative">
          {/* Mock toolbar */}
          <div className="flex items-center gap-1 p-2 rounded-t-lg border border-border/50 bg-muted/30 text-xs">
            {["B", "I", "U", "H1", "H2", "•", "1.", "—", "🔗"].map((btn) => (
              <button
                key={btn}
                className="px-2 py-1 rounded hover:bg-muted transition-colors font-mono text-muted-foreground"
              >
                {btn}
              </button>
            ))}
          </div>
          <Textarea
            value={activeDoc.content}
            onChange={(e) => updateContent(e.target.value)}
            className="min-h-[400px] rounded-t-none border-t-0 font-mono text-sm leading-relaxed resize-y"
          />
        </div>
      </div>
    </motion.div>
  );
};
