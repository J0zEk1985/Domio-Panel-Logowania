const SOAP_NS = 'http://www.w3.org/2003/05/soap-envelope'
const WSA_NS = 'http://www.w3.org/2005/08/addressing'
const BIR_NS = 'http://CIS/BIR/PUBL/2014/07'
const BIR_DATA_NS = 'http://CIS/BIR/PUBL/2014/07/DataContract'

export type GusPreview = {
  nip: string
  regon: string
  krs: string | null
  legalName: string
  voivodeship: string | null
  county: string | null
  commune: string | null
  city: string | null
  postalCode: string | null
  street: string | null
  buildingNumber: string | null
  apartmentNumber: string | null
  seatFullAddress: string
  legalFormCode: string | null
  legalFormName: string | null
  typ: string | null
  endedAt: string | null
}

/** Public GUS BIR test key from the official instruction. Production key: GUS_BIR_KEY. */
const GUS_BIR_PUBLIC_TEST_KEY = 'abcde12345abcde12345'

function birEnv(): 'test' | 'prod' {
  const explicit = (Deno.env.get('GUS_BIR_ENV') ?? '').toLowerCase()
  if (explicit === 'test' || explicit === 'prod') return explicit
  return Deno.env.get('GUS_BIR_KEY')?.trim() ? 'prod' : 'test'
}

function birKey(): string {
  return Deno.env.get('GUS_BIR_KEY')?.trim() || GUS_BIR_PUBLIC_TEST_KEY
}

function endpoint(): string {
  if (birEnv() === 'test') {
    return 'https://wyszukiwarkaregontest.stat.gov.pl/wsBIR/UslugaBIRzewnPubl.svc'
  }
  return 'https://wyszukiwarkaregon.stat.gov.pl/wsBIR/UslugaBIRzewnPubl.svc'
}

function xmlTag(xml: string, tag: string): string | null {
  const re = new RegExp(`<(?:[\\w-]+:)?${tag}[^>]*>([\\s\\S]*?)</(?:[\\w-]+:)?${tag}>`, 'i')
  const m = xml.match(re)
  if (!m) return null
  const raw = m[1]
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .trim()
  return raw.length ? raw : null
}

function envelope(action: string, body: string): string {
  const url = endpoint()
  return `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="${SOAP_NS}" xmlns:ns="${BIR_NS}" xmlns:dat="${BIR_DATA_NS}">
  <soap:Header xmlns:wsa="${WSA_NS}">
    <wsa:To>${url}</wsa:To>
    <wsa:Action>${BIR_NS}/IUslugaBIRzewnPubl/${action}</wsa:Action>
  </soap:Header>
  <soap:Body>${body}</soap:Body>
</soap:Envelope>`
}

async function soapCall(action: string, body: string, sid?: string): Promise<string> {
  const url = endpoint()
  const headers: Record<string, string> = {
    'Content-Type': 'application/soap+xml; charset=utf-8',
  }
  if (sid) headers.sid = sid
  const res = await fetch(url, {
    method: 'POST',
    headers,
    body: envelope(action, body),
  })
  const text = await res.text()
  if (!res.ok) {
    throw new Error(`GUS_HTTP_${res.status}`)
  }
  return text
}

function formatPostal(raw: string | null): string | null {
  if (!raw) return null
  const digits = raw.replace(/\D/g, '')
  if (digits.length === 5) return `${digits.slice(0, 2)}-${digits.slice(2)}`
  if (/^\d{2}-\d{3}$/.test(raw.trim())) return raw.trim()
  return null
}

function mapKind(legalName: string, formName: string | null): 'housing_community' | 'housing_cooperative' | 'property_manager' | 'company' {
  const blob = `${legalName} ${formName ?? ''}`.toUpperCase()
  const folded = blob
    .replace(/Ł/g, 'L')
    .replace(/Ń/g, 'N')
    .replace(/Ó/g, 'O')
    .replace(/Ś/g, 'S')
    .replace(/Ź|Ż/g, 'Z')
    .replace(/Ą/g, 'A')
    .replace(/Ć/g, 'C')
    .replace(/Ę/g, 'E')
  if (folded.includes('SPOLDZIELNIA')) return 'housing_cooperative'
  if (folded.includes('WSPOLNOTA')) return 'housing_community'
  if (folded.includes('ZARZADCA') || folded.includes('ZARZAD NIERUCHOM')) return 'property_manager'
  return 'company'
}

