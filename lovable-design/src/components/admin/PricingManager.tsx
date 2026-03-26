import { useState } from "react";
import { motion } from "framer-motion";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { Label } from "@/components/ui/label";
import { toast } from "@/hooks/use-toast";
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from "@/components/ui/table";
import { Save, Plus, Percent, Trash2 } from "lucide-react";
import { modules } from "@/data/modules";

interface TierPricing {
  basic: { monthly: number; yearly: number };
  pro: { monthly: number; yearly: number };
  enterprise: { monthly: number; yearly: number };
}

interface PromoCode {
  id: string;
  code: string;
  discount: number;
  active: boolean;
}

const defaultPricing: Record<string, TierPricing> = Object.fromEntries(
  modules.filter((m) => !m.comingSoon).map((m) => [
    m.slug,
    {
      basic: { monthly: 49, yearly: 470 },
      pro: { monthly: 99, yearly: 950 },
      enterprise: { monthly: 199, yearly: 1900 },
    },
  ])
);

const initialPromos: PromoCode[] = [
  { id: "1", code: "SUMMER20", discount: 20, active: true },
  { id: "2", code: "WELCOME10", discount: 10, active: false },
];

export const PricingManager = () => {
  const [pricing, setPricing] = useState(defaultPricing);
  const [promos, setPromos] = useState(initialPromos);
  const [newCode, setNewCode] = useState("");
  const [newDiscount, setNewDiscount] = useState("");

  const activeModules = modules.filter((m) => !m.comingSoon);

  const updatePrice = (slug: string, tier: keyof TierPricing, period: "monthly" | "yearly", value: string) => {
    setPricing((prev) => ({
      ...prev,
      [slug]: {
        ...prev[slug],
        [tier]: { ...prev[slug][tier], [period]: Number(value) || 0 },
      },
    }));
  };

  const addPromo = () => {
    if (!newCode.trim() || !newDiscount.trim()) return;
    setPromos((prev) => [
      ...prev,
      { id: Date.now().toString(), code: newCode.toUpperCase(), discount: Number(newDiscount), active: true },
    ]);
    setNewCode("");
    setNewDiscount("");
    toast({ title: "Kod dodany", description: `Kod promocyjny ${newCode.toUpperCase()} został utworzony.` });
  };

  const togglePromo = (id: string) => {
    setPromos((prev) => prev.map((p) => (p.id === id ? { ...p, active: !p.active } : p)));
  };

  const removePromo = (id: string) => {
    setPromos((prev) => prev.filter((p) => p.id !== id));
    toast({ title: "Usunięto", description: "Kod promocyjny został usunięty." });
  };

  const savePricing = () => {
    toast({ title: "Zapisano", description: "Cennik został zaktualizowany pomyślnie." });
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8">
      {/* Module Pricing Table */}
      <div className="bento-card">
        <div className="flex items-center justify-between mb-6">
          <h3 className="font-display text-lg font-semibold">Cennik modułów</h3>
          <Button onClick={savePricing} size="sm">
            <Save className="h-4 w-4 mr-1" /> Zapisz zmiany
          </Button>
        </div>

        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[140px]">Moduł</TableHead>
                <TableHead>Basic / mies.</TableHead>
                <TableHead>Basic / rok</TableHead>
                <TableHead>Pro / mies.</TableHead>
                <TableHead>Pro / rok</TableHead>
                <TableHead>Enterprise / mies.</TableHead>
                <TableHead>Enterprise / rok</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {activeModules.map((mod) => {
                const p = pricing[mod.slug];
                return (
                  <TableRow key={mod.slug}>
                    <TableCell className="font-medium">
                      <div className="flex items-center gap-2">
                        <mod.icon className="h-4 w-4 text-primary" />
                        {mod.name.replace(" DOMIO", "")}
                      </div>
                    </TableCell>
                    {(["basic", "pro", "enterprise"] as const).map((tier) => (
                      <>
                        <TableCell key={`${tier}-m`}>
                          <Input
                            type="number"
                            value={p[tier].monthly}
                            onChange={(e) => updatePrice(mod.slug, tier, "monthly", e.target.value)}
                            className="w-20 h-8 text-xs"
                          />
                        </TableCell>
                        <TableCell key={`${tier}-y`}>
                          <Input
                            type="number"
                            value={p[tier].yearly}
                            onChange={(e) => updatePrice(mod.slug, tier, "yearly", e.target.value)}
                            className="w-20 h-8 text-xs"
                          />
                        </TableCell>
                      </>
                    ))}
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </div>
      </div>

      {/* Promotions */}
      <div className="bento-card">
        <h3 className="font-display text-lg font-semibold mb-6">Kody promocyjne</h3>

        <div className="flex flex-wrap gap-3 mb-6">
          <div className="flex-1 min-w-[140px]">
            <Label className="text-xs text-muted-foreground mb-1 block">Kod</Label>
            <Input placeholder="np. SUMMER20" value={newCode} onChange={(e) => setNewCode(e.target.value)} className="h-9" />
          </div>
          <div className="w-24">
            <Label className="text-xs text-muted-foreground mb-1 block">Rabat %</Label>
            <Input type="number" placeholder="20" value={newDiscount} onChange={(e) => setNewDiscount(e.target.value)} className="h-9" />
          </div>
          <div className="flex items-end">
            <Button onClick={addPromo} size="sm" className="h-9">
              <Plus className="h-4 w-4 mr-1" /> Dodaj
            </Button>
          </div>
        </div>

        <div className="space-y-3">
          {promos.map((promo) => (
            <div key={promo.id} className="flex items-center justify-between p-3 rounded-xl bg-muted/50 border border-border/50">
              <div className="flex items-center gap-3">
                <Percent className="h-4 w-4 text-primary" />
                <span className="font-mono font-semibold text-sm">{promo.code}</span>
                <Badge variant="outline" className="text-xs">-{promo.discount}%</Badge>
              </div>
              <div className="flex items-center gap-3">
                <div className="flex items-center gap-2">
                  <span className="text-xs text-muted-foreground">{promo.active ? "Aktywny" : "Nieaktywny"}</span>
                  <Switch checked={promo.active} onCheckedChange={() => togglePromo(promo.id)} />
                </div>
                <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive" onClick={() => removePromo(promo.id)}>
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </motion.div>
  );
};
