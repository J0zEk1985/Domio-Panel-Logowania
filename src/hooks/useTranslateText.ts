import { useState } from 'react'

interface TranslateResult {
  translatedText: string | null
  loading: boolean
  error: string | null
}

/**
 * Hook to translate text from Polish to Ukrainian using MyMemory API (free, no API key required)
 */
export function useTranslateText() {
  const [state, setState] = useState<TranslateResult>({
    translatedText: null,
    loading: false,
    error: null,
  })

  const translate = async (text: string, from: string = 'pl', to: string = 'uk'): Promise<void> => {
    if (!text || text.trim().length === 0) {
      setState({ translatedText: null, loading: false, error: null })
      return
    }

    setState({ translatedText: null, loading: true, error: null })

    try {
      // Using MyMemory Translation API (free, no API key required, has rate limits)
      const encodedText = encodeURIComponent(text)
      const response = await fetch(
        `https://api.mymemory.translated.net/get?q=${encodedText}&langpair=${from}|${to}`
      )

      if (!response.ok) {
        throw new Error('Translation service unavailable')
      }

      const data = await response.json()

      if (data.responseStatus === 200 && data.responseData?.translatedText) {
        setState({
          translatedText: data.responseData.translatedText,
          loading: false,
          error: null,
        })
      } else {
        throw new Error('Translation failed')
      }
    } catch (err) {
      console.error('Translation error:', err)
      setState({
        translatedText: null,
        loading: false,
        error: err instanceof Error ? err.message : 'Translation failed',
      })
    }
  }

  const reset = () => {
    setState({ translatedText: null, loading: false, error: null })
  }

  return {
    ...state,
    translate,
    reset,
  }
}
