import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { motion } from "framer-motion";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Users, Server, DollarSign, Shield,
  Sparkles, Car, Building2, Wrench,
  CreditCard, Scale, Layout,
} from "lucide-react";
import { useState } from "react";
import { PricingManager } from "@/components/admin/PricingManager";
import { LegalEditor } from "@/components/admin/LegalEditor";
import { LandingContentManager } from "@/components/admin/LandingContentManager";

const metrics = [
  { label: "Aktywni użytkownicy", value: "1,247", icon: Users, change: "+12%" },
  { label: "Instancje VPS", value: "38", icon: Server, change: "+3" },
  { label: "Przychód (mies.)", value: "48,200 zł", icon: DollarSign, change: "+8.5%" },
];

interface Customer {
  id: string;
  name: string;
  email: string;
  type: "standard" | "simplified";
  modules: { name: string; icon: React.ElementType; enabled: boolean }[];
}

const initialCustomers: Customer[] = [
  {
    id: "1",
    name: "Anna Kowalska",
    email: "anna@example.com",
    type: "standard",
    modules: [
      { name: "Cleaning", icon: Sparkles, enabled: true },
      { name: "Flota", icon: Car, enabled: false },
      { name: "Nieruchomości", icon: Building2, enabled: true },
    ],
  },
  {
    id: "2",
    name: "Jan Nowak",
    email: "jan@example.com",
    type: "simplified",
    modules: [
      { name: "Cleaning", icon: Sparkles, enabled: true },
      { name: "Flota", icon: Car, enabled: true },
      { name: "Serwis", icon: Wrench, enabled: false },
    ],
  },
  {
    id: "3",
    name: "Maria Wiśniewska",
    email: "maria@example.com",
    type: "standard",
    modules: [
      { name: "Cleaning", icon: Sparkles, enabled: false },
      { name: "Nieruchomości", icon: Building2, enabled: true },
      { name: "Serwis", icon: Wrench, enabled: true },
    ],
  },
];

const Admin = () => {
  const [customers, setCustomers] = useState(initialCustomers);

  const toggleModule = (customerId: string, moduleName: string) => {
    setCustomers((prev) =>
      prev.map((c) =>
        c.id === customerId
          ? {
              ...c,
              modules: c.modules.map((m) =>
                m.name === moduleName ? { ...m, enabled: !m.enabled } : m
              ),
            }
          : c
      )
    );
  };

  return (
    <div className="min-h-screen">
      <Navbar />
      <div className="pt-24 pb-16 px-4">
        <div className="container mx-auto max-w-6xl">
          {/* Header */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="mb-10"
          >
            <h1 className="font-display text-3xl md:text-4xl font-bold mb-2 flex items-center gap-3">
              <Shield className="h-8 w-8 text-primary" />
              Panel <span className="gradient-brand-text">Administratora</span>
            </h1>
            <p className="text-muted-foreground text-lg">Zarządzaj platformą, użytkownikami i modułami.</p>
          </motion.div>

          {/* Metrics */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="grid sm:grid-cols-3 gap-4 mb-12"
          >
            {metrics.map((m) => (
              <div key={m.label} className="bento-card">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 rounded-xl bg-muted">
                    <m.icon className="h-5 w-5 text-primary" />
                  </div>
                  <span className="text-xs text-primary font-medium bg-primary/5 px-2 py-1 rounded-full">
                    {m.change}
                  </span>
                </div>
                <p className="text-sm text-muted-foreground mb-1">{m.label}</p>
                <p className="font-display text-2xl font-bold">{m.value}</p>
              </div>
            ))}
          </motion.div>

          {/* CMS Tabs */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.15 }}
            className="mb-12"
          >
            <Tabs defaultValue="pricing" className="w-full">
              <TabsList className="w-full sm:w-auto mb-6 h-auto flex-wrap">
                <TabsTrigger value="pricing" className="gap-2">
                  <CreditCard className="h-4 w-4" /> Cennik i promocje
                </TabsTrigger>
                <TabsTrigger value="legal" className="gap-2">
                  <Scale className="h-4 w-4" /> Dokumenty prawne
                </TabsTrigger>
                <TabsTrigger value="landing" className="gap-2">
                  <Layout className="h-4 w-4" /> Treści strony
                </TabsTrigger>
              </TabsList>

              <TabsContent value="pricing">
                <PricingManager />
              </TabsContent>
              <TabsContent value="legal">
                <LegalEditor />
              </TabsContent>
              <TabsContent value="landing">
                <LandingContentManager />
              </TabsContent>
            </Tabs>
          </motion.div>

          {/* Customer List */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.25 }}
          >
            <h2 className="font-display text-xl font-semibold mb-4">Klienci</h2>
            <div className="space-y-4">
              {customers.map((customer) => (
                <div key={customer.id} className="bento-card">
                  <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full gradient-brand flex items-center justify-center text-primary-foreground font-semibold text-sm">
                        {customer.name.charAt(0)}
                      </div>
                      <div>
                        <p className="font-semibold">{customer.name}</p>
                        <p className="text-sm text-muted-foreground">{customer.email}</p>
                      </div>
                      <Badge
                        variant="outline"
                        className={
                          customer.type === "standard"
                            ? "bg-primary/10 text-primary border-primary/20"
                            : "bg-muted text-muted-foreground"
                        }
                      >
                        {customer.type === "standard" ? "Standard" : "Uproszczony"}
                      </Badge>
                    </div>
                    <div className="flex items-center gap-4 flex-wrap">
                      {customer.modules.map((mod) => (
                        <div key={mod.name} className="flex items-center gap-2">
                          <mod.icon className="h-4 w-4 text-muted-foreground" />
                          <span className="text-sm">{mod.name}</span>
                          <Switch
                            checked={mod.enabled}
                            onCheckedChange={() => toggleModule(customer.id, mod.name)}
                          />
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </motion.div>
        </div>
      </div>
      <Footer />
    </div>
  );
};

export default Admin;
