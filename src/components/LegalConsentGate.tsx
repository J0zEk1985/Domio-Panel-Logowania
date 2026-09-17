import { useEffect, useState, type ReactNode } from 'react'
import LegalConsentWall from './LegalConsentWall'
import { fetchPendingRequiredLegalDocuments } from '../lib/legalConsentApi'
import type { PendingRequiredLegalDocument } from '../types/database'

type Props = {
  children: ReactNode
}

export default function LegalConsentGate({ children }: Props) {
  const [pending, setPending] = useState<PendingRequiredLegalDocument[] | null>(null)
  const [error, setError] = useState<string | null>(null)

  const loadPending = async () => {
    setError(null)
    try {
      const rows = await fetchPendingRequiredLegalDocuments()
      setPending(rows)
    } catch (err) {
      console.error('[LegalConsentGate]', err)
      setError(err instanceof Error ? err.message : 'Nie udało się sprawdzić dokumentów prawnych.')
      setPending([])
    }
  }

  useEffect(() => {
    void loadPending()
  }, [])

  if (pending === null) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-lg">Ładowanie...</div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center px-4">
        <div className="bento-card max-w-md p-6 space-y-4 text-center">
          <p className="text-sm text-destructive">{error}</p>
          <button
            type="button"
            onClick={() => {
              setPending(null)
              void loadPending()
            }}
            className="inline-flex items-center justify-center rounded-md bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground"
          >
            Spróbuj ponownie
          </button>
        </div>
      </div>
    )
  }

  if (pending.length > 0) {
    return (
      <LegalConsentWall
        documents={pending}
        onAccepted={() => {
          setPending([])
        }}
      />
    )
  }

  return <>{children}</>
}
