import { useState } from "react";
import { motion } from "framer-motion";
import { CheckCircle2, Star } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";

export interface PricingPlan {
  id: string;
  name: string;
  monthlyPrice: number;
  yearlyPrice: number;
  features: string[];
  highlighted?: boolean;
}

const defaultPlans: PricingPlan[] = [
  {
    id: "basic",
    name: "Basic",
    monthlyPrice: 49,
    yearlyPrice: 470,
    features: [
      "Do 10 użytkowników",
      "Podstawowe raporty",
      "Harmonogramy zadań",
      "Powiadomienia e-mail",
      "Wsparcie w dni robocze",
    ],
  },
  {
    id: "pro",
    name: "Pro",
    monthlyPrice: 129,
    yearlyPrice: 1249,
    highlighted: true,
    features: [
      "Do 50 użytkowników",
      "Zaawansowane raporty i KPI",
      "Automatyzacja procesów",
      "API & integracje",
      "Powiadomienia push",
      "Priorytetowe wsparcie 24/7",
    ],
  },
  {
    id: "enterprise",
    name: "Enterprise",
    monthlyPrice: 349,
    yearlyPrice: 3349,
    features: [
      "Nielimitowani użytkownicy",
      "Dedykowany opiekun",
      "SLA gwarancja uptime 99.9%",
      "Własne integracje & webhook",
      "White-label branding",
      "On-premise / VPS deployment",
    ],
  },
];

interface PricingSectionProps {
  moduleName: string;
  onSelectPlan: (plan: PricingPlan, yearly: boolean) => void;
}

export function PricingSection({ moduleName, onSelectPlan }: PricingSectionProps) {
  const [yearly, setYearly] = useState(false);

  return (
    <section className="py-20 px-4">
      <div className="container mx-auto max-w-6xl">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-12"
        >
          <h2 className="font-display text-3xl md:text-4xl font-bold mb-4">
            Wybierz swój <span className="gradient-brand-text">plan</span>
          </h2>
          <p className="text-muted-foreground max-w-md mx-auto mb-8">
            Elastyczne plany cenowe dopasowane do Twoich potrzeb.
          </p>
          <div className="flex items-center justify-center gap-3">
            <Label htmlFor="billing-toggle" className={`text-sm ${!yearly ? "text-foreground" : "text-muted-foreground"}`}>
              Miesięcznie
            </Label>
            <Switch id="billing-toggle" checked={yearly} onCheckedChange={setYearly} />
            <Label htmlFor="billing-toggle" className={`text-sm ${yearly ? "text-foreground" : "text-muted-foreground"}`}>
              Rocznie
              <span className="ml-1.5 text-xs text-primary font-semibold">-20%</span>
            </Label>
          </div>
        </motion.div>

        <motion.div
          initial="hidden"
          whileInView="show"
          viewport={{ once: true, amount: 0.2 }}
          variants={{ hidden: { opacity: 0 }, show: { opacity: 1, transition: { staggerChildren: 0.1 } } }}
          className="grid grid-cols-1 md:grid-cols-3 gap-6"
        >
          {defaultPlans.map((plan) => {
            const price = yearly ? plan.yearlyPrice : plan.monthlyPrice;
            return (
              <motion.div
                key={plan.id}
                variants={{ hidden: { opacity: 0, y: 30 }, show: { opacity: 1, y: 0 } }}
                whileHover={{ y: -6, scale: 1.02 }}
                className={`bento-card relative flex flex-col ${
                  plan.highlighted
                    ? "ring-2 ring-primary/60 shadow-[0_0_40px_-10px_hsl(var(--primary)/0.3)]"
                    : ""
                }`}
              >
                {plan.highlighted && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 flex items-center gap-1 px-3 py-1 rounded-full bg-primary text-primary-foreground text-xs font-semibold">
                    <Star className="h-3 w-3" /> Najpopularniejszy
                  </div>
                )}
                <div className="mb-4">
                  <h3 className="font-display text-xl font-bold mb-1">{plan.name}</h3>
                  <p className="text-sm text-muted-foreground">{moduleName}</p>
                </div>
                <div className="mb-6">
                  <span className="font-display text-4xl font-bold">{price} zł</span>
                  <span className="text-muted-foreground text-sm ml-1">
                    / {yearly ? "rok" : "mies."}
                  </span>
                </div>
                <ul className="space-y-3 mb-8 flex-1">
                  {plan.features.map((f) => (
                    <li key={f} className="flex items-start gap-2 text-sm text-muted-foreground">
                      <CheckCircle2 className="h-4 w-4 text-primary shrink-0 mt-0.5" />
                      <span>{f}</span>
                    </li>
                  ))}
                </ul>
                <Button
                  onClick={() => onSelectPlan(plan, yearly)}
                  size="lg"
                  className={`w-full ${
                    plan.highlighted
                      ? "gradient-brand text-primary-foreground border-0"
                      : ""
                  }`}
                  variant={plan.highlighted ? "default" : "outline"}
                >
                  Wybierz plan
                </Button>
              </motion.div>
            );
          })}
        </motion.div>
      </div>
    </section>
  );
}
