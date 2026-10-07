import { useMemo, useState } from 'react'
import { inputClass } from '../pricingAdminUtils'
import type { CleaningLocationRow } from '../partnerOffersTypes'

type Props = {
  locations: CleaningLocationRow[]
  selectedIds: string[]
  onChange: (selectedIds: string[]) => void
}

function locationLabel(location: CleaningLocationRow): string {
  const name = location.name?.trim()
  const address = location.address?.trim()
  if (name && address) return `${name} — ${address}`
  return name || address || 'Brak adresu'
}

export default function OfferLocationPicker({ locations, selectedIds, onChange }: Props) {
  const [query, setQuery] = useState('')

  const locationsByCity = useMemo(() => {
    const needle = query.trim().toLocaleLowerCase('pl-PL')
    const filtered = needle
      ? locations.filter((location) => {
          const haystack = [locationLabel(location), location.city, location.orgName]
            .filter(Boolean)
            .join(' ')
            .toLocaleLowerCase('pl-PL')
          return haystack.includes(needle)
        })
      : locations

    const grouped = filtered.reduce<Record<string, CleaningLocationRow[]>>((acc, location) => {
      const city = location.city?.trim() || 'Inne'
      if (!acc[city]) acc[city] = []
      acc[city].push(location)
      return acc
    }, {})

    return Object.entries(grouped)
      .sort(([cityA], [cityB]) => cityA.localeCompare(cityB, 'pl-PL'))
      .map(([city, cityLocations]) => ({
        city,
        locations: [...cityLocations].sort((a, b) => locationLabel(a).localeCompare(locationLabel(b), 'pl-PL')),
      }))
  }, [locations, query])

  const visibleIds = useMemo(
    () => locationsByCity.flatMap((group) => group.locations.map((location) => location.id)),
    [locationsByCity],
  )

  const toggleLocation = (locationId: string) => {
    if (selectedIds.includes(locationId)) {
      onChange(selectedIds.filter((id) => id !== locationId))
      return
    }
    onChange([...selectedIds, locationId])
  }

  const setVisibleSelected = (selected: boolean) => {
    const visible = new Set(visibleIds)
    if (selected) {
      onChange([...new Set([...selectedIds, ...visibleIds])])
      return
    }
    onChange(selectedIds.filter((id) => !visible.has(id)))
  }

  const allVisibleSelected = visibleIds.length > 0 && visibleIds.every((id) => selectedIds.includes(id))

  return (
    <div className="space-y-2">
      <h4 className="font-medium">Targetowanie lokalizacji (opcjonalnie)</h4>
      <p className="text-xs text-muted-foreground">
        Możesz zaznaczyć wiele lokalizacji. Brak zaznaczenia oznacza ofertę globalną.
        {selectedIds.length > 0 ? ` Wybrano: ${selectedIds.length}.` : ''}
      </p>
      <input
        className={inputClass}
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Szukaj po adresie, mieście lub organizacji"
        aria-label="Szukaj lokalizacji"
      />
      {visibleIds.length > 0 && (
        <label className="inline-flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={allVisibleSelected}
            onChange={(e) => setVisibleSelected(e.target.checked)}
          />
          <span>{allVisibleSelected ? 'Odznacz widoczne' : 'Zaznacz widoczne'}</span>
        </label>
      )}
      <div className="rounded-xl border border-border p-3 max-h-[240px] overflow-y-auto space-y-3">
        {locations.length === 0 && (
          <div className="text-sm text-muted-foreground">Brak lokalizacji do wyboru.</div>
        )}
        {locations.length > 0 && locationsByCity.length === 0 && (
          <div className="text-sm text-muted-foreground">Brak lokalizacji pasujących do wyszukiwania.</div>
        )}
        {locationsByCity.map((group) => (
          <div key={group.city} className="space-y-2">
            <div className="text-sm font-semibold">{group.city}</div>
            <div className="space-y-1.5">
              {group.locations.map((location) => (
                <label key={location.id} className="flex items-start gap-2 text-sm">
                  <input
                    type="checkbox"
                    checked={selectedIds.includes(location.id)}
                    onChange={() => toggleLocation(location.id)}
                  />
                  <span>
                    {locationLabel(location)}
                    {location.orgName ? (
                      <span className="block text-xs text-muted-foreground">{location.orgName}</span>
                    ) : null}
                  </span>
                </label>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