function toPreview(searchXml: string, reportXml: string | null): GusPreview | null {
  const inner = xmlTag(searchXml, 'DaneSzukajPodmiotyResult') ?? searchXml
  const legalName = xmlTag(inner, 'Nazwa')
  const nip = (xmlTag(inner, 'Nip') ?? '').replace(/\D/g, '')
  if (!legalName || nip.length !== 10) return null

  const street = xmlTag(inner, 'Ulica')
  const buildingNumber = xmlTag(inner, 'NrNieruchomosci') ?? xmlTag(reportXml ?? '', 'praw_adSiedzNumerNieruchomosci')
  const apartmentNumber = xmlTag(inner, 'NrLokalu')
  const city = xmlTag(inner, 'Miejscowosc')
  const postalCode = formatPostal(xmlTag(inner, 'KodPocztowy'))
  const seatFullAddress = [street, buildingNumber, apartmentNumber, postalCode, city]
    .filter(Boolean)
    .join(', ')

  const formName =
    xmlTag(reportXml ?? '', 'praw_formaPrawna') ??
    xmlTag(reportXml ?? '', 'fiz_formaPrawna') ??
    null
  const krs =
    xmlTag(reportXml ?? '', 'praw_numerWRejestrzeEwidencji') ??
    xmlTag(inner, 'Krs') ??
    null

  return {
    nip,
    regon: (xmlTag(inner, 'Regon') ?? '').replace(/\D/g, ''),
    krs: krs ? krs.replace(/\D/g, '') || null : null,
    legalName,
    voivodeship: xmlTag(inner, 'Wojewodztwo'),
    county: xmlTag(inner, 'Powiat'),
    commune: xmlTag(inner, 'Gmina'),
    city,
    postalCode,
    street,
    buildingNumber,
    apartmentNumber,
    seatFullAddress,
    legalFormCode: xmlTag(reportXml ?? '', 'praw_formaPrawna_NazwaSzczegolna'),
    legalFormName: formName,
    typ: xmlTag(inner, 'Typ'),
    endedAt: xmlTag(inner, 'DataZakonczeniaDzialalnosci'),
  }
}

export async function fetchGusByNip(nip: string): Promise<{ preview: GusPreview | null; suggestedKind: ReturnType<typeof mapKind> }> {
  const key = birKey()

  const loginXml = await soapCall(
    'Zaloguj',
    `<ns:Zaloguj><ns:pKluczUzytkownika>${key}</ns:pKluczUzytkownika></ns:Zaloguj>`,
  )
  const sid = xmlTag(loginXml, 'ZalogujResult')
  if (!sid) throw new Error('GUS_LOGIN_FAILED')

  try {
    const searchXml = await soapCall(
      'DaneSzukajPodmioty',
      `<ns:DaneSzukajPodmioty>
        <ns:pParametryWyszukiwania>
          <dat:Nip>${nip}</dat:Nip>
        </ns:pParametryWyszukiwania>
      </ns:DaneSzukajPodmioty>`,
      sid,
    )

    const regon = xmlTag(xmlTag(searchXml, 'DaneSzukajPodmiotyResult') ?? searchXml, 'Regon')
    const typ = xmlTag(xmlTag(searchXml, 'DaneSzukajPodmiotyResult') ?? searchXml, 'Typ')
    let reportXml: string | null = null
    if (regon) {
      const reportName = typ === 'F' || typ === 'LF'
        ? 'PublDaneRaportDzialalnoscFizycznejCeidg'
        : 'PublDaneRaportPrawna'
      try {
        reportXml = await soapCall(
          'DanePobierzPelnyRaport',
          `<ns:DanePobierzPelnyRaport>
            <ns:pRegon>${regon}</ns:pRegon>
            <ns:pNazwaRaportu>${reportName}</ns:pNazwaRaportu>
          </ns:DanePobierzPelnyRaport>`,
          sid,
        )
      } catch {
        reportXml = null
      }
    }

    const preview = toPreview(searchXml, reportXml)
    if (!preview) return { preview: null, suggestedKind: 'company' }
    return { preview, suggestedKind: mapKind(preview.legalName, preview.legalFormName) }
  } finally {
    try {
      await soapCall('Wyloguj', `<ns:Wyloguj><ns:pIdentyfikatorSesji>${sid}</ns:pIdentyfikatorSesji></ns:Wyloguj>`, sid)
    } catch {
      // Session expires on its own.
    }
  }
}
