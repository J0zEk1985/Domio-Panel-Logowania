import React from 'react'
import { Languages } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { useTranslateText } from '../hooks/useTranslateText'

interface TranslateButtonProps {
  text: string
  onTranslationComplete?: (translatedText: string) => void
  className?: string
}

/**
 * Button component that translates text from Polish to Ukrainian
 */
export function TranslateButton({ text, onTranslationComplete, className = '' }: TranslateButtonProps) {
  const { t } = useTranslation()
  const { translate, loading, translatedText, error } = useTranslateText()

  const handleClick = async () => {
    if (!text || text.trim().length === 0) return
    await translate(text, 'pl', 'uk')
  }

  // Notify parent when translation completes
  React.useEffect(() => {
    if (translatedText && onTranslationComplete) {
      onTranslationComplete(translatedText)
    }
  }, [translatedText, onTranslationComplete])

  return (
    <button
      onClick={handleClick}
      disabled={loading || !text || text.trim().length === 0}
      className={`inline-flex items-center gap-1.5 px-2 py-1 text-xs text-blue-400 hover:text-blue-300 disabled:opacity-50 disabled:cursor-not-allowed transition-colors ${className}`}
      title={t('translate')}
    >
      <Languages className="w-3.5 h-3.5" />
      <span>{loading ? t('translating') : t('translate')}</span>
    </button>
  )
}
