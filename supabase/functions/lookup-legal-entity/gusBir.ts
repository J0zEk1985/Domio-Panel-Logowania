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

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

function decodeXmlEntities(value: string): string {
  return value
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&amp;/g, '&')
}

/** Exact tag match so `Miejscowosc` does not capture `MiejscowoscPoczty`. */
function xmlTag(xml: string, tag: string): string | null {
  const t = escapeRegExp(tag)
  const re = new RegExp(
    `<(?:[\\w-]+:)?${t}(?:\\s[^>]*)?>([\\s\\S]*?)</(?:[\\w-]+:)?${t}\\s*>`,
    'i',
  )
  const m = xml.match(re)
  if (!m) return null
  const raw = decodeXmlEntities(m[1]).trim()
  return raw.length ? raw : null
}

function firstXmlValue(xml: string, tags: string[]): string | null {
  for (const tag of tags) {
    const value = xmlTag(xml, tag)
    if (value) return value
  }
  return null
}

function unwrapBirResult(soapXml: string, resultTag: string): string {
  const raw = xmlTag(soapXml, resultTag)
  if (!raw) return soapXml
  if (raw.includes('<')) return raw
  const once = decodeXmlEntities(raw)
  return once.includes('<') ? once : raw
}

function reportCandidates(typ: string | null, silos: string | null): string[] {
  const t = (typ ?? '').toUpperCase()
  const s = (silos ?? '').trim()
  if (t === 'P') {
    return ['PublDaneRaportPrawna', 'BIR11OsPrawna', 'BIR12OsPrawna']
  }
  if (t === 'LP') {
    return ['PublDaneRaportLokalnaPrawnej', 'BIR11JednLokalnaOsPrawnej', 'BIR12JednLokalnaOsPrawnej']
  }
  if (t === 'LF') {
    return ['PublDaneRaportLokalnaFizycznej', 'BIR11JednLokalnaOsFizycznej', 'BIR12JednLokalnaOsFizycznej']
  }
  const bySilo: Record<string, string[]> = {
    '1': [
      'PublDaneRaportDzialalnoscFizycznejCeidg',
      'BIR11OsFizycznaDzialalnoscCeidg',
      'BIR12OsFizycznaDzialalnoscCeidg',
    ],
    '2': [
      'PublDaneRaportDzialalnoscFizycznejRolnicza',
      'BIR11OsFizycznaDzialalnoscRolnicza',
      'BIR12OsFizycznaDzialalnoscRolnicza',
    ],
    '3': [
      'PublDaneRaportDzialalnosciFizycznej',
      'BIR11OsFizycznaDzialalnoscPozostala',
      'BIR12OsFizycznaDzialalnoscPozostala',
    ],
    '4': [
      'PublDaneRaportDzialalnoscFizycznejSkreslonaDo20141108',
      'BIR11OsFizycznaDzialalnoscSkreslonaDo20141108',
      'BIR12OsFizycznaDzialalnoscSkreslonaDo20141108',
    ],
  }
  return [
    ...(bySilo[s] ?? bySilo['1']),
    'PublDaneRaportFizycznaOsoba',
    'BIR11OsFizycznaDaneOgolne',
    'BIR12OsFizycznaDaneOgolne',
  ]
}

