import { validatePassword, validatePIN } from '../lib/validation'

interface ValidationChecklistProps {
  value: string
  type: 'password' | 'pin'
}

export default function ValidationChecklist({ value, type }: ValidationChecklistProps) {
  if (type === 'password') {
    const validation = validatePassword(value)
    const checks = validation.checks

    return (
      <ul className="mt-2 space-y-1 text-sm">
        <li className={checks.minLength ? 'text-green-500 font-bold' : 'text-gray-400 font-light'}>
          Minimum 8 znaków
        </li>
        <li className={checks.hasUpperCase ? 'text-green-500 font-bold' : 'text-gray-400 font-light'}>
          Przynajmniej jedna wielka litera
        </li>
        <li className={checks.hasNumberOrSpecial ? 'text-green-500 font-bold' : 'text-gray-400 font-light'}>
          Przynajmniej jedna cyfra lub znak specjalny
        </li>
      </ul>
    )
  }

  if (type === 'pin') {
    const validation = validatePIN(value)
    const checks = validation.checks

    return (
      <ul className="mt-2 space-y-1 text-sm">
        <li className={checks.exactLength ? 'text-green-500 font-bold' : 'text-gray-400 font-light'}>
          Dokładnie 6 cyfr
        </li>
        <li className={checks.isNumeric ? 'text-green-500 font-bold' : 'text-gray-400 font-light'}>
          Tylko cyfry
        </li>
        <li className={checks.notSimpleSequence ? 'text-green-500 font-bold' : 'text-gray-400 font-light'}>
          Nie może być prostą sekwencją (np. 123456, 111111)
        </li>
      </ul>
    )
  }

  return null
}
