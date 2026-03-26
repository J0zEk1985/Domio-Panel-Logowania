export function Footer() {
  return (
    <footer className="border-t border-border/50 py-12 px-4">
      <div className="container mx-auto max-w-6xl flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <img src="/logo ver 1.jpg" alt="DOMIO" className="h-6 w-6 rounded object-cover" />
          <span className="font-display font-semibold gradient-brand-text">DOMIO</span>
        </div>
        <p className="text-sm text-muted-foreground">© {new Date().getFullYear()} DOMIO Ecosystem Hub. Wszelkie prawa zastrzeżone.</p>
      </div>
    </footer>
  )
}
