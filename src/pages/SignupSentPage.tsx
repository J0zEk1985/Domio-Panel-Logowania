import { Link, useSearchParams } from 'react-router-dom'

export default function SignupSentPage() {
  const [searchParams] = useSearchParams()
  const email = searchParams.get('email') || 'swoją skrzynkę e-mail'

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-900 px-4">
      <div className="w-full max-w-md">
        <div className="bg-gray-800 rounded-lg shadow-xl p-8">
          <div className="flex items-center justify-center w-16 h-16 mx-auto mb-4 bg-green-900/50 rounded-full">
            <svg
              className="w-8 h-8 text-green-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
              />
            </svg>
          </div>

          <h1 className="text-3xl font-bold text-white mb-2 text-center">Sprawdź swoją pocztę</h1>
          
          <div className="space-y-4 mb-8">
            <p className="text-gray-300 text-center">
              Konto zostało utworzone! Wysłaliśmy wiadomość e-mail na adres:
            </p>
            
            <p className="text-white font-semibold text-center text-lg break-all">
              {email}
            </p>

            <div className="bg-blue-900/30 border border-blue-700/50 rounded-lg p-4 space-y-2">
              <p className="text-blue-200 text-sm">
                📧 <strong>Kliknij w link aktywacyjny</strong> w wiadomości e-mail, aby dokończyć rejestrację i aktywować konto.
              </p>
              <p className="text-blue-200 text-sm">
                ⏰ Link jest ważny przez <strong>1 godzinę</strong>.
              </p>
            </div>

            <div className="bg-gray-700/50 border border-gray-600 rounded-lg p-4 space-y-2">
              <p className="text-gray-300 text-sm font-medium">
                Nie widzisz wiadomości?
              </p>
              <ul className="text-gray-400 text-sm space-y-1 list-disc list-inside">
                <li>Sprawdź folder SPAM lub Wiadomości-śmieci</li>
                <li>Upewnij się, że podałeś poprawny adres e-mail</li>
                <li>Poczekaj kilka minut - czasem dostarczenie emaila może potrwać</li>
              </ul>
            </div>
          </div>

          <div className="space-y-3">
            <Link
              to="/login"
              className="block w-full text-center bg-gray-700 text-white py-2 px-4 rounded-md hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:ring-offset-gray-800 transition-colors"
            >
              Przejdź do logowania
            </Link>
            
            <p className="text-center text-sm text-gray-400">
              Nie otrzymałeś emaila?{' '}
              <Link to="/signup" className="text-blue-400 hover:text-blue-300 font-medium">
                Zarejestruj się ponownie
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
