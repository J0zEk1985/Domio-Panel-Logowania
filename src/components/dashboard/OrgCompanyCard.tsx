import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { Building2 } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { inboundAliasPreview } from '../../lib/orgSlug'

type Props = {
  orgId: string
  canManage: boolean
}

export function OrgCompanyCard({ orgId, canManage }: Props) {
  const [name, setName] = useState<string | null>(null)
  const [slug, setSlug] = useState<string | null>(null)
  const [loadError, setLoadError] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoadError(null)
    try {
      const { data, error } = await supabase
        .from('organizations')
        .select('name, slug')
        .eq('id', orgId)
        .maybeSingle()
      if (error) {
        console.error('[OrgCompanyCard] load:', error)
        setLoadError('Nie udało się pobrać nazwy firmy.')
        return
      }
      const row = data as { name: string; slug: string } | null
      setName(row?.name?.trim() || null)
      setSlug(row?.slug?.trim() || null)
    } catch (e) {
      console.error('[OrgCompanyCard] load:', e)
      setLoadError('Nie udało się pobrać nazwy firmy.')
    }
  }, [orgId])

  useEffect(() => {
    void load()
  }, [load])

  const alias = slug ? inboundAliasPreview(slug) : null

  return (
    <section className="rounded-2xl border border-border bg-card p-5 space-y-3">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="font-display text-lg font-semibold flex items-center gap-2">
            <Building2 className="h-5 w-5 text-primary" aria-hidden />
            Dane firmy
          </h2>
          <p className="text-sm text-muted-foreground mt-1 max-w-2xl">
            Nazwa i identyfikator firmy wchodzą w skład aliasu e-mail zgłoszeń. Warto je ustawić
            zanim rozesłasz adres Domio.
          </p>
        </div>
        {canManage ? (
          <Link
            to="/firma"
            className="inline-flex h-9 items-center rounded-md border border-border px-3 text-sm font-medium hover:bg-muted/60"
          >
            Edytuj dane firmy
          </Link>
        ) : null}
      </div>
      {loadError ? <p className="text-sm text-destructive">{loadError}</p> : null}
      <div className="rounded-xl border border-border/70 bg-muted/30 px-4 py-3 space-y-1">
        <p className="font-medium">{name || 'Brak nazwy firmy'}</p>
        {alias ? (
          <p className="text-sm text-muted-foreground">
            Przykładowy alias:{' '}
            <code className="bg-muted px-1.5 py-0.5 rounded">{alias}</code>
          </p>
        ) : (
          <p className="text-sm text-muted-foreground">Brak identyfikatora używanego w aliasie.</p>
        )}
      </div>
      {!canManage ? (
        <p className="text-xs text-muted-foreground">
          Podgląd. Edycję danych firmy wykona właściciel lub administrator.
        </p>
      ) : null}
    </section>
  )
}
