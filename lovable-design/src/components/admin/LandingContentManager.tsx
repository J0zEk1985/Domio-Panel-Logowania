import { useState } from "react";
import { motion } from "framer-motion";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { toast } from "@/hooks/use-toast";
import { Save, Eye, EyeOff, Megaphone, Type, AlignLeft } from "lucide-react";
import { cn } from "@/lib/utils";

export const LandingContentManager = () => {
  const [heroHeader, setHeroHeader] = useState("Twój Ekosystem. Jedno Centrum.");
  const [heroSubtitle, setHeroSubtitle] = useState(
    "DOMIO łączy wszystkie usługi dla Twojej nieruchomości w jednym, inteligentnym hubie."
  );
  const [bannerEnabled, setBannerEnabled] = useState(false);
  const [bannerText, setBannerText] = useState(
    "🎉 Promocja letnia! -20% na wszystkie moduły z kodem SUMMER20"
  );
  const [bannerType, setBannerType] = useState<"info" | "warning" | "promo">("promo");

  const saveContent = () => {
    toast({ title: "Zapisano", description: "Treści strony głównej zostały zaktualizowane." });
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8">
      {/* Hero Content */}
      <div className="bento-card">
        <div className="flex items-center justify-between mb-6">
          <h3 className="font-display text-lg font-semibold">Treści Hero Section</h3>
          <Button onClick={saveContent} size="sm">
            <Save className="h-4 w-4 mr-1" /> Zapisz
          </Button>
        </div>

        <div className="space-y-5">
          <div className="space-y-2">
            <Label className="flex items-center gap-2 text-sm">
              <Type className="h-4 w-4 text-primary" />
              Nagłówek główny
            </Label>
            <Input
              value={heroHeader}
              onChange={(e) => setHeroHeader(e.target.value)}
              placeholder="Wpisz nagłówek..."
              className="text-lg font-semibold"
            />
            <p className="text-xs text-muted-foreground">{heroHeader.length}/80 znaków</p>
          </div>

          <div className="space-y-2">
            <Label className="flex items-center gap-2 text-sm">
              <AlignLeft className="h-4 w-4 text-primary" />
              Podtytuł
            </Label>
            <Textarea
              value={heroSubtitle}
              onChange={(e) => setHeroSubtitle(e.target.value)}
              placeholder="Wpisz podtytuł..."
              className="min-h-[80px] resize-none"
            />
            <p className="text-xs text-muted-foreground">{heroSubtitle.length}/200 znaków</p>
          </div>

          {/* Preview */}
          <div className="p-6 rounded-xl bg-muted/30 border border-border/50">
            <p className="text-xs text-muted-foreground mb-3 uppercase tracking-wider">Podgląd</p>
            <h2 className="font-display text-2xl font-bold mb-2">{heroHeader || "..."}</h2>
            <p className="text-muted-foreground">{heroSubtitle || "..."}</p>
          </div>
        </div>
      </div>

      {/* Announcement Banner */}
      <div className="bento-card">
        <div className="flex items-center justify-between mb-6">
          <h3 className="font-display text-lg font-semibold">Baner ogłoszeniowy</h3>
          <div className="flex items-center gap-3">
            {bannerEnabled ? (
              <Eye className="h-4 w-4 text-primary" />
            ) : (
              <EyeOff className="h-4 w-4 text-muted-foreground" />
            )}
            <span className="text-sm text-muted-foreground">
              {bannerEnabled ? "Widoczny" : "Ukryty"}
            </span>
            <Switch checked={bannerEnabled} onCheckedChange={setBannerEnabled} />
          </div>
        </div>

        <div className="space-y-4">
          <div className="space-y-2">
            <Label className="flex items-center gap-2 text-sm">
              <Megaphone className="h-4 w-4 text-primary" />
              Treść baneru
            </Label>
            <Input
              value={bannerText}
              onChange={(e) => setBannerText(e.target.value)}
              placeholder="Wpisz treść baneru..."
            />
          </div>

          <div className="space-y-2">
            <Label className="text-sm">Typ baneru</Label>
            <div className="flex gap-2">
              {(["promo", "info", "warning"] as const).map((type) => (
                <Button
                  key={type}
                  variant={bannerType === type ? "default" : "outline"}
                  size="sm"
                  onClick={() => setBannerType(type)}
                >
                  {type === "promo" ? "Promocja" : type === "info" ? "Informacja" : "Ostrzeżenie"}
                </Button>
              ))}
            </div>
          </div>

          {/* Banner Preview */}
          {bannerEnabled && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: "auto" }}
              className={cn(
                "p-3 rounded-lg text-sm text-center font-medium",
                bannerType === "promo" && "bg-primary/10 text-primary border border-primary/20",
                bannerType === "info" && "bg-accent/10 text-accent border border-accent/20",
                bannerType === "warning" && "bg-destructive/10 text-destructive border border-destructive/20"
              )}
            >
              {bannerText}
            </motion.div>
          )}
        </div>
      </div>
    </motion.div>
  );
};
