import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { supabase } from '../lib/supabase'

const CookiesPage = () => {
  const [content, setContent] = useState<string | null>(null)
  const [version, setVersion] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const loadCookies = async () => {
      try {
        const { data, error: fetchError } = await supabase
          .from('legal_documents')
          .select('version, content, published_at')
          .eq('document_type', 'cookies')
          .eq('is_active', true)
          .single()

        if (fetchError) {
          console.error('[CookiesPage] fetch error:', fetchError)
          setError('Nie udało się załadować polityki cookies.')
          return
        }

        if (data) {
          setVersion(data.version)
          setContent(data.content)
        } else {
          setError('Brak opublikowanej polityki cookies.')
        }
      } catch (e) {
        console.error('[CookiesPage] error:', e)
        setError('Wystąpił błąd podczas ładowania polityki cookies.')
      } finally {
        setLoading(false)
      }
    }

    void loadCookies()
  }, [])

  return (
    <div className="min-h-screen bg-[#1a1f2c] text-white p-8">
      <div className="max-w-3xl mx-auto">
        <Link to="/" className="flex items-center text-gray-400 hover:text-white mb-8 transition-colors">
          <ArrowLeft className="w-4 h-4 mr-2" /> Powrót
        </Link>

        {loading && (
          <div className="text-center py-12">
            <p className="text-gray-400">Ładowanie polityki cookies…</p>
          </div>
        )}

        {error && (
          <div className="bg-red-900/50 border border-red-700 text-red-200 px-6 py-4 rounded-lg">
            {error}
          </div>
        )}

        {!loading && !error && content && (
          <>
            <h1 className="text-3xl font-bold mb-6">Polityka cookies</h1>
            {version && <p className="text-gray-400 mb-8">Wersja {version}</p>}
            <section className="space-y-6 text-gray-300 whitespace-pre-wrap">{content}</section>
          </>
        )}
      </div>
    </div>
  )
}

export default CookiesPage
