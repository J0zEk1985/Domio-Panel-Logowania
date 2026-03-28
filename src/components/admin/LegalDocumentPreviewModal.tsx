import { X } from 'lucide-react'
import { DOC_LABELS, formatPublishedLegal, type LegalDocumentRow } from './legalAdminTypes'

type Props = {
  row: LegalDocumentRow
  onClose: () => void
}

export default function LegalDocumentPreviewModal({ row, onClose }: Props) {
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
          <div>
            <h3 id="legal-preview-title" className="font-display font-semibold text-lg">
              Podgląd — wersja {row.version}
            </h3>
            <p className="text-xs text-muted-foreground mt-1">
              {DOC_LABELS[row.document_type]} · {formatPublishedLegal(row.published_at)} · tylko do odczytu
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-md p-2 text-muted-foreground hover:bg-muted hover:text-foreground"
            aria-label="Zamknij podgląd"
          >
            <X className="h-5 w-5" />
          </button>
        </div>
        <div className="overflow-y-auto p-4 flex-1">
          <pre className="whitespace-pre-wrap font-sans text-sm text-foreground leading-relaxed">{row.content}</pre>
        </div>
      </div>
    </div>
  )
}
