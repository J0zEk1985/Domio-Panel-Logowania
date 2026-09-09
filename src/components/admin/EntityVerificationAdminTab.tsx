import { useCallback, useEffect, useState } from 'react'
import { AlertTriangle, Loader2, RefreshCw, ShieldCheck } from 'lucide-react'
import {
  countPlatformVerificationAlerts,
  listPlatformVerificationAlerts,
  resolveLegalEntityVerification,
  retryLegalEntityGus,
  LegalEntityAdminApiError,
  type PlatformVerificationAlert,
} from '../../lib/legalEntityAdminApi'
import { LEGAL_ENTITY_KIND_LABELS } from '../../lib/legalEntityMessages'

function formatDateTime(iso: string): string {
  try {
    return new Intl.DateTimeFormat('pl-PL', {
      dateStyle: 'short',
      timeStyle: 'short',
    }).format(new Date(iso))
  } catch {
    return '—'
  }
}

export default function EntityVerificationAdminTab({
  onCountChange,
}: {
  onCountChange?: (count: number) => void
}) {
  const [rows, setRows] = useState<PlatformVerificationAlert[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [busyId, setBusyId] = useState<string | null>(null)

  const load = useCallback(async () => {
    setError(null)
    setLoading(true)
    try {
      const [list, count] = await Promise.all([
        listPlatformVerificationAlerts(),
        countPlatformVerificationAlerts(),
      ])
      setRows(list)
      onCountChange?.(count)
    } catch (e) {
      console.error('[EntityVerificationAdminTab] load:', e)
      setError(e instanceof LegalEntityAdminApiError ? e.message : 'Nie udało się pobrać kolejki weryfikacji.')
      setRows([])
      onCountChange?.(0)
    } finally {
      setLoading(false)
    }
  }, [onCountChange])

  useEffect(() => {
    void load()
  }, [load])

  const onRetry = async (id: string) => {
    setBusyId(id)
    setError(null)
    try {
      await retryLegalEntityGus(id)
      await load()
    } catch (e) {
      console.error('[EntityVerificationAdminTab] retry:', e)
      setError(e instanceof LegalEntityAdminApiError ? e.message : 'Nie udało się ponowić GUS.')
    } finally {
      setBusyId(null)
    }
  }

  const onResolve = async (id: string) => {
    setBusyId(id)
    setError(null)
    try {
      await resolveLegalEntityVerification(id)
      await load()
    } catch (e) {
      console.error('[EntityVerificationAdminTab] resolve:', e)
      setError(e instanceof LegalEntityAdminApiError ? e.message : 'Nie udało się oznaczyć jako sprawdzone.')
    } finally {
      setBusyId(null)
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="font-display text-xl font-semibold">Podmioty do sprawdzenia</h2>
          <p className="text-sm text-muted-foreground">
            Dodane przy awarii GUS. Ponów BIR albo oznacz ręcznie jako sprawdzone.
          </p>
        </div>
        <button
          type="button"
          onClick={() => void load()}
          className="inline-flex items-center gap-2 rounded-xl border border-border px-3 py-2 text-sm hover:bg-muted"
          disabled={loading}
        >
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
          Odśwież
        </button>
      </div>

      {error ? (
        <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
          {error}
        </div>
      ) : null}

      <div className="bento-card overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border/60 text-left text-muted-foreground">
              <th className="p-4 font-medium">Podmiot</th>
              <th className="p-4 font-medium">NIP</th>
              <th className="p-4 font-medium">Organizacja</th>
              <th className="p-4 font-medium">Dodano</th>
              <th className="p-4 font-medium text-right">Akcje</th>
            </tr>
          </thead>
          <tbody>
            {!loading &&
              rows.map((row) => (
                <tr key={row.legalEntityId} className="border-b border-border/40 last:border-0">
                  <td className="p-4">
                    <p className="font-medium">{row.shortName}</p>
                    <p className="text-xs text-muted-foreground">{LEGAL_ENTITY_KIND_LABELS[row.kind]}</p>
                  </td>
                  <td className="p-4 tabular-nums">{row.nip}</td>
                  <td className="p-4 text-muted-foreground">{row.orgName?.trim() || '—'}</td>
                  <td className="p-4 text-muted-foreground">{formatDateTime(row.createdAt)}</td>
                  <td className="p-4">
                    <div className="flex justify-end gap-2">
                      <button
                        type="button"
                        className="inline-flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-xs font-medium hover:bg-muted disabled:opacity-50"
                        disabled={busyId === row.legalEntityId}
                        onClick={() => void onRetry(row.legalEntityId)}
                      >
                        {busyId === row.legalEntityId ? (
                          <Loader2 className="h-3.5 w-3.5 animate-spin" />
                        ) : (
                          <AlertTriangle className="h-3.5 w-3.5" />
                        )}
                        Ponów GUS
                      </button>
                      <button
                        type="button"
                        className="inline-flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-xs font-medium hover:bg-muted disabled:opacity-50"
                        disabled={busyId === row.legalEntityId}
                        onClick={() => void onResolve(row.legalEntityId)}
                      >
                        <ShieldCheck className="h-3.5 w-3.5" />
                        Oznacz jako sprawdzone
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
          </tbody>
        </table>
        {loading ? (
          <div className="p-8 text-center text-muted-foreground">Ładowanie kolejki…</div>
        ) : null}
        {!loading && rows.length === 0 && !error ? (
          <div className="p-8 text-center text-muted-foreground">Brak podmiotów oczekujących na weryfikację.</div>
        ) : null}
      </div>
    </div>
  )
}
