import { Building2, Mail, MapPin, Phone } from 'lucide-react'
import { usePlatformContact } from '../../hooks/usePlatformContact'
import {
  buildOrganizationJsonLd,
  hasVisibleContact,
  toMailtoHref,
  toTelHref,
  type PlatformContact,
} from '../../lib/platformContact'

type ContactDetailsProps = {
  contact: PlatformContact
  variant: 'auth' | 'footer'
}

function ContactLines({ contact }: { contact: PlatformContact }) {
  return (
    <address className="not-italic space-y-2">
      {contact.name ? (
        <p className="font-semibold" itemProp="name">
          {contact.name}
        </p>
      ) : null}
      {(contact.address || contact.registeredOffice) && (
        <div itemProp="address" itemScope itemType="https://schema.org/PostalAddress">
          {contact.registeredOffice ? (
            <p className="flex items-start gap-2">
              <Building2 className="h-4 w-4 mt-0.5 shrink-0 opacity-70" aria-hidden />
              <span>
                <span className="block text-xs uppercase tracking-wide opacity-70">Siedziba</span>
                <span itemProp="addressLocality">{contact.registeredOffice}</span>
              </span>
            </p>
          ) : null}
          {contact.address ? (
            <p className="flex items-start gap-2 whitespace-pre-line">
              <MapPin className="h-4 w-4 mt-0.5 shrink-0 opacity-70" aria-hidden />
              <span>
                <span className="block text-xs uppercase tracking-wide opacity-70">Adres</span>
                <span itemProp="streetAddress">{contact.address}</span>
              </span>
            </p>
          ) : null}
        </div>
      )}
      {contact.phone ? (
        <p className="flex items-start gap-2">
          <Phone className="h-4 w-4 mt-0.5 shrink-0 opacity-70" aria-hidden />
          <span>
            <span className="block text-xs uppercase tracking-wide opacity-70">Telefon</span>
            <span>{contact.phone}</span>
          </span>
        </p>
      ) : null}
      {contact.email ? (
        <p className="flex items-start gap-2">
          <Mail className="h-4 w-4 mt-0.5 shrink-0 opacity-70" aria-hidden />
          <span>
            <span className="block text-xs uppercase tracking-wide opacity-70">E-mail</span>
            <span>{contact.email}</span>
          </span>
        </p>
      ) : null}
    </address>
  )
}

function ActionButtons({
  contact,
  variant,
}: {
  contact: PlatformContact
  variant: ContactDetailsProps['variant']
}) {
  const telHref = toTelHref(contact.phone)
  const mailHref = toMailtoHref(contact.email)
  if (!telHref && !mailHref) return null

  const isAuth = variant === 'auth'
  const callClass = isAuth
    ? 'inline-flex items-center justify-center gap-2 rounded-md bg-gray-800 text-white py-2.5 px-4 text-sm font-medium hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2'
    : 'inline-flex items-center justify-center gap-2 rounded-md gradient-brand text-primary-foreground px-4 py-2.5 text-sm font-medium hover:opacity-90'
  const mailClass = isAuth
    ? 'inline-flex items-center justify-center gap-2 rounded-md border border-gray-300 bg-white text-gray-700 py-2.5 px-4 text-sm font-medium hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2'
    : 'inline-flex items-center justify-center gap-2 rounded-md border border-border bg-background px-4 py-2.5 text-sm font-medium hover:bg-muted/60'

  return (
    <div className={`flex flex-col sm:flex-row gap-3 ${isAuth ? '' : 'md:justify-end'}`}>
      {telHref ? (
        <a
          href={telHref}
          className={`${callClass} w-full ${isAuth ? 'sm:flex-1' : 'sm:w-auto'}`}
          aria-label={`Zadzwoń: ${contact.phone}`}
        >
          <Phone className="h-4 w-4" aria-hidden />
          Zadzwoń
        </a>
      ) : null}
      {mailHref ? (
        <a
          href={mailHref}
          className={`${mailClass} w-full ${isAuth ? 'sm:flex-1' : 'sm:w-auto'}`}
          aria-label={`Napisz e-mail: ${contact.email}`}
        >
          <Mail className="h-4 w-4" aria-hidden />
          Napisz e-mail
        </a>
      ) : null}
    </div>
  )
}

export function AuthContactSlot() {
  const { contact, loading } = usePlatformContact()
  if (loading) return null
  return <ContactDetails contact={contact} variant="auth" />
}

export function ContactDetails({ contact, variant }: ContactDetailsProps) {
  if (!hasVisibleContact(contact)) return null

  const jsonLd = buildOrganizationJsonLd(contact)

  if (variant === 'auth') {
    return (
      <section
        className="bg-white rounded-lg shadow-lg p-8"
        aria-labelledby="auth-contact-heading"
        itemScope
        itemType="https://schema.org/Organization"
      >
        {jsonLd ? (
          <script
            type="application/ld+json"
            dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd).replace(/</g, '\\u003c') }}
          />
        ) : null}
        <h2 id="auth-contact-heading" className="text-lg font-bold text-gray-900 mb-1">
          Kontakt
        </h2>
        <p className="text-sm text-gray-600 mb-5">Potrzebujesz pomocy? Zadzwoń lub napisz do nas.</p>
        <div className="space-y-5 text-sm text-gray-700">
          <ContactLines contact={contact} />
          <ActionButtons contact={contact} variant="auth" />
        </div>
      </section>
    )
  }

  return (
    <div
      className="w-full"
      aria-labelledby="footer-contact-heading"
      itemScope
      itemType="https://schema.org/Organization"
    >
      {jsonLd ? (
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd).replace(/</g, '\\u003c') }}
        />
      ) : null}
      <div className="grid gap-6 md:grid-cols-2 md:items-start">
        <div className="space-y-3 text-sm text-muted-foreground">
          <h2 id="footer-contact-heading" className="font-display text-base font-semibold text-foreground">
            Dane kontaktowe
          </h2>
          <ContactLines contact={contact} />
        </div>
        <ActionButtons contact={contact} variant="footer" />
      </div>
    </div>
  )
}
