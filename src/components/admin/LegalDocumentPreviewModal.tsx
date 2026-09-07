import { X, Copy } from 'lucide-react'
import { DOC_LABELS, formatPublishedLegal, type LegalDocumentRow } from './legalAdminTypes'

type Props = {
  row: LegalDocumentRow
  onClose: () => void
  onUseAsBase?: (row: LegalDocumentRow) => void
}

export default function LegalDocumentPreviewModal({ row, onClose, onUseAsBase }: Props) {
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
      role="dialog"
      aria-modal="true"
      aria-labelledby="legal-preview-title"
      onClick={onClose}
    >
      <div
        className="bento-card max-w-3xl w-full max-h-[85vh] flex flex-col shadow-lg border border-border"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between gap-4 p-4 border-b border-border/60">
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-1">
              <h3 id="legal-preview-title" className="font-display font-semibold text-lg">
                Podgląd — wersja {row.version}
              </h3>
              {row.is_active ? (
                <span className="inline-flex rounded-full bg-emerald-500/15 text-emerald-700 dark:text-emerald-400 px-2.5 py-0.5 text-xs font-medium">
                  Aktywny
                </span>
              ) : (
                <span className="inline-flex rounded-full bg-muted text-muted-foreground px-2.5 py-0.5 text-xs font-medium">
                  Archiwum
                </span>
              )}
            </div>
            <p className="text-xs text-muted-foreground">
              {DOC_LABELS[row.document_type]} · {formatPublishedLegal(row.published_at)} · tylko do odczytu
            </p>
          </div>
          <div className="flex items-center gap-2">
            {onUseAsBase && (
              <button
                type="button"
                onClick={() => {
                  onUseAsBase(row)
                  onClose()
                }}
                className="rounded-md px-3 py-2 text-sm font-medium text-primary hover:bg-primary/10 inline-flex items-center gap-1.5"
                title="Skopiuj do formularza nowej wersji"
              >
                <Copy className="h-4 w-4" />
                Użyj jako bazę
              </button>
            )}
            <button
              type="button"
              onClick={onClose}
              className="rounded-md p-2 text-muted-foreground hover:bg-muted hover:text-foreground"
              aria-label="Zamknij podgląd"
            >
              <X className="h-5 w-5" />
            </button>
          </div>
        </div>
        <div className="overflow-y-auto p-4 flex-1">
          <pre className="whitespace-pre-wrap font-sans text-sm text-foreground leading-relaxed">{row.content}</pre>
        </div>
      </div>
    </div>
  )
}
