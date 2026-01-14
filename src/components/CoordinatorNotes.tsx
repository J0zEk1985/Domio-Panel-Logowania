import { Languages } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { useTranslateText } from '../hooks/useTranslateText'

interface CoordinatorNotesProps {
  notes: string | null | undefined
  className?: string
}

/**
 * Component displaying coordinator notes with translation functionality
 * This component can be used in PropertyDetailSheet or TaskCard
 */
export function CoordinatorNotes({ notes, className = '' }: CoordinatorNotesProps) {
  const { t } = useTranslation()
  const { translate, loading, translatedText, error } = useTranslateText()

  const handleTranslate = async () => {
    if (!notes || notes.trim().length === 0) return
    await translate(notes, 'pl', 'uk')
  }

  if (!notes || notes.trim().length === 0) {
    return null
  }

  return (
    <div className={`space-y-2 ${className}`}>
      <div className="flex items-start justify-between gap-2">
        <p className="text-sm text-gray-700 dark:text-gray-300 flex-1">{notes}</p>
        <button
          onClick={handleTranslate}
          disabled={loading || !notes || notes.trim().length === 0}
          className="inline-flex items-center gap-1.5 px-2 py-1 text-xs text-blue-400 hover:text-blue-300 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex-shrink-0"
          title={t('translate')}
        >
          <Languages className="w-3.5 h-3.5" />
          <span>{loading ? t('translating') : t('translate')}</span>
        </button>
      </div>
      {translatedText && (
        <div className="pl-4 border-l-2 border-blue-300 dark:border-blue-600">
          <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">{t('autoTranslation')}</p>
          <p className="text-sm text-gray-600 dark:text-gray-400 italic">{translatedText}</p>
        </div>
      )}
      {error && (
        <p className="text-xs text-red-500 dark:text-red-400">{t('translationError')}</p>
      )}
    </div>
  )
}
