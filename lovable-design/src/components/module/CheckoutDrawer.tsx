import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Lock, CheckCircle2, CreditCard, Smartphone, Building2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import {
  Drawer,
  DrawerContent,
  DrawerHeader,
  DrawerTitle,
  DrawerDescription,
} from "@/components/ui/drawer";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { useIsMobile } from "@/hooks/use-mobile";
import type { PricingPlan } from "./PricingSection";

interface CheckoutDrawerProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  moduleName: string;
  plan: PricingPlan | null;
  yearly: boolean;
}

function CheckoutContent({
  moduleName,
  plan,
  yearly,
  onClose,
}: {
  moduleName: string;
  plan: PricingPlan;
  yearly: boolean;
  onClose: () => void;
}) {
  const [paymentMethod, setPaymentMethod] = useState("card");
  const [processing, setProcessing] = useState(false);
  const [success, setSuccess] = useState(false);

  const price = yearly ? plan.yearlyPrice : plan.monthlyPrice;
  const cycle = yearly ? "Rocznie" : "Miesięcznie";

  const handlePay = () => {
    setProcessing(true);
    setTimeout(() => {
      setProcessing(false);
      setSuccess(true);
    }, 1800);
  };

  return (
    <div className="p-6 space-y-6 max-h-[80vh] overflow-y-auto">
      <AnimatePresence mode="wait">
        {success ? (
          <motion.div
            key="success"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="flex flex-col items-center justify-center py-12 text-center"
          >
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: "spring", stiffness: 200, delay: 0.2 }}
              className="p-4 rounded-full bg-primary/10 mb-6"
            >
              <CheckCircle2 className="h-12 w-12 text-primary" />
            </motion.div>
            <h3 className="font-display text-2xl font-bold mb-2">Płatność zakończona!</h3>
            <p className="text-muted-foreground mb-6">
              {moduleName} — {plan.name} został aktywowany.
            </p>
            <Button onClick={onClose} className="gradient-brand text-primary-foreground border-0">
              Gotowe
            </Button>
          </motion.div>
        ) : (
          <motion.div key="form" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="space-y-6">
            {/* Order Summary */}
            <div className="rounded-xl bg-muted/50 border border-border/50 p-4 space-y-2">
              <h4 className="font-display font-semibold text-sm text-muted-foreground uppercase tracking-wider">
                Podsumowanie zamówienia
              </h4>
              <div className="flex justify-between items-center">
                <div>
                  <p className="font-semibold">{moduleName}</p>
                  <p className="text-sm text-muted-foreground">Plan {plan.name} · {cycle}</p>
                </div>
                <p className="font-display text-xl font-bold">{price} zł</p>
              </div>
            </div>

            {/* Payment Method */}
            <div className="space-y-3">
              <Label className="text-sm font-semibold">Metoda płatności</Label>
              <RadioGroup value={paymentMethod} onValueChange={setPaymentMethod} className="grid gap-2">
                {[
                  { value: "card", label: "Karta kredytowa", icon: CreditCard },
                  { value: "blik", label: "BLIK", icon: Smartphone },
                  { value: "payu", label: "PayU / Przelewy24", icon: Building2 },
                ].map((m) => (
                  <label
                    key={m.value}
                    className={`flex items-center gap-3 rounded-xl border px-4 py-3 cursor-pointer transition-colors ${
                      paymentMethod === m.value
                        ? "border-primary bg-primary/5"
                        : "border-border/50 bg-muted/30 hover:bg-muted/50"
                    }`}
                  >
                    <RadioGroupItem value={m.value} />
                    <m.icon className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm font-medium">{m.label}</span>
                  </label>
                ))}
              </RadioGroup>
            </div>

            {/* Billing Details */}
            <div className="space-y-3">
              <Label className="text-sm font-semibold">Dane do faktury</Label>
              <Input placeholder="Imię i nazwisko" />
              <Input placeholder="Firma (opcjonalnie)" />
              <Input placeholder="NIP (opcjonalnie)" />
            </div>

            {/* CTA */}
            <Button
              onClick={handlePay}
              disabled={processing}
              size="lg"
              className="w-full gradient-brand text-primary-foreground border-0 gap-2"
            >
              <Lock className="h-4 w-4" />
              {processing ? "Przetwarzanie..." : `Potwierdź i zapłać · ${price} zł`}
            </Button>
            <p className="text-xs text-center text-muted-foreground">
              Płatność jest bezpieczna i szyfrowana SSL.
            </p>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

export function CheckoutDrawer({ open, onOpenChange, moduleName, plan, yearly }: CheckoutDrawerProps) {
  const isMobile = useIsMobile();

  if (!plan) return null;

  const content = (
    <CheckoutContent
      moduleName={moduleName}
      plan={plan}
      yearly={yearly}
      onClose={() => onOpenChange(false)}
    />
  );

  if (isMobile) {
    return (
      <Drawer open={open} onOpenChange={onOpenChange}>
        <DrawerContent>
          <DrawerHeader>
            <DrawerTitle>Zamówienie</DrawerTitle>
            <DrawerDescription>Dokończ zakup modułu</DrawerDescription>
          </DrawerHeader>
          {content}
        </DrawerContent>
      </Drawer>
    );
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Zamówienie</DialogTitle>
          <DialogDescription>Dokończ zakup modułu</DialogDescription>
        </DialogHeader>
        {content}
      </DialogContent>
    </Dialog>
  );
}
