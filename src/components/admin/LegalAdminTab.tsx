import { useCallback, useEffect, useMemo, useState } from 'react'
import { Eye, FileText, Megaphone, Scale } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { inputClass } from './pricingAdminUtils'
import LegalDocumentPreviewModal from './LegalDocumentPreviewModal'
import { DOC_LABELS, formatPublishedLegal, type LegalDocType, type LegalDocumentRow } from './legalAdminTypes'

export type { LegalDocType } from './legalAdminTypes'

export default function LegalAdminTab() {
  const [activeDocType, setActiveDocType] = useState<LegalDocType>('terms')
  const [documentHistory, setDocumentHistory] = useState<LegalDocumentRow[]>([])
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [newVersion, setNewVersion] = useState('')
  const [newContent, setNewContent] = useState('')
  const [isRequired, setIsRequired] = useState(true)
  const [publishError, setPublishError] = useState<string | null>(null)
  const [publishing, setPublishing] = useState(false)

  const [previewRow, setPreviewRow] = useState<LegalDocumentRow | null>(null)

  useEffect(() => {
    setIsRequired(activeDocType !== 'marketing')
  }, [activeDocType])

  const loadHistory = useCallback(async () => {
    setLoadError(null)
    setLoading(true)
    setDocumentHistory([])
    try {
      const { data, error } = await supabase
        .from('legal_documents')
        .select('id, document_type, version, content, is_active, is_required, published_at, created_by')
        .eq('document_type', activeDocType)
        .order('published_at', { ascending: false })

      if (error) {
        console.error('[LegalAdminTab] loadHistory:', error)
        setLoadError('Nie udało się pobrać historii dokumentów (sprawdź migrację i RLS).')
        setDocumentHistory([])
        return
      }
      setDocumentHistory((data as LegalDocumentRow[]) ?? [])
    } catch (e) {
      console.error('[LegalAdminTab] loadHistory:', e)
      setLoadError('Wystąpił błąd podczas ładowania dokumentów.')
      setDocumentHistory([])
    } finally {
      setLoading(false)
    }
  }, [activeDocType])

  useEffect(() => {
    void loadHistory()
  }, [loadHistory])

  const latestVersionHint = useMemo(() => {
    const active = documentHistory.find((d) => d.is_active)
    if (active?.version) return active.version
    const newest = documentHistory[0]
    return newest?.version ?? null
  }, [documentHistory])

  const publishNewVersion = async () => {
    setPublishError(null)
    const version = newVersion.trim()
    const content = newContent.trim()
    if (!version || !content) {
      setPublishError('Podaj numer wersji i treść dokumentu.')
      return
    }

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser()
    if (userError || !user?.id) {
      console.error('[LegalAdminTab] getUser:', userError)
      setPublishError('Nie udało się ustalić zalogowanego użytkownika.')
      return
    }

    setPublishing(true)
    try {
      const deactivate = await supabase
        .from('legal_documents')
        .update({ is_active: false })
        .eq('document_type', activeDocType)

      if (deactivate.error) {
        console.error('[LegalAdminTab] deactivate:', deactivate.error)
        setPublishError(deactivate.error.message || 'Nie udało się zdezaktywować poprzednich wersji.')
        return
      }

      const insert = await supabase.from('legal_documents').insert({
        document_type: activeDocType,
        version,
        content,
        is_active: true,
        is_required: isRequired,
        created_by: user.id,
      })

      if (insert.error) {
        console.error('[LegalAdminTab] insert:', insert.error)
        setPublishError(insert.error.message || 'Nie udało się zapisać nowej wersji.')
        return
      }

      setNewVersion('')
      setNewContent('')
      await loadHistory()
    } catch (e) {
      console.error('[LegalAdminTab] publish:', e)
      setPublishError('Wystąpił nieoczekiwany błąd podczas publikacji.')
    } finally {
      setPublishing(false)
    }
  }

  return (
    <div className="space-y-10">
      {loadError && (
        <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
          {loadError}
        </div>
      )}

      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          onClick={() => setActiveDocType('terms')}
          className={`inline-flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-colors ${
            activeDocType === 'terms'
              ? 'bg-primary/10 text-primary'
              : 'text-muted-foreground hover:bg-muted hover:text-foreground'
          }`}
        >
          <Scale className="h-4 w-4 shrink-0" />
          Regulamin
        </button>
        <button
          type="button"
          onClick={() => setActiveDocType('privacy')}
          className={`inline-flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-colors ${
            activeDocType === 'privacy'
              ? 'bg-primary/10 text-primary'
              : 'text-muted-foreground hover:bg-muted hover:text-foreground'
          }`}
        >
          <FileText className="h-4 w-4 shrink-0" />
          Polityka prywatności
        </button>
        <button
          type="button"
          onClick={() => setActiveDocType('marketing')}
          className={`inline-flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-colors ${
            activeDocType === 'marketing'
              ? 'bg-primary/10 text-primary'
              : 'text-muted-foreground hover:bg-muted hover:text-foreground'
          }`}
        >
          <Megaphone className="h-4 w-4 shrink-0" />
          Zgody marketingowe
        </button>
      </div>

      <section aria-labelledby="legal-publish-heading" className="bento-card p-6 space-y-4">
        <h2 id="legal-publish-heading" className="font-display text-lg font-semibold">
          Nowa wersja: {DOC_LABELS[activeDocType]}
        </h2>

        {publishError && (
          <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
            {publishError}
          </div>
        )}

        <div className="space-y-1.5">
          <label className="block text-sm text-muted-foreground" htmlFor="legal-version">
            Numer wersji
          </label>
          <input
            id="legal-version"
            className={inputClass}
            value={newVersion}
            onChange={(e) => setNewVersion(e.target.value)}
            placeholder={latestVersionHint ? `np. wyższa niż „${latestVersionHint}” (np. 1.1)` : 'np. 1.0'}
          />
          <p className="text-xs text-muted-foreground">
            {latestVersionHint
              ? `Ostatnia znana wersja dla tego typu: ${latestVersionHint}. Użyj wyższego numeru wersji.`
              : 'Brak opublikowanych wersji — możesz ustawić np. 1.0.'}
          </p>
        </div>

        <div className="space-y-1.5">
          <label className="block text-sm text-muted-foreground" htmlFor="legal-content">
            Pełna treść dokumentu
          </label>
          <textarea
            id="legal-content"
            className={`${inputClass} min-h-[22rem] font-mono text-sm leading-relaxed`}
            rows={15}
            value={newContent}
            onChange={(e) => setNewContent(e.target.value)}
            placeholder="Wklej tutaj pełną treść dokumentu…"
          />
        </div>

        <label className="flex items-start gap-3 cursor-pointer select-none">
          <input
            type="checkbox"
            checked={isRequired}
            onChange={(e) => setIsRequired(e.target.checked)}
            className="mt-1 h-4 w-4 rounded border-input text-primary focus:ring-ring"
          />
          <span className="text-sm text-foreground">
            Wymagane do założenia konta
            <span className="block text-xs text-muted-foreground mt-1">
              Jeśli zaznaczone, użytkownik musi zaakceptować ten dokument przy rejestracji (dotyczy dokumentów obowiązkowych).
            </span>
          </span>
        </label>

        <button
          type="button"
          disabled={publishing}
          onClick={() => void publishNewVersion()}
          className="inline-flex items-center justify-center rounded-md bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50"
        >
          {publishing ? 'Publikowanie…' : 'Opublikuj nową wersję'}
        </button>
      </section>

      <section aria-labelledby="legal-history-heading">
        <h2 id="legal-history-heading" className="font-display text-lg font-semibold mb-4">
          Historia wersji
        </h2>
        <div className="bento-card overflow-x-auto p-0">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border/60 text-left text-muted-foreground">
                <th className="p-4 font-medium">Wersja</th>
                <th className="p-4 font-medium">Data publikacji</th>
                <th className="p-4 font-medium">Wymagany</th>
                <th className="p-4 font-medium">Status</th>
                <th className="p-4 font-medium text-right">Akcje</th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={5} className="p-8 text-center text-muted-foreground">
                    Ładowanie historii…
                  </td>
                </tr>
              )}
              {!loading &&
                documentHistory.map((row) => (
                <tr key={row.id} className="border-b border-border/40 last:border-0">
                  <td className="p-4 font-medium">{row.version}</td>
                  <td className="p-4 text-muted-foreground">{formatPublishedLegal(row.published_at)}</td>
                  <td className="p-4 text-muted-foreground">
                    {row.is_required ? 'Tak' : 'Nie'}
                  </td>
                  <td className="p-4">
                    {row.is_active ? (
                      <span className="inline-flex rounded-full bg-emerald-500/15 text-emerald-700 dark:text-emerald-400 px-2.5 py-0.5 text-xs font-medium">
                        Aktywny
                      </span>
                    ) : (
                      <span className="inline-flex rounded-full bg-muted text-muted-foreground px-2.5 py-0.5 text-xs font-medium">
                        Archiwum
                      </span>
                    )}
                  </td>
                  <td className="p-4 text-right">
                    {!row.is_active && (
                      <button
                        type="button"
                        onClick={() => setPreviewRow(row)}
                        className="inline-flex items-center gap-1.5 text-primary hover:underline text-sm font-medium"
                      >
                        <Eye className="h-4 w-4" />
                        Podgląd
                      </button>
                    )}
                  </td>
                </tr>
                ))}
            </tbody>
          </table>
          {documentHistory.length === 0 && !loading && (
            <div className="p-8 text-center text-muted-foreground">Brak zapisanych wersji dla tego typu dokumentu.</div>
          )}
        </div>
      </section>

      {previewRow && (
        <LegalDocumentPreviewModal row={previewRow} onClose={() => setPreviewRow(null)} />
      )}
    </div>
  )
}
