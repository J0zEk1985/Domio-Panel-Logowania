import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../../lib/supabase'
import { DOC_LABELS, type LegalDocType } from './legalAdminTypes'
import { formatDateTime } from './usersAndOrgsUtils'

type ConsentRow = {
  id: string
  batch_id: string
  document_type: string
  document_version: string
  accepted_at: string
  ip_address: string | null
  acceptance_hash: string
}

type DispatchRow = {
  batch_id: string
  status: string
  sent_at: string | null
}

type Props = {
  userId: string
}

function docLabel(type: string): string {
  return DOC_LABELS[type as LegalDocType] ?? type
}

function dispatchLabel(status: string | undefined, sentAt: string | null): string {
  if (status === 'sent') return sentAt ? `Wysłano ${formatDateTime(sentAt)}` : 'Wysłano'
  if (status === 'pending' || status === 'processing') return 'Oczekuje na wysyłkę'
  if (status === 'failed') return 'Błąd wysyłki'
  return '—'
}

export default function UserDetailLegalConsents({ userId }: Props) {
  const [rows, setRows] = useState<ConsentRow[]>([])
  const [dispatchByBatch, setDispatchByBatch] = useState<Record<string, DispatchRow>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [verifyNote, setVerifyNote] = useState<string | null>(null)

  const load = useCallback(async () => {
    setError(null)
    setLoading(true)
    try {
      const consentsRes = await supabase
        .from('user_consents')
        .select('id,batch_id,document_type,document_version,accepted_at,ip_address,acceptance_hash')
        .eq('user_id', userId)
        .order('accepted_at', { ascending: false })

      if (consentsRes.error) {
        console.error('[UserDetailLegalConsents]', consentsRes.error)
        setError('Nie udało się pobrać logu zgód.')
        setRows([])
        return
      }

      const consents = (consentsRes.data as ConsentRow[]) ?? []
      setRows(consents)

      const batchIds = [...new Set(consents.map((row) => row.batch_id))]
      if (batchIds.length === 0) {
        setDispatchByBatch({})
        return
      }

      const dispatchRes = await supabase
        .from('legal_welcome_dispatches')
        .select('batch_id,status,sent_at')
        .in('batch_id', batchIds)

      if (dispatchRes.error) {
        console.error('[UserDetailLegalConsents] dispatches:', dispatchRes.error)
        setDispatchByBatch({})
        return
      }

      const map: Record<string, DispatchRow> = {}
      for (const row of (dispatchRes.data as DispatchRow[]) ?? []) {
        map[row.batch_id] = row
      }
      setDispatchByBatch(map)
    } catch (e) {
      console.error('[UserDetailLegalConsents] load:', e)
      setError('Wystąpił błąd podczas ładowania zgód.')
    } finally {
      setLoading(false)
    }
  }, [userId])

  useEffect(() => {
    void load()
  }, [load])

  const verify = async (consentId: string) => {
    setVerifyNote(null)
    const { data, error: rpcError } = await supabase.rpc('verify_user_consent', {
      p_consent_id: consentId,
    })
    if (rpcError) {
      console.error('[UserDetailLegalConsents] verify:', rpcError)
      setVerifyNote('Nie udało się zweryfikować hasha.')
      return
    }
    const rec = data && typeof data === 'object' ? (data as Record<string, unknown>) : {}
    if (rec.hash_matches === true) {
      setVerifyNote('Hash zgody jest zgodny z solą serwerową i PDF.')
    } else {
      setVerifyNote(`Hash niezgodny (${String(rec.reason ?? 'hash_mismatch')}).`)
    }
  }

  return (
    <section className="bento-card p-6 space-y-4">
      <h2 className="font-display text-lg font-semibold">Log zgód (trwały nośnik)</h2>
      <p className="text-xs text-muted-foreground">
        Źródło prawdy to ten log, nie pole „akceptacja regulaminu” w profilu. Cache profilu może być nieaktualny.
      </p>
      {error && (
        <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
          {error}
        </div>
      )}
      {verifyNote && <p className="text-sm text-muted-foreground">{verifyNote}</p>}
      {loading ? (
        <p className="text-sm text-muted-foreground">Ładowanie logu zgód…</p>
      ) : rows.length === 0 ? (
        <p className="text-sm text-muted-foreground">Brak wpisów w user_consents.</p>
      ) : (
        <div className="overflow-x-auto -mx-6 px-6 sm:mx-0 sm:px-0">
          <table className="w-full text-sm min-w-[40rem]">
            <thead>
              <tr className="border-b border-border/60 text-left text-muted-foreground">
                <th className="p-3 font-medium">Dokument</th>
                <th className="p-3 font-medium">Wersja</th>
                <th className="p-3 font-medium">Czas</th>
                <th className="p-3 font-medium">IP</th>
                <th className="p-3 font-medium">Hash</th>
                <th className="p-3 font-medium">E-mail PDF</th>
                <th className="p-3 font-medium text-right">Audyt</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => {
                const dispatch = dispatchByBatch[row.batch_id]
                return (
                  <tr key={row.id} className="border-b border-border/40 last:border-0 align-top">
                    <td className="p-3">{docLabel(row.document_type)}</td>
                    <td className="p-3">{row.document_version}</td>
                    <td className="p-3">{formatDateTime(row.accepted_at)}</td>
                    <td className="p-3 font-mono text-xs">{row.ip_address ?? '—'}</td>
                    <td className="p-3 font-mono text-xs break-all">{row.acceptance_hash.slice(0, 16)}…</td>
                    <td className="p-3">{dispatchLabel(dispatch?.status, dispatch?.sent_at ?? null)}</td>
                    <td className="p-3 text-right">
                      <button
                        type="button"
                        onClick={() => void verify(row.id)}
                        className="text-primary text-xs font-medium hover:underline"
                      >
                        Sprawdź hash
                      </button>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}
    </section>
  )
}
