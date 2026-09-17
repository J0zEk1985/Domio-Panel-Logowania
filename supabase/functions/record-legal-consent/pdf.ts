import { PDFDocument, rgb, type PDFFont } from 'https://esm.sh/pdf-lib@1.17.1'
import fontkit from 'https://esm.sh/@pdf-lib/fontkit@1.0.0'
import { OPEN_SANS_REGULAR_TTF } from './openSansRegular.ts'

/** Open Sans Regular (Apache License 2.0) — bundled for Polish glyphs. */

export type LegalPdfDocument = {
  id?: string
  document_type: string
  version: string
  content: string
  content_hash: string
  active_from: string
}

export type LegalPdfMeta = {
  email: string
  acceptedAt: string
  ipAddress: string | null
  userAgent: string | null
  documents: LegalPdfDocument[]
}

const DOC_TITLES: Record<string, string> = {
  terms: 'Regulamin',
  privacy: 'Polityka prywatności',
  marketing: 'Zgody marketingowe',
}

const PAGE_WIDTH = 595.28
const PAGE_HEIGHT = 841.89
const MARGIN = 56
const FONT_SIZE_BODY = 10
const FONT_SIZE_TITLE = 16
const FONT_SIZE_HEADING = 13
const LINE_HEIGHT = 14

function wrapLine(font: PDFFont, text: string, fontSize: number, maxWidth: number): string[] {
  if (text === '') return ['']
  const words = text.split(/\s+/)
  const lines: string[] = []
  let current = ''

  const splitLong = (word: string) => {
    let rest = word
    while (rest.length > 0) {
      let lo = 1
      let hi = rest.length
      let fit = 1
      while (lo <= hi) {
        const mid = Math.floor((lo + hi) / 2)
        const slice = rest.slice(0, mid)
        if (font.widthOfTextAtSize(slice, fontSize) <= maxWidth) {
          fit = mid
          lo = mid + 1
        } else {
          hi = mid - 1
        }
      }
      lines.push(rest.slice(0, fit))
      rest = rest.slice(fit)
    }
  }

  for (const word of words) {
    const next = current ? `${current} ${word}` : word
    if (font.widthOfTextAtSize(next, fontSize) <= maxWidth) {
      current = next
      continue
    }
    if (current) lines.push(current)
    if (font.widthOfTextAtSize(word, fontSize) <= maxWidth) {
      current = word
    } else {
      splitLong(word)
      current = ''
    }
  }
  if (current) lines.push(current)
  return lines.length > 0 ? lines : ['']
}

function wrapParagraphs(font: PDFFont, text: string, fontSize: number, maxWidth: number): string[] {
  const source = (text ?? '').replace(/\r\n/g, '\n').replace(/\r/g, '\n')
  const out: string[] = []
  for (const para of source.split('\n')) {
    out.push(...wrapLine(font, para, fontSize, maxWidth))
  }
  return out
}

function formatWarsaw(iso: string): string {
  try {
    return new Intl.DateTimeFormat('pl-PL', {
      dateStyle: 'medium',
      timeStyle: 'medium',
      timeZone: 'Europe/Warsaw',
    }).format(new Date(iso))
  } catch {
    return iso
  }
}

async function loadFontBytes(): Promise<Uint8Array> {
  return OPEN_SANS_REGULAR_TTF
}

export async function buildLegalAcceptancePdf(meta: LegalPdfMeta): Promise<Uint8Array> {
  const pdf = await PDFDocument.create()
  pdf.registerFontkit(fontkit)
  const font = await pdf.embedFont(await loadFontBytes(), { subset: true })
  const maxWidth = PAGE_WIDTH - MARGIN * 2
  const ink = rgb(0.12, 0.12, 0.14)

  let page = pdf.addPage([PAGE_WIDTH, PAGE_HEIGHT])
  let y = PAGE_HEIGHT - MARGIN

  const ensureSpace = (need: number) => {
    if (y - need < MARGIN) {
      page = pdf.addPage([PAGE_WIDTH, PAGE_HEIGHT])
      y = PAGE_HEIGHT - MARGIN
    }
  }

  const drawLines = (lines: string[], size: number, height: number) => {
    for (const line of lines) {
      ensureSpace(height)
      page.drawText(line || ' ', {
        x: MARGIN,
        y: y - size,
        size,
        font,
        color: ink,
      })
      y -= height
    }
  }

  drawLines(wrapParagraphs(font, 'DOMIO — potwierdzenie akceptacji dokumentów', FONT_SIZE_TITLE, maxWidth), FONT_SIZE_TITLE, 22)
  y -= 8
  drawLines(wrapParagraphs(font, 'Trwały nośnik: treść obowiązująca w chwili akceptacji.', FONT_SIZE_BODY, maxWidth), FONT_SIZE_BODY, LINE_HEIGHT)
  y -= 10

  const cover = [
    `Adres e-mail: ${meta.email}`,
    `Data i godzina akceptacji: ${formatWarsaw(meta.acceptedAt)} (Europe/Warsaw)`,
    `Adres IP: ${meta.ipAddress || 'nieustalony'}`,
    `Przeglądarka: ${meta.userAgent || 'nieustalona'}`,
    '',
    'Zestawienie dokumentów:',
  ]
  drawLines(wrapParagraphs(font, cover.join('\n'), FONT_SIZE_BODY, maxWidth), FONT_SIZE_BODY, LINE_HEIGHT)

  for (const doc of meta.documents) {
    const title = DOC_TITLES[doc.document_type] ?? doc.document_type
    const row = `• ${title} — wersja ${doc.version} — SHA-256 treści ${doc.content_hash}`
    drawLines(wrapParagraphs(font, row, FONT_SIZE_BODY, maxWidth), FONT_SIZE_BODY, LINE_HEIGHT)
  }

  y -= 12
  drawLines(
    wrapParagraphs(
      font,
      'Poniżej znajduje się pełna treść zaakceptowanych dokumentów. Zmiana regulaminu na serwerze nie zmienia tego pliku.',
      FONT_SIZE_BODY,
      maxWidth,
    ),
    FONT_SIZE_BODY,
    LINE_HEIGHT,
  )

  for (const doc of meta.documents) {
    page = pdf.addPage([PAGE_WIDTH, PAGE_HEIGHT])
    y = PAGE_HEIGHT - MARGIN
    const title = DOC_TITLES[doc.document_type] ?? doc.document_type
    drawLines(
      wrapParagraphs(font, `${title} (wersja ${doc.version})`, FONT_SIZE_HEADING, maxWidth),
      FONT_SIZE_HEADING,
      20,
    )
    y -= 6
    drawLines(wrapParagraphs(font, doc.content ?? '', FONT_SIZE_BODY, maxWidth), FONT_SIZE_BODY, LINE_HEIGHT)
  }

  const bytes = await pdf.save()
  return bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes)
}

export async function sha256Hex(bytes: Uint8Array): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', bytes)
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}
