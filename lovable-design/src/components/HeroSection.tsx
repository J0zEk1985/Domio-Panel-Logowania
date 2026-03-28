import { motion, useScroll, useTransform } from "framer-motion";
import { ArrowDown } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";
import domioLogo from "@/assets/domio-logo.jpg";

export function HeroSection() {
  const { scrollY } = useScroll();
  const logoScale = useTransform(scrollY, [0, 400], [1, 0.3]);
  const logoOpacity = useTransform(scrollY, [0, 300], [1, 0]);
  const logoY = useTransform(scrollY, [0, 400], [0, -200]);
  const textY = useTransform(scrollY, [0, 300], [0, -50]);
  const textOpacity = useTransform(scrollY, [0, 250], [1, 0]);

  return (
    <section className="relative min-h-screen flex flex-col items-center justify-center overflow-hidden px-4">
      {/* Background decorations */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 rounded-full bg-primary/5 blur-3xl animate-float" />
        <div className="absolute bottom-1/4 right-1/4 w-80 h-80 rounded-full bg-accent/5 blur-3xl animate-float" style={{ animationDelay: "3s" }} />
      </div>

      {/* Animated Logo */}
      <motion.div
        style={{ scale: logoScale, opacity: logoOpacity, y: logoY }}
        className="mb-8"
      >
        <div className="relative">
          <div className="absolute inset-0 rounded-3xl bg-primary/20 blur-2xl animate-glow" />
          <img
            src={domioLogo}
            alt="DOMIO Logo"
            className="relative w-40 h-40 md:w-56 md:h-56 rounded-3xl object-cover shadow-2xl"
          />
        </div>
      </motion.div>

      {/* Title */}
      <motion.div
        style={{ y: textY, opacity: textOpacity }}
        className="text-center max-w-3xl"
      >
        <h1 className="font-display text-5xl md:text-7xl font-bold tracking-tight mb-4">
          <span className="gradient-brand-text">DOMIO</span>
        </h1>
        <p className="text-lg md:text-xl text-muted-foreground max-w-xl mx-auto mb-8 text-balance">
          Jeden ekosystem aplikacji dla mieszkańców i firm. Zarządzaj, kontroluj, rozwijaj — wszystko w jednym miejscu.
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Link to="/dashboard">
            <Button size="lg" className="gradient-brand text-primary-foreground border-0 px-8 text-base">
              Zaloguj się
            </Button>
          </Link>
          <a href="#ecosystem">
            <Button size="lg" variant="outline" className="px-8 text-base">
              Odkryj DOMIO
            </Button>
          </a>
        </div>
      </motion.div>

      {/* Scroll hint */}
      <motion.div
        className="absolute bottom-8"
        animate={{ y: [0, 10, 0] }}
        transition={{ duration: 2, repeat: Infinity }}
      >
        <ArrowDown className="h-6 w-6 text-muted-foreground" />
      </motion.div>
    </section>
  );
}
