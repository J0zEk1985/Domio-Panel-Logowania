import { useEffect, useRef, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import type { EmailOtpType } from '@supabase/supabase-js'
import { supabase } from '../lib/supabase'

type ConfirmStatus = 'loading' | 'success' | 'error' | 'idle'

const OTP_TYPES = new Set<EmailOtpType>(['email', 'signup'])

function isSignupOtpType(value: string | null): value is EmailOtpType {
  return value !== null && OTP_TYPES.has(value as EmailOtpType)
}

function confirmationErrorMessage(raw: string): string {
  const message = raw.toLowerCase()
  if (
    message.includes('expired') ||
    message.includes('invalid') ||
    message.includes('already') ||
    message.includes('otp')
  ) {
    return 'Link potwierdzający wygasł albo został już użyty. Jeśli konto jest już aktywne, zaloguj się. W przeciwnym razie zarejestruj się ponownie.'
  }
  return 'Nie udało się potwierdzić rejestracji. Otwórz link z wiadomości e-mail jeszcze raz.'
}

export default function SignupConfirmedPage() {
  const [searchParams] = useSearchParams()
  const [status, setStatus] = useState<ConfirmStatus>('loading')
  const [message, setMessage] = useState<string | null>(null)
  const confirmedRef = useRef(false)

  useEffect(() => {
    if (confirmedRef.current) return

    let cancelled = false

    const succeed = () => {
      if (cancelled || confirmedRef.current) return
      confirmedRef.current = true
      setStatus('success')
      setMessage(null)
      window.history.replaceState({}, '', '/rejestracja-potwierdzona')
    }

    const fail = (raw: string) => {
      if (cancelled || confirmedRef.current) return
      console.error('[SignupConfirmedPage]', raw)
      setStatus('error')
      setMessage(confirmationErrorMessage(raw))
    }

    const confirm = async () => {
      const authError = searchParams.get('error_description') || searchParams.get('error')
      if (authError) {
        fail(authError)
        return
      }

      const tokenHash = searchParams.get('token_hash')
      const otpType = searchParams.get('type')
      if (tokenHash && isSignupOtpType(otpType)) {
        const { error } = await supabase.auth.verifyOtp({
          token_hash: tokenHash,
          type: otpType,
        })
        if (error) {
          fail(error.message)
          return
        }
        succeed()
        return
      }

      const hasAuthCallback =
        Boolean(searchParams.get('code')) || window.location.hash.includes('access_token')
      if (hasAuthCallback) {
        const { data, error } = await supabase.auth.getSession()
        if (error) {
          fail(error.message)
          return
        }
        if (data.session) {
          succeed()
          return
        }
        fail('Brak sesji po potwierdzeniu rejestracji.')
        return
      }

      if (!cancelled) setStatus('idle')
    }

    void confirm().catch((error: unknown) => {
      fail(error instanceof Error ? error.message : 'Nieznany błąd potwierdzenia')
    })

    return () => {
      cancelled = true
    }
  }, [searchParams])

  const title =
    status === 'success'
      ? 'Rejestracja potwierdzona'
      : status === 'error'
        ? 'Nie udało się potwierdzić konta'
        : status === 'loading'
          ? 'Potwierdzanie rejestracji'
          : 'Potwierdzenie rejestracji'

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-900 px-4">
      <div className="w-full max-w-md">
        <div className="bg-gray-800 rounded-lg shadow-xl p-8">
          <h1 className="text-3xl font-bold text-white mb-2">{title}</h1>

          {status === 'loading' && (
            <p className="text-gray-400">Sprawdzamy link z wiadomości e-mail…</p>
          )}

          {status === 'success' && (
            <p className="text-gray-300 mb-8">
              Adres e-mail został potwierdzony. Konto jest aktywne. Przejdź do panelu logowania,
              aby się zalogować.
            </p>
          )}

          {status === 'error' && (
            <p className="text-red-300 mb-8">{message}</p>
          )}

          {status === 'idle' && (
            <p className="text-gray-300 mb-8">
              Ta strona potwierdza rejestrację po kliknięciu linku z wiadomości e-mail. Jeśli
              konto jest już aktywne, przejdź do panelu logowania.
            </p>
          )}

          {status !== 'loading' && (
            <div className="space-y-4">
              <Link
                to="/login"
                className="block w-full text-center bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-gray-800"
              >
                Przejdź do panelu logowania
              </Link>
              {status === 'error' && (
                <p className="text-center text-sm text-gray-400">
                  Nie masz jeszcze konta?{' '}
                  <Link to="/signup" className="text-blue-400 hover:text-blue-300 font-medium">
                    Zarejestruj się
                  </Link>
                </p>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
