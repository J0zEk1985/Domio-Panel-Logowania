import { useEffect, useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import {
  fetchClientIp,
  recordPlatformLegalConsent,
} from '../lib/legalConsentApi'
import { DOC_LABELS, DOC_PATHS, formatPublishedLegal, type LegalDocType } from './admin/legalAdminTypes'
import type { LegalConsentSource, PendingRequiredLegalDocument } from '../types/database'

type Props = {
  documents: PendingRequiredLegalDocument[]
  onAccepted: () => void
}

const OPTIONAL_TYPES: LegalDocType[] = ['marketing', 'cookies']

function labelFor(type: string): string {
  return DOC_LABELS[type as LegalDocType] ?? type
}

function pathFor(type: string): string {
  return DOC_PATHS[type as LegalDocType] ?? '/regulamin'
}

export default function LegalConsentWall({ documents, onAccepted }: Props) {
  const [accepted, setAccepted] = useState<Record<string, boolean>>({})
  const [optionalDocs, setOptionalDocs] = useState<PendingRequiredLegalDocument[]>([])
  const [hasPriorConsent, setHasPriorConsent] = useState(false)
  const [optionsLoading, setOptionsLoading] = useState(true)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false

    const loadOptional = async () => {
      setOptionsLoading(true)
      try {
        const [docsRes, consentsRes] = await Promise.all([
          supabase
            .from('legal_documents')
            .select('id, document_type, version, active_from')
            .eq('is_active', true)
            .in('document_type', OPTIONAL_TYPES),
          supabase.from('user_consents').select('id, document_id'),
        ])

        if (cancelled) return

        if (docsRes.error) {
          console.error('[LegalConsentWall] optional documents:', docsRes.error)
        }
        if (consentsRes.error) {
          console.error('[LegalConsentWall] existing consents:', consentsRes.error)
        }

        const consents = consentsRes.data ?? []
        setHasPriorConsent(consents.length > 0)
        const acceptedIds = new Set(consents.map((row) => row.document_id))
        const requiredIds = new Set(documents.map((doc) => doc.id))

        const optional = ((docsRes.data ?? []) as PendingRequiredLegalDocument[])
          .filter((doc) => doc.id && !acceptedIds.has(doc.id) && !requiredIds.has(doc.id))
          .sort(
            (a, b) =>
              OPTIONAL_TYPES.indexOf(a.document_type as LegalDocType) -
              OPTIONAL_TYPES.indexOf(b.document_type as LegalDocType),
          )
        setOptionalDocs(optional)
      } catch (err) {
        console.error('[LegalConsentWall] load optional:', err)
        if (!cancelled) setOptionalDocs([])
      } finally {
        if (!cancelled) setOptionsLoading(false)
      }
    }

    void loadOptional()
    return () => {
      cancelled = true
    }
  }, [documents])

  const allRequiredChecked = documents.every((doc) => accepted[doc.id])

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)
    if (!allRequiredChecked) {
      setError('Musisz zaakceptować wszystkie wymagane dokumenty.')
      return
    }
    setLoading(true)
    try {
      const { data: userData } = await supabase.auth.getUser()
      const provider = String(userData.user?.app_metadata?.provider ?? 'email')
      const source: LegalConsentSource = hasPriorConsent
        ? 'reacceptance'
        : provider === 'email'
          ? 'signup_email'
          : 'signup_oauth'

      const acceptedDocumentIds = [
        ...documents.map((doc) => doc.id),
        ...optionalDocs.filter((doc) => accepted[doc.id]).map((doc) => doc.id),
      ]

      const ipAddress = await fetchClientIp()
      const result = await recordPlatformLegalConsent({
        acceptedDocumentIds,
        source,
        ipAddress,
      })
      if (!result.ok) {
        throw new Error(result.error || 'Nie udało się zapisać akceptacji.')
      }
      onAccepted()
    } catch (err) {
      console.error('[LegalConsentWall]', err)
      setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas zapisu zgody.')
    } finally {
      setLoading(false)
    }
  }

  const signOut = async () => {
    await supabase.auth.signOut()
    window.location.href = '/login'
  }

  const title = optionsLoading
    ? 'Dokumenty prawne'
    : hasPriorConsent
      ? 'Aktualizacja dokumentów prawnych'
      : 'Zaakceptuj dokumenty prawne'

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4 py-10">
      <div className="bento-card w-full max-w-lg p-8 space-y-6 border border-border">
        <div className="space-y-2">
          <h1 className="font-display text-2xl font-semibold">{title}</h1>
          <p className="text-sm text-muted-foreground">
            Żeby korzystać z DOMIO, zaakceptuj aktualne dokumenty. Na Twój e-mail wyślemy ich treść w pliku PDF
            (trwały nośnik).
          </p>
        </div>

        <form onSubmit={(e) => void handleSubmit(e)} className="space-y-4">
          {documents.map((doc) => (
            <div key={doc.id} className="flex items-start gap-3">
              <input
                id={`wall-accept-${doc.id}`}
                type="checkbox"
                checked={Boolean(accepted[doc.id])}
                onChange={(e) =>
                  setAccepted((prev) => ({ ...prev, [doc.id]: e.target.checked }))
                }
                className="mt-1 h-4 w-4 rounded border-input text-primary focus:ring-ring"
              />
              <label htmlFor={`wall-accept-${doc.id}`} className="text-sm leading-relaxed">
                Akceptuję{' '}
                <Link
                  to={pathFor(doc.document_type)}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-primary underline"
                >
                  {labelFor(doc.document_type)}
                </Link>
                {' '}z dnia {formatPublishedLegal(doc.active_from)} (wersja {doc.version}) *
              </label>
            </div>
          ))}

          {optionsLoading && (
            <p className="text-sm text-muted-foreground">Ładowanie opcjonalnych zgód…</p>
          )}

          {optionalDocs.map((doc) => (
            <div key={doc.id} className="flex items-start gap-3">
              <input
                id={`wall-accept-${doc.id}`}
                type="checkbox"
                checked={Boolean(accepted[doc.id])}
                onChange={(e) =>
                  setAccepted((prev) => ({ ...prev, [doc.id]: e.target.checked }))
                }
                className="mt-1 h-4 w-4 rounded border-input text-primary focus:ring-ring"
              />
              <label htmlFor={`wall-accept-${doc.id}`} className="text-sm leading-relaxed">
                Akceptuję{' '}
                <Link
                  to={pathFor(doc.document_type)}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-primary underline"
                >
                  {labelFor(doc.document_type)}
                </Link>
                {' '}z dnia {formatPublishedLegal(doc.active_from)} (wersja {doc.version}) — opcjonalnie
              </label>
            </div>
          ))}

          {error && (
            <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading || optionsLoading || !allRequiredChecked}
            className="w-full inline-flex items-center justify-center rounded-md bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50"
          >
            {loading ? 'Zapisywanie…' : 'Akceptuję i kontynuuję'}
          </button>
        </form>

        <button
          type="button"
          onClick={() => void signOut()}
          className="w-full text-sm text-muted-foreground hover:text-foreground underline"
        >
          Wyloguj się
        </button>
      </div>
    </div>
  )
}
