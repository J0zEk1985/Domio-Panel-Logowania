import { useEffect, useState, FormEvent } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import { validatePassword } from '../lib/validation'
import ValidationChecklist from '../components/ValidationChecklist'
import { DOC_LABELS, type LegalDocType } from '../components/admin/legalAdminTypes'

type ActiveLegalDoc = {
  id: string
  document_type: LegalDocType
  version: string
  content: string
  is_required: boolean
}

const DOC_ORDER: LegalDocType[] = ['terms', 'privacy', 'marketing']

function emptyAcceptedDocs(): Record<LegalDocType, boolean> {
  return { terms: false, privacy: false, marketing: false }
}

function sortLegalDocs(docs: ActiveLegalDoc[]): ActiveLegalDoc[] {
  return [...docs].sort(
    (a, b) => DOC_ORDER.indexOf(a.document_type) - DOC_ORDER.indexOf(b.document_type),
  )
}

export default function SignupPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [repeatPassword, setRepeatPassword] = useState('')
  const [activeLegalDocs, setActiveLegalDocs] = useState<ActiveLegalDoc[]>([])
  const [acceptedDocs, setAcceptedDocs] = useState<Record<LegalDocType, boolean>>(emptyAcceptedDocs)
  const [legalDocsLoading, setLegalDocsLoading] = useState(true)
  const [legalDocsError, setLegalDocsError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const navigate = useNavigate()

  useEffect(() => {
    let cancelled = false

    const loadLegalDocs = async () => {
      setLegalDocsLoading(true)
      setLegalDocsError(null)
      try {
        const { data, error: fetchError } = await supabase
          .from('legal_documents')
          .select('id, document_type, version, content, is_required')
          .eq('is_active', true)

        if (cancelled) return

        if (fetchError) {
          console.error('[SignupPage] legal_documents:', fetchError)
          setLegalDocsError('Nie udało się pobrać dokumentów prawnych. Odśwież stronę lub spróbuj później.')
          setActiveLegalDocs([])
          return
        }

        setActiveLegalDocs(sortLegalDocs((data as ActiveLegalDoc[]) ?? []))
        setAcceptedDocs(emptyAcceptedDocs())
      } catch (e) {
        console.error('[SignupPage] loadLegalDocs:', e)
        if (!cancelled) {
          setLegalDocsError('Wystąpił błąd podczas ładowania dokumentów prawnych.')
          setActiveLegalDocs([])
        }
      } finally {
        if (!cancelled) setLegalDocsLoading(false)
      }
    }

    void loadLegalDocs()
    return () => {
      cancelled = true
    }
  }, [])

  const fetchIPAddress = async (): Promise<string | null> => {
    try {
      const response = await fetch('https://api.ipify.org?format=json')
      const data = await response.json()
      return data.ip || null
    } catch (err) {
      console.error('Failed to fetch IP address:', err)
      return null
    }
  }

  const handleSignup = async (e: FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    try {
      const passwordValidation = validatePassword(password)
      if (!passwordValidation.allValid) {
        throw new Error('Hasło nie spełnia wymagań')
      }

      if (password !== repeatPassword) {
        throw new Error('Hasła nie są identyczne')
      }

      if (legalDocsLoading) {
        throw new Error('Poczekaj na załadowanie dokumentów prawnych.')
      }

      if (activeLegalDocs.length === 0) {
        throw new Error(
          legalDocsError
            ? 'Nie udało się załadować dokumentów prawnych. Spróbuj ponownie później.'
            : 'Brak opublikowanych dokumentów prawnych. Rejestracja jest chwilowo niedostępna.',
        )
      }

      for (const doc of activeLegalDocs) {
        if (doc.is_required && !acceptedDocs[doc.document_type]) {
          throw new Error(
            `Musisz zaakceptować: ${DOC_LABELS[doc.document_type]} (wersja ${doc.version}).`,
          )
        }
      }

      const ipAddress = await fetchIPAddress()

      const { data: authData, error: authError } = await supabase.auth.signUp({
        email,
        password,
      })

      if (authError) throw authError

      if (!authData.user) {
        throw new Error('Nie udało się utworzyć konta')
      }

      const termsDoc = activeLegalDocs.find((d) => d.document_type === 'terms')
      const privacyDoc = activeLegalDocs.find((d) => d.document_type === 'privacy')
      const marketingDoc = activeLegalDocs.find((d) => d.document_type === 'marketing')

      const { error: profileError } = await supabase.from('profiles').insert({
        id: authData.user.id,
        ip_address: ipAddress,
        accepted_terms_at: new Date().toISOString(),
        terms_version: termsDoc && acceptedDocs.terms ? termsDoc.version : '1.0',
        privacy_version: privacyDoc && acceptedDocs.privacy ? privacyDoc.version : null,
        marketing_consent: marketingDoc ? acceptedDocs.marketing : false,
        marketing_version: marketingDoc && acceptedDocs.marketing ? marketingDoc.version : null,
      })

      if (profileError) {
        console.error('Profile creation error:', profileError)
      }

      navigate('/dashboard')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas rejestracji')
    } finally {
      setLoading(false)
    }
  }

  const handleGoogleSignup = async () => {
    setLoading(true)
    setError(null)

    try {
      const { error: oauthError } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${window.location.origin}/dashboard`,
        },
      })

      if (oauthError) throw oauthError
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas rejestracji przez Google')
      setLoading(false)
    }
  }

  const handleFacebookSignup = async () => {
    setLoading(true)
    setError(null)

    try {
      const { error: oauthError } = await supabase.auth.signInWithOAuth({
        provider: 'facebook',
        options: {
          redirectTo: `${window.location.origin}/dashboard`,
        },
      })

      if (oauthError) throw oauthError
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas rejestracji przez Facebook')
      setLoading(false)
    }
  }

  const renderDocCheckboxLabel = (doc: ActiveLegalDoc) => {
    const label = DOC_LABELS[doc.document_type]
    const href =
      doc.document_type === 'terms'
        ? '/regulamin'
        : doc.document_type === 'privacy'
          ? '/polityka-prywatnosci'
          : null

    if (href) {
      return (
        <>
          Akceptuję{' '}
          <Link to={href} target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:text-blue-300 underline">
            {label}
          </Link>{' '}
          w wersji {doc.version}
          {doc.is_required ? ' *' : ''}
        </>
      )
    }

    return (
      <>
        Akceptuję {label} w wersji {doc.version}
        {doc.is_required ? ' *' : ''}
      </>
    )
  }

  const canSubmitEmail =
    !legalDocsLoading &&
    !legalDocsError &&
    activeLegalDocs.length > 0 &&
    validatePassword(password).allValid

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-900 px-4">
      <div className="w-full max-w-md">
        <div className="bg-gray-800 rounded-lg shadow-xl p-8">
          <h1 className="text-3xl font-bold text-white mb-2">Utwórz konto</h1>
          <p className="text-gray-400 mb-8">Podaj swój email, aby utworzyć konto</p>

          <form onSubmit={handleSignup} className="space-y-6">
            <div>
              <label htmlFor="signup-email" className="block text-sm font-medium text-gray-300 mb-2">
                Email
              </label>
              <input
                id="signup-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="nazwa@przykład.pl"
                required
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-md text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div>
              <label htmlFor="signup-password" className="block text-sm font-medium text-gray-300 mb-2">
                Hasło
              </label>
              <input
                id="signup-password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="********"
                required
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-md text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <ValidationChecklist value={password} type="password" />
            </div>

            <div>
              <label htmlFor="repeat-password" className="block text-sm font-medium text-gray-300 mb-2">
                Powtórz hasło
              </label>
              <input
                id="repeat-password"
                type="password"
                value={repeatPassword}
                onChange={(e) => setRepeatPassword(e.target.value)}
                placeholder="********"
                required
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-md text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div className="space-y-4">
              {legalDocsLoading && (
                <p className="text-sm text-gray-400">Ładowanie dokumentów prawnych…</p>
              )}
              {legalDocsError && (
                <div className="bg-red-900/50 border border-red-700 text-red-200 px-4 py-3 rounded text-sm">{legalDocsError}</div>
              )}
              {!legalDocsLoading && !legalDocsError && activeLegalDocs.length === 0 && (
                <div className="bg-amber-900/40 border border-amber-700 text-amber-100 px-4 py-3 rounded text-sm">
                  Brak opublikowanych dokumentów prawnych. Rejestracja e-mail jest niedostępna — skontaktuj się z administratorem.
                </div>
              )}
              {!legalDocsLoading &&
                activeLegalDocs.map((doc) => (
                  <div key={doc.id} className="flex items-start">
                    <input
                      id={`legal-accept-${doc.id}`}
                      type="checkbox"
                      checked={acceptedDocs[doc.document_type]}
                      onChange={(e) =>
                        setAcceptedDocs((prev) => ({
                          ...prev,
                          [doc.document_type]: e.target.checked,
                        }))
                      }
                      className="mt-1 h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-600 rounded bg-gray-700"
                    />
                    <label htmlFor={`legal-accept-${doc.id}`} className="ml-3 text-sm text-gray-300">
                      {renderDocCheckboxLabel(doc)}
                    </label>
                  </div>
                ))}
            </div>

            {error && (
              <div className="bg-red-900/50 border border-red-700 text-red-200 px-4 py-3 rounded">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading || !canSubmitEmail}
              className="w-full bg-gray-700 text-white py-2 px-4 rounded-md hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:ring-offset-gray-800 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Tworzenie konta...' : 'Utwórz konto'}
            </button>
          </form>

          <div className="my-6 flex items-center">
            <div className="flex-1 border-t border-gray-600"></div>
            <span className="px-4 text-sm text-gray-400">LUB</span>
            <div className="flex-1 border-t border-gray-600"></div>
          </div>

          <div className="space-y-3">
            <button
              onClick={handleGoogleSignup}
              disabled={loading}
              className="w-full flex items-center justify-center gap-3 bg-gray-700 border border-gray-600 text-gray-300 py-2 px-4 rounded-md hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:ring-offset-gray-800 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <svg className="w-5 h-5" viewBox="0 0 24 24">
                <path
                  fill="#4285F4"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                />
                <path
                  fill="#34A853"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                />
                <path
                  fill="#EA4335"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                />
              </svg>
              Zaloguj przez Google
            </button>

            <button
              onClick={handleFacebookSignup}
              disabled={loading}
              className="w-full flex items-center justify-center gap-3 bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-gray-800 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24">
                <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
              </svg>
              Zaloguj przez Facebook
            </button>
          </div>

          <p className="mt-6 text-center text-sm text-gray-400">
            Masz już konto?{' '}
            <Link to="/login" className="text-blue-400 hover:text-blue-300 font-medium">
              Zaloguj się
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}
