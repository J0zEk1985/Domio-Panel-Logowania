import { useState, FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '../lib/supabase'

export default function StaffLoginPage() {
  const [internalId, setInternalId] = useState('')
  const [pin, setPin] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const navigate = useNavigate()

  const handleStaffLogin = async (e: FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    try {
      // Find staff member by internal_id and pin
      const { data: staffData, error: staffError } = await supabase
        .from('cleaning_staff')
        .select('*')
        .eq('internal_id', internalId)
        .eq('pin', pin)
        .eq('is_active', true)
        .single()

      if (staffError || !staffData) {
        throw new Error('Nieprawidłowy identyfikator lub PIN')
      }

      // Note: This is a simplified staff login flow
      // In a production system, you might want to create a separate auth flow
      // or link cleaning_staff to auth.users table
      // For now, we'll just navigate to dashboard with a flag
      // You may need to implement a custom auth solution for staff login

      // Store staff info in session storage (temporary solution)
      sessionStorage.setItem('staff_user', JSON.stringify(staffData))
      
      navigate('/dashboard')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas logowania')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="w-full max-w-md">
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Logowanie personelu</h1>
          <p className="text-gray-600 mb-8">Zaloguj się używając identyfikatora i PIN</p>

          <form onSubmit={handleStaffLogin} className="space-y-6">
            <div>
              <label htmlFor="internal-id" className="block text-sm font-medium text-gray-700 mb-2">
                Identyfikator
              </label>
              <input
                id="internal-id"
                type="text"
                value={internalId}
                onChange={(e) => setInternalId(e.target.value)}
                placeholder="Wprowadź identyfikator"
                required
                className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div>
              <label htmlFor="staff-pin" className="block text-sm font-medium text-gray-700 mb-2">
                PIN
              </label>
              <input
                id="staff-pin"
                type="password"
                value={pin}
                onChange={(e) => setPin(e.target.value)}
                placeholder="••••"
                required
                maxLength={10}
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
              className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Logowanie...' : 'Zaloguj się'}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}
