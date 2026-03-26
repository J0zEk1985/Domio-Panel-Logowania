import { motion } from "framer-motion";
import { Home, Building2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";

export function ValueProposition() {
  return (
    <section className="py-24 px-4">
      <div className="container mx-auto max-w-5xl">
        <div className="grid md:grid-cols-2 gap-6">
          {/* Residents */}
          <motion.div
            id="residents"
            initial={{ opacity: 0, x: -30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="bento-card relative overflow-hidden group"
          >
            <div className="absolute top-0 right-0 w-32 h-32 bg-primary/5 rounded-full blur-2xl group-hover:bg-primary/10 transition-colors" />
            <div className="relative">
              <div className="p-3 rounded-xl bg-primary/10 text-primary w-fit mb-4">
                <Home className="h-8 w-8" />
              </div>
              <h3 className="font-display text-2xl font-bold mb-3">Dla Mieszkańców</h3>
              <p className="text-muted-foreground mb-6">
                Zarządzaj swoim mieszkaniem, zgłaszaj usterki, rezerwuj usługi — wszystko w jednej aplikacji. Prostota, która oszczędza Twój czas.
              </p>
              <Link to="/dashboard">
                <Button className="gradient-brand text-primary-foreground border-0">
                  Rozpocznij
                </Button>
              </Link>
            </div>
          </motion.div>

          {/* Businesses */}
          <motion.div
            id="business"
            initial={{ opacity: 0, x: 30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="bento-card relative overflow-hidden group"
          >
            <div className="absolute top-0 right-0 w-32 h-32 bg-accent/5 rounded-full blur-2xl group-hover:bg-accent/10 transition-colors" />
            <div className="relative">
              <div className="p-3 rounded-xl bg-accent/10 text-accent w-fit mb-4">
                <Building2 className="h-8 w-8" />
              </div>
              <h3 className="font-display text-2xl font-bold mb-3">Dla Firm</h3>
              <p className="text-muted-foreground mb-6">
                Skaluj swoje usługi, zarządzaj zespołami i klientami. Gotowe moduły biznesowe, które rosną razem z Tobą.
              </p>
              <Link to="/dashboard">
                <Button variant="outline" className="border-accent text-accent hover:bg-accent/10">
                  Dowiedz się więcej
                </Button>
              </Link>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
