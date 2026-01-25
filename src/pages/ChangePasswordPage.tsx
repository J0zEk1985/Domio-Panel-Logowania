import { useState, FormEvent, useEffect } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import { validatePassword } from '../lib/validation'
import ValidationChecklist from '../components/ValidationChecklist'

export default function ChangePasswordPage() {
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [repeatPassword, setRepeatPassword] = useState('')
  const [passwordType, setPasswordType] = useState<'password' | 'pin'>('password')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()

  useEffect(() => {
    const checkUser = async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser()
      if (!user) {
        navigate('/login')
      }
    }
    checkUser()
  }, [navigate])

  const handleChangePassword = async (e: FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    try {
      // Get current user email
      const {
        data: { user },
        error: userError,
      } = await supabase.auth.getUser()

      if (userError || !user || !user.email) {
        throw new Error('Nie można pobrać danych użytkownika')
      }

      // Validate new password/PIN
      let validation
      if (passwordType === 'password') {
        validation = validatePassword(newPassword)
        if (!validation.isValid) {
          throw new Error('Nowe hasło nie spełnia wymagań')
        }
      } else {
        validation = validatePIN(newPassword)
        if (!validation.isValid) {
          throw new Error('Nowy PIN nie spełnia wymagań')
        }
      }

      // Check if passwords match
      if (newPassword !== repeatPassword) {
        throw new Error('Nowe hasła nie są identyczne')
      }

      // SECURITY: Silent login to verify current password
      // This confirms user identity before allowing password change
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email: user.email,
        password: currentPassword,
      })

      if (signInError) {
        throw new Error('Obecne hasło jest nieprawidłowe')
      }

      // Check password history (prevent reusing same password)
      // Note: We can't easily get old password from Supabase, so we'll skip this check
      // In a production system, you'd store password hashes in a separate table

      // Update password
      const { error: updateError } = await supabase.auth.updateUser({
        password: newPassword,
      })

      if (updateError) throw updateError

      setSuccess(true)

      // Redirect after 2 seconds
      setTimeout(() => {
        const returnTo = searchParams.get('returnTo')
        if (returnTo) {
          window.location.href = returnTo
        } else {
          navigate('/dashboard')
        }
      }, 2000)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas zmiany hasła')
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-900 px-4">
        <div className="w-full max-w-md">
          <div className="bg-gray-800 rounded-lg shadow-xl p-8 text-center">
            <div className="mb-4">
              <svg
                className="w-16 h-16 text-green-500 mx-auto"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M5 13l4 4L19 7"
                />
              </svg>
            </div>
            <h1 className="text-2xl font-bold text-white mb-2">Hasło zostało zmienione</h1>
            <p className="text-gray-400">Przekierowywanie...</p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-900 px-4">
      <div className="w-full max-w-md">
        <div className="bg-gray-800 rounded-lg shadow-xl p-8">
          <h1 className="text-3xl font-bold text-white mb-2">Zmień hasło</h1>
          <p className="text-gray-400 mb-8">Wprowadź obecne hasło i nowe hasło</p>

          <form onSubmit={handleChangePassword} className="space-y-6">
            <div>
              <label htmlFor="password-type" className="block text-sm font-medium text-gray-300 mb-2">
                Typ hasła
              </label>
              <select
                id="password-type"
                value={passwordType}
                onChange={(e) => setPasswordType(e.target.value as 'password' | 'pin')}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-md text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="password">Hasło (Właściciel)</option>
                <option value="pin">PIN (Pracownik)</option>
              </select>
            </div>

            <div>
              <label htmlFor="current-password" className="block text-sm font-medium text-gray-300 mb-2">
                Obecne hasło
              </label>
              <input
                id="current-password"
                type="password"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                placeholder="********"
                required
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-md text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div>
              <label htmlFor="new-password" className="block text-sm font-medium text-gray-300 mb-2">
                Nowe {passwordType === 'password' ? 'hasło' : 'PIN'}
              </label>
              <input
                id="new-password"
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder={passwordType === 'password' ? '********' : '123456'}
                required
                maxLength={passwordType === 'pin' ? 6 : undefined}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-md text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <ValidationChecklist value={newPassword} type={passwordType} />
            </div>

            <div>
              <label htmlFor="repeat-password" className="block text-sm font-medium text-gray-300 mb-2">
                Powtórz nowe {passwordType === 'password' ? 'hasło' : 'PIN'}
              </label>
              <input
                id="repeat-password"
                type="password"
                value={repeatPassword}
                onChange={(e) => setRepeatPassword(e.target.value)}
                placeholder={passwordType === 'password' ? '********' : '123456'}
                required
                maxLength={passwordType === 'pin' ? 6 : undefined}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-md text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            {error && (
              <div className="bg-red-900/50 border border-red-700 text-red-200 px-4 py-3 rounded">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={
                loading ||
                !currentPassword ||
                !newPassword ||
                !repeatPassword ||
                (passwordType === 'password' ? !validatePassword(newPassword).isValid : !validatePIN(newPassword).isValid)
              }
              className="w-full bg-gray-700 text-white py-2 px-4 rounded-md hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:ring-offset-gray-800 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Zmienianie hasła...' : 'Zmień hasło'}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}
