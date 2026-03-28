import domioLogo from '../../../lovable-design/src/assets/domio-logo.jpg'

const DEFAULT_COPYRIGHT = `© ${new Date().getFullYear()} DOMIO. Wszelkie prawa zastrzeżone.`

type FooterProps = {
  /** Pełna linia z stopki CMS; jeśli brak — domyślny tekst z bieżącym rokiem. */
  copyrightLine?: string
}

export function Footer({ copyrightLine }: FooterProps) {
  return (
    <footer className="border-t border-border/50 py-12 px-4">
      <div className="container mx-auto max-w-6xl flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <img src={domioLogo} alt="DOMIO" className="h-6 w-6 rounded object-cover" />
          <span className="font-display font-semibold gradient-brand-text">DOMIO</span>
        </div>
        <p className="text-sm text-muted-foreground">{copyrightLine?.trim() ? copyrightLine : DEFAULT_COPYRIGHT}</p>
      </div>
    </footer>
  )
}
