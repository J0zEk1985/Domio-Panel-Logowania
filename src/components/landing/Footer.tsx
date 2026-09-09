import { useEffect, useState } from 'react'
import domioLogo from '../../../lovable-design/src/assets/domio-logo.jpg'
import { ContactDetails } from './ContactDetails'
import { hasVisibleContact, parsePlatformContact } from '../../lib/platformContact'
import { supabase } from '../../lib/supabase'

const DEFAULT_COPYRIGHT = `© ${new Date().getFullYear()} DOMIO. Wszelkie prawa zastrzeżone.`

type FooterProps = {
  /** Pełna linia z stopki CMS; jeśli brak — pobierana z page_content lub tekst z bieżącym rokiem. */
  copyrightLine?: string
}

export function Footer({ copyrightLine }: FooterProps) {
  const [resolvedCopyright, setResolvedCopyright] = useState(copyrightLine ?? '')
  const [contact, setContact] = useState(() => parsePlatformContact({}))

  useEffect(() => {
    setResolvedCopyright(copyrightLine ?? '')
  }, [copyrightLine])

  useEffect(() => {
    let cancelled = false
    void supabase
      .from('page_content')
      .select('content_key, content_value')
      .then(({ data, error }) => {
        if (cancelled) return
        if (error) {
          console.error('[Footer] page_content:', error)
          return
        }
        const map = (data ?? []).reduce<Record<string, string>>((acc, row) => {
          acc[row.content_key] = row.content_value ?? ''
          return acc
        }, {})
        setContact(parsePlatformContact(map))
        if (!copyrightLine?.trim()) {
          setResolvedCopyright((map.footer_copyright ?? '').trim())
        }
      })
    return () => {
      cancelled = true
    }
  }, [copyrightLine])

  const showContact = hasVisibleContact(contact)

  return (
    <footer className="border-t border-border/50 py-12 px-4">
      <div className="container mx-auto max-w-6xl space-y-8">
        {showContact ? <ContactDetails contact={contact} variant="footer" /> : null}
        <div className="flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <img src={domioLogo} alt="DOMIO" className="h-6 w-6 rounded object-cover" />
            <span className="font-display font-semibold gradient-brand-text">DOMIO</span>
          </div>
          <p className="text-sm text-muted-foreground">
            {resolvedCopyright.trim() ? resolvedCopyright : DEFAULT_COPYRIGHT}
          </p>
        </div>
      </div>
    </footer>
  )
}
