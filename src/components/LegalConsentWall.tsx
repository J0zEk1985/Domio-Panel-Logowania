import { useState, type FormEvent } from 'react'
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

function labelFor(type: string): string {
  return DOC_LABELS[type as LegalDocType] ?? type
}

function pathFor(type: string): string {
  return DOC_PATHS[type as LegalDocType] ?? '/regulamin'
}

export default function LegalConsentWall({ documents, onAccepted }: Props) {
  const [accepted, setAccepted] = useState<Record<string, boolean>>({})
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const allChecked = documents.every((doc) => accepted[doc.id])

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)
    if (!allChecked) {
      setError('Musisz zaakceptować wszystkie wymagane dokumenty.')
      return
    }
    setLoading(true)
    try {
      const { data: existing } = await supabase
        .from('user_consents')
        .select('id')
        .limit(1)
      const { data: userData } = await supabase.auth.getUser()
      const provider = String(userData.user?.app_metadata?.provider ?? 'email')
      const source: LegalConsentSource = existing && existing.length > 0
        ? 'reacceptance'
        : provider === 'email'
          ? 'signup_email'
          : 'signup_oauth'

      const ipAddress = await fetchClientIp()
      const result = await recordPlatformLegalConsent({
        acceptedDocumentIds: documents.map((doc) => doc.id),
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

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4 py-10">
      <div className="bento-card w-full max-w-lg p-8 space-y-6 border border-border">
        <div className="space-y-2">
          <h1 className="font-display text-2xl font-semibold">Aktualizacja dokumentów prawnych</h1>
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

          {error && (
            <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading || !allChecked}
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
