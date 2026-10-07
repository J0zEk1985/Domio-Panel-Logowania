/** City from a Polish address such as "Pienista 51, 94-109 Łódź, Polska". */
export function cityFromAddress(address: string | null | undefined): string | null {
  const parts = (address ?? '')
    .split(',')
    .map((part) => part.trim())
    .filter(Boolean)

  for (const part of parts) {
    const postal = part.match(/^\d{2}-\d{3}\s+(.+)$/)
    if (postal?.[1]) return postal[1]
  }

  if (parts.length >= 2) {
    const last = parts[parts.length - 1]
    const candidate = last.toLowerCase() === 'polska' ? parts[parts.length - 2] : last
    const withoutPostal = candidate.replace(/^\d{2}-\d{3}\s+/, '').trim()
    if (withoutPostal) return withoutPostal
  }

  return null
}
