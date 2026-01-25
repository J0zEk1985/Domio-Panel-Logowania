import { useState, FormEvent } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { supabase } from '../lib/supabase'

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)
  const [searchParams] = useSearchParams()

  const handleResetPassword = async (e: FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)
    setSuccess(false)

    try {
      const emailInput = email.trim()

      // Sprawdzenie czy input zawiera @ (czy jest mailem)
      if (!emailInput.includes('@')) {
        setError('Personel nie może resetować hasła samodzielnie. Skontaktuj się z przełożonym')
        setLoading(false)
        return
      }

      // Jeśli to email, wyślij link do resetowania
      const { error: resetError } = await supabase.auth.resetPasswordForEmail(emailInput, {
        redirectTo: `${window.location.origin}/reset-password`,
      })

      if (resetError) throw resetError

      setSuccess(true)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas resetowania hasła')
    } finally {
      setLoading(false)
    }
  }

  const returnTo = searchParams.get('returnTo')

  return (
    <div className="min-h-screen flex items-center justify-center bg-white px-4">
      <div className="w-full max-w-md">
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Resetowanie hasła</h1>
          <p className="text-gray-600 mb-8">Podaj swój adres e-mail, aby otrzymać link do resetowania hasła</p>

          {success ? (
            <div className="space-y-4">
              <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded">
                Link do resetowania hasła został wysłany na podany adres e-mail. Sprawdź swoją skrzynkę pocztową.
              </div>
              <Link
                to={returnTo ? `/login?returnTo=${encodeURIComponent(returnTo)}` : '/login'}
                className="block text-center text-blue-600 hover:text-blue-800 font-medium"
              >
                Powrót do logowania
              </Link>
            </div>
          ) : (
            <form onSubmit={handleResetPassword} className="space-y-6">
              <div>
                <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                  Email / Login
                </label>
                <input
                  id="email"
                  type="text"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="nazwa@przykład.pl lub Twój ID"
                  required
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              {error && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
                  {error}
                </div>
              )}

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-gray-800 text-white py-2 px-4 rounded-md hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? 'Wysyłanie...' : 'Wyślij link resetujący'}
              </button>
            </form>
          )}

          <p className="mt-6 text-center text-sm text-gray-600">
            Pamiętasz hasło?{' '}
            <Link
              to={returnTo ? `/login?returnTo=${encodeURIComponent(returnTo)}` : '/login'}
              className="text-blue-600 hover:text-blue-800 font-medium"
            >
              Zaloguj się
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}