function reportLooksUseful(payload: string): boolean {
  if (payload.length < 30) return false
  return /<(?:[\w-]+:)?(?:praw_|fiz_|lokpraw_|lokfiz_|fizC_)/i.test(payload)
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

function toPreview(searchInner: string, reportInner: string): GusPreview | null {
  const blob = `${searchInner}\n${reportInner}`
  const legalName = xmlTag(searchInner, 'Nazwa')
  const nip = (xmlTag(searchInner, 'Nip') ?? xmlTag(reportInner, 'praw_nip') ?? xmlTag(reportInner, 'fiz_nip') ?? '').replace(/\D/g, '')
  if (!legalName || nip.length !== 10) return null

  const street = firstXmlValue(blob, [
    'Ulica',
    'praw_adSiedzUlica_Nazwa',
    'fiz_adSiedzUlica_Nazwa',
    'lokpraw_adSiedzUlica_Nazwa',
    'lokfiz_adSiedzUlica_Nazwa',
    'praw_adKorUlica_Nazwa',
    'fiz_adKorUlica_Nazwa',
  ])
  const buildingNumber = firstXmlValue(blob, [
    'NrNieruchomosci',
    'praw_adSiedzNumerNieruchomosci',
    'fiz_adSiedzNumerNieruchomosci',
    'lokpraw_adSiedzNumerNieruchomosci',
    'lokfiz_adSiedzNumerNieruchomosci',
  ])
  const apartmentNumber = firstXmlValue(blob, [
    'NrLokalu',
    'praw_adSiedzNumerLokalu',
    'fiz_adSiedzNumerLokalu',
    'lokpraw_adSiedzNumerLokalu',
    'lokfiz_adSiedzNumerLokalu',
  ])
  const city = firstXmlValue(blob, [
    'Miejscowosc',
    'praw_adSiedzMiejscowosc_Nazwa',
    'fiz_adSiedzMiejscowosc_Nazwa',
    'lokpraw_adSiedzMiejscowosc_Nazwa',
    'lokfiz_adSiedzMiejscowosc_Nazwa',
    'MiejscowoscPoczty',
    'praw_adSiedzMiejscowoscPoczty_Nazwa',
    'fiz_adSiedzMiejscowoscPoczty_Nazwa',
  ])
  const postalCode = formatPostal(
    firstXmlValue(blob, [
      'KodPocztowy',
      'praw_adSiedzKodPocztowy',
      'fiz_adSiedzKodPocztowy',
      'lokpraw_adSiedzKodPocztowy',
      'lokfiz_adSiedzKodPocztowy',
    ]),
  )
  const seatFullAddress = [street, buildingNumber, apartmentNumber, postalCode, city]
    .filter(Boolean)
    .join(', ')

  const formName =
    firstXmlValue(reportInner, ['praw_formaPrawna', 'fiz_formaPrawna', 'praw_szczegolnaFormaPrawna_Nazwa']) ??
    null
  const krs =
    firstXmlValue(blob, ['praw_numerWRejestrzeEwidencji', 'Krs']) ??
    null

  return {
    nip,
    regon: (xmlTag(searchInner, 'Regon') ?? '').replace(/\D/g, ''),
    krs: krs ? krs.replace(/\D/g, '') || null : null,
    legalName,
    voivodeship:
      firstXmlValue(blob, ['Wojewodztwo', 'praw_adSiedzWojewodztwo_Nazwa', 'fiz_adSiedzWojewodztwo_Nazwa']) ??
      null,
    county: firstXmlValue(blob, ['Powiat', 'praw_adSiedzPowiat_Nazwa', 'fiz_adSiedzPowiat_Nazwa']),
    commune: firstXmlValue(blob, ['Gmina', 'praw_adSiedzGmina_Nazwa', 'fiz_adSiedzGmina_Nazwa']),
    city,
    postalCode,
    street,
    buildingNumber,
    apartmentNumber,
    seatFullAddress,
    legalFormCode: xmlTag(reportInner, 'praw_formaPrawna_NazwaSzczegolna'),
    legalFormName: formName,
    typ: xmlTag(searchInner, 'Typ'),
    endedAt: xmlTag(searchInner, 'DataZakonczeniaDzialalnosci'),
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

    const searchInner = unwrapBirResult(searchXml, 'DaneSzukajPodmiotyResult')
    const regon = xmlTag(searchInner, 'Regon')
    const typ = xmlTag(searchInner, 'Typ')
    const silos = xmlTag(searchInner, 'SilosID')
    let reportInner = ''
    if (regon) {
      for (const reportName of reportCandidates(typ, silos)) {
        try {
          const reportXml = await soapCall(
            'DanePobierzPelnyRaport',
            `<ns:DanePobierzPelnyRaport>
            <ns:pRegon>${regon}</ns:pRegon>
            <ns:pNazwaRaportu>${reportName}</ns:pNazwaRaportu>
          </ns:DanePobierzPelnyRaport>`,
            sid,
          )
          const payload = unwrapBirResult(reportXml, 'DanePobierzPelnyRaportResult')
          if (reportLooksUseful(payload)) {
            reportInner = payload
            break
          }
        } catch {
          continue
        }
      }
    }

    const preview = toPreview(searchInner, reportInner)
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
