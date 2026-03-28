import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Sparkles, Car, Building2, Wrench, ShieldCheck,
  ShoppingCart, TrendingUp, Zap
} from "lucide-react";

interface UserModule {
  name: string;
  icon: React.ElementType;
  status: "active" | "free" | "trial";
  description: string;
}

const activeModules: UserModule[] = [
  { name: "Cleaning DOMIO", icon: Sparkles, status: "active", description: "Zarządzanie usługami sprzątania" },
  { name: "Nieruchomości DOMIO", icon: Building2, status: "active", description: "Zarządzanie nieruchomościami" },
  { name: "Bezpieczeństwo DOMIO", icon: ShieldCheck, status: "free", description: "Kontrola dostępu" },
];

interface MarketplaceModule {
  name: string;
  icon: React.ElementType;
  price: string;
  description: string;
  suggestion?: string;
}

const marketplaceModules: MarketplaceModule[] = [
  { name: "Flota DOMIO", icon: Car, price: "49 zł/mies.", description: "Zarządzanie flotą pojazdów", suggestion: "Skoro korzystasz z Cleaning, wypróbuj Flotę!" },
  { name: "Serwis DOMIO", icon: Wrench, price: "39 zł/mies.", description: "Zgłoszenia serwisowe i naprawy" },
];

const statusColors: Record<string, string> = {
  active: "bg-primary/10 text-primary border-primary/20",
  free: "bg-accent/10 text-accent border-accent/20",
  trial: "bg-muted text-muted-foreground border-border",
};

const statusLabels: Record<string, string> = {
  active: "Aktywny",
  free: "Darmowy",
  trial: "Trial",
};

const Dashboard = () => {
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
            <h1 className="font-display text-3xl md:text-4xl font-bold mb-2">
              Witaj w <span className="gradient-brand-text">panelu DOMIO</span>
            </h1>
            <p className="text-muted-foreground text-lg">Zarządzaj swoimi modułami i odkrywaj nowe możliwości.</p>
          </motion.div>

          {/* Active Modules */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="mb-12"
          >
            <h2 className="font-display text-xl font-semibold mb-4 flex items-center gap-2">
              <Zap className="h-5 w-5 text-primary" /> Moje Moduły
            </h2>
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {activeModules.map((mod) => (
                <div key={mod.name} className="bento-card">
                  <div className="flex items-start justify-between mb-3">
                    <div className="p-2.5 rounded-xl bg-muted">
                      <mod.icon className="h-5 w-5 text-primary" />
                    </div>
                    <Badge variant="outline" className={statusColors[mod.status]}>
                      {statusLabels[mod.status]}
                    </Badge>
                  </div>
                  <h3 className="font-display font-semibold mb-1">{mod.name}</h3>
                  <p className="text-sm text-muted-foreground">{mod.description}</p>
                  <Button size="sm" variant="ghost" className="mt-4 text-primary">
                    Otwórz →
                  </Button>
                </div>
              ))}
            </div>
          </motion.div>

          {/* Marketplace */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
          >
            <h2 className="font-display text-xl font-semibold mb-4 flex items-center gap-2">
              <ShoppingCart className="h-5 w-5 text-accent" /> Marketplace
            </h2>
            <div className="grid sm:grid-cols-2 gap-4">
              {marketplaceModules.map((mod) => (
                <div key={mod.name} className="bento-card relative overflow-hidden">
                  {mod.suggestion && (
                    <div className="flex items-center gap-1.5 mb-3 text-xs text-primary bg-primary/5 px-3 py-1.5 rounded-full w-fit">
                      <TrendingUp className="h-3 w-3" />
                      {mod.suggestion}
                    </div>
                  )}
                  <div className="flex items-start gap-4">
                    <div className="p-2.5 rounded-xl bg-muted">
                      <mod.icon className="h-5 w-5 text-accent" />
                    </div>
                    <div className="flex-1">
                      <h3 className="font-display font-semibold mb-1">{mod.name}</h3>
                      <p className="text-sm text-muted-foreground mb-3">{mod.description}</p>
                      <div className="flex items-center justify-between">
                        <span className="font-display font-bold text-foreground">{mod.price}</span>
                        <Button size="sm" className="gradient-brand text-primary-foreground border-0">
                          Kup moduł
                        </Button>
                      </div>
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

export default Dashboard;
