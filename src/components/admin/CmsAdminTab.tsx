import { useCallback, useEffect, useMemo, useState } from 'react'
import { Loader2, Save } from 'lucide-react'
import { toast } from 'sonner'
import { supabase } from '../../lib/supabase'
import { inputClass } from './pricingAdminUtils'

const SHORT_TEXT_MAX_LEN = 100

export type PageContentRow = {
  content_key: string
  section_name: string
  description: string
  content_value: string
  sort_order: number
  updated_at: string | null
}

function groupBySection(rows: PageContentRow[]): Record<string, PageContentRow[]> {
  return rows.reduce<Record<string, PageContentRow[]>>((acc, row) => {
    const key = row.section_name
    if (!acc[key]) acc[key] = []
    acc[key].push(row)
    return acc
  }, {})
}

function sectionDisplayOrder(rows: PageContentRow[]): string[] {
  const sorted = [...rows].sort((a, b) => {
    if (a.section_name !== b.section_name) {
      return a.section_name.localeCompare(b.section_name, 'pl')
    }
    if (a.sort_order !== b.sort_order) return a.sort_order - b.sort_order
    return a.content_key.localeCompare(b.content_key)
  })
  const order: string[] = []
  const seen = new Set<string>()
  for (const r of sorted) {
    if (!seen.has(r.section_name)) {
      seen.add(r.section_name)
      order.push(r.section_name)
    }
  }
  return order
}

export default function CmsAdminTab() {
  const [rows, setRows] = useState<PageContentRow[]>([])
  const [editedContent, setEditedContent] = useState<Record<string, string>>({})
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  const loadRows = useCallback(async () => {
    setLoadError(null)
    setLoading(true)
    try {
      const { data, error } = await supabase
        .from('page_content')
        .select('content_key, section_name, description, content_value, sort_order, updated_at')
        .order('section_name', { ascending: true })
        .order('sort_order', { ascending: true })
        .order('content_key', { ascending: true })

      if (error) {
        console.error('[CmsAdminTab] loadRows:', error)
        setLoadError('Nie udało się pobrać treści (sprawdź migrację i polityki RLS).')
        setRows([])
        return
      }

      const list = (data as PageContentRow[]) ?? []
      setRows(list)
      setEditedContent(Object.fromEntries(list.map((r) => [r.content_key, r.content_value])))
    } catch (e) {
      console.error('[CmsAdminTab] loadRows:', e)
      setLoadError('Wystąpił błąd podczas ładowania treści.')
      setRows([])
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadRows()
  }, [loadRows])

  const originalByKey = useMemo(
    () => Object.fromEntries(rows.map((r) => [r.content_key, r.content_value])),
    [rows],
  )

  const grouped = useMemo(() => groupBySection(rows), [rows])
  const sectionOrder = useMemo(() => sectionDisplayOrder(rows), [rows])

  const hasChanges = useMemo(
    () => rows.some((r) => (editedContent[r.content_key] ?? '') !== r.content_value),
    [rows, editedContent],
  )

  const setField = (contentKey: string, value: string) => {
    setEditedContent((prev) => ({ ...prev, [contentKey]: value }))
  }

  const saveAll = async () => {
    if (!hasChanges || saving) return

    const changed = rows.filter(
      (r) => (editedContent[r.content_key] ?? '') !== r.content_value,
    )
    if (changed.length === 0) return

    setSaving(true)
    try {
      for (const row of changed) {
        const content_value = editedContent[row.content_key] ?? ''
        const { error } = await supabase
          .from('page_content')
          .update({ content_value, updated_at: new Date().toISOString() })
          .eq('content_key', row.content_key)

        if (error) {
          console.error('[CmsAdminTab] save:', error)
          toast.error('Nie udało się zapisać zmian.', {
            description: error.message || 'Spróbuj ponownie.',
          })
          return
        }
      }

      toast.success('Zapisano wszystkie zmiany.')
      await loadRows()
    } catch (e) {
      console.error('[CmsAdminTab] save:', e)
      toast.error('Wystąpił nieoczekiwany błąd podczas zapisu.')
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center gap-2 py-16 text-muted-foreground">
        <Loader2 className="h-5 w-5 animate-spin" />
        Ładowanie treści…
      </div>
    )
  }

  if (loadError) {
    return (
      <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl">
        {loadError}
      </div>
    )
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="font-display text-xl font-semibold">Treści strony (CMS)</h2>
          <p className="text-sm text-muted-foreground mt-1">
            Edytuj teksty wyświetlane na stronie publicznej. Zmiany zapisuj zbiorczo przyciskiem poniżej.
          </p>
        </div>
        <button
          type="button"
          onClick={() => void saveAll()}
          disabled={!hasChanges || saving}
          className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary text-primary-foreground px-4 py-2.5 text-sm font-medium shadow-sm hover:opacity-90 disabled:opacity-50 disabled:pointer-events-none transition-opacity shrink-0"
        >
          {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
          Zapisz wszystkie zmiany
        </button>
      </div>

      {rows.length === 0 ? (
        <p className="text-muted-foreground text-sm">Brak rekordów w tabeli page_content.</p>
      ) : (
        <div className="space-y-8">
          {sectionOrder.map((sectionName) => {
            const items = grouped[sectionName] ?? []
            if (items.length === 0) return null
            const sortedItems = [...items].sort(
              (a, b) => a.sort_order - b.sort_order || a.content_key.localeCompare(b.content_key),
            )
            return (
              <section
                key={sectionName}
                className="bento-card border border-border/60 overflow-hidden"
              >
                <header className="border-b border-border/50 px-5 py-4 bg-muted/30">
                  <h3 className="font-display text-lg font-semibold">{sectionName}</h3>
                </header>
                <div className="p-5 space-y-6">
                  {sortedItems.map((row) => {
                    const value = editedContent[row.content_key] ?? ''
                    const useTextarea =
                      value.length > SHORT_TEXT_MAX_LEN ||
                      value.includes('\n') ||
                      (originalByKey[row.content_key]?.length ?? 0) > SHORT_TEXT_MAX_LEN ||
                      (originalByKey[row.content_key]?.includes('\n') ?? false)

                    return (
                      <div key={row.content_key} className="space-y-2">
                        <label
                          htmlFor={`cms-${row.content_key}`}
                          className="block text-sm text-muted-foreground"
                        >
                          {row.description}
                        </label>
                        {useTextarea ? (
                          <textarea
                            id={`cms-${row.content_key}`}
                            value={value}
                            onChange={(e) => setField(row.content_key, e.target.value)}
                            rows={6}
                            className={`${inputClass} min-h-[120px] resize-y font-sans`}
                          />
                        ) : (
                          <input
                            id={`cms-${row.content_key}`}
                            type="text"
                            value={value}
                            onChange={(e) => setField(row.content_key, e.target.value)}
                            className={inputClass}
                          />
                        )}
                      </div>
                    )
                  })}
                </div>
              </section>
            )
          })}
        </div>
      )}

      {rows.length > 0 && (
        <div className="flex justify-end pt-2 border-t border-border/40">
          <button
            type="button"
            onClick={() => void saveAll()}
            disabled={!hasChanges || saving}
            className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary text-primary-foreground px-4 py-2.5 text-sm font-medium shadow-sm hover:opacity-90 disabled:opacity-50 disabled:pointer-events-none transition-opacity"
          >
            {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
            Zapisz wszystkie zmiany
          </button>
        </div>
      )}
    </div>
  )
}
