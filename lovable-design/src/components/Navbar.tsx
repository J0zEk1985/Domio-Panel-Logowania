import { Link, useLocation } from "react-router-dom";
import { ThemeToggle } from "./ThemeToggle";
import { Button } from "@/components/ui/button";
import { LayoutDashboard, Shield, Menu, X } from "lucide-react";
import { useState } from "react";
import domioLogo from "@/assets/domio-logo.jpg";

export function Navbar() {
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);
  const isLanding = location.pathname === "/";

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 glass-strong">
      <div className="container mx-auto flex items-center justify-between h-16 px-4">
        <Link to="/" className="flex items-center gap-2">
          <img src={domioLogo} alt="DOMIO" className="h-8 w-8 rounded-lg object-cover" />
          <span className="font-display font-bold text-xl gradient-brand-text">DOMIO</span>
        </Link>

        {/* Desktop Nav */}
        <div className="hidden md:flex items-center gap-2">
          {isLanding && (
            <>
              <a href="#ecosystem" className="px-3 py-2 text-sm text-muted-foreground hover:text-foreground transition-colors">
                Ekosystem
              </a>
              <a href="#residents" className="px-3 py-2 text-sm text-muted-foreground hover:text-foreground transition-colors">
                Mieszkańcy
              </a>
              <a href="#business" className="px-3 py-2 text-sm text-muted-foreground hover:text-foreground transition-colors">
                Firmy
              </a>
            </>
          )}
          <ThemeToggle />
          <Link to="/dashboard">
            <Button variant="ghost" size="sm" className="gap-2">
              <LayoutDashboard className="h-4 w-4" /> Hub
            </Button>
          </Link>
          <Link to="/admin">
            <Button variant="ghost" size="sm" className="gap-2">
              <Shield className="h-4 w-4" /> Admin
            </Button>
          </Link>
          <Link to="/dashboard">
            <Button size="sm" className="gradient-brand text-primary-foreground border-0">
              Zaloguj się
            </Button>
          </Link>
        </div>

        {/* Mobile toggle */}
        <div className="flex md:hidden items-center gap-2">
          <ThemeToggle />
          <Button variant="ghost" size="icon" onClick={() => setMobileOpen(!mobileOpen)}>
            {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </Button>
        </div>
      </div>

      {/* Mobile Menu */}
      {mobileOpen && (
        <div className="md:hidden glass-strong border-t border-border/50 p-4 space-y-2">
          <Link to="/dashboard" onClick={() => setMobileOpen(false)}>
            <Button variant="ghost" className="w-full justify-start gap-2">
              <LayoutDashboard className="h-4 w-4" /> Hub
            </Button>
          </Link>
          <Link to="/admin" onClick={() => setMobileOpen(false)}>
            <Button variant="ghost" className="w-full justify-start gap-2">
              <Shield className="h-4 w-4" /> Admin
            </Button>
          </Link>
          <Link to="/dashboard" onClick={() => setMobileOpen(false)}>
            <Button className="w-full gradient-brand text-primary-foreground border-0">
              Zaloguj się
            </Button>
          </Link>
        </div>
      )}
    </nav>
  );
}
