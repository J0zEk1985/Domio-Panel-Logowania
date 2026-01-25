import { validatePassword, validatePIN } from '../lib/validation'

interface ValidationChecklistProps {
  value: string
  type: 'password' | 'pin'
}

export default function ValidationChecklist({ value, type }: ValidationChecklistProps) {
  if (type === 'password') {
    const validation = validatePassword(value)

    return (
      <ul className="mt-2 space-y-1 text-sm">
        <li className={validation.isLong ? 'text-green-600 font-bold' : 'text-gray-400 font-light'}>
          Minimum 8 znaków
        </li>
        <li className={validation.hasUpper ? 'text-green-600 font-bold' : 'text-gray-400 font-light'}>
          Przynajmniej jedna wielka litera
        </li>
        <li className={validation.hasSpecial ? 'text-green-600 font-bold' : 'text-gray-400 font-light'}>
          Przynajmniej jedna cyfra lub znak specjalny
        </li>
      </ul>
    )
  }

  if (type === 'pin') {
    const validation = validatePIN(value)

    return (
      <ul className="mt-2 space-y-1 text-sm">
        <li className={validation.isSixDigits ? 'text-green-600 font-bold' : 'text-gray-400 font-light'}>
          Dokładnie 6 cyfr
        </li>
        <li className={validation.isNotSimple ? 'text-green-600 font-bold' : 'text-gray-400 font-light'}>
          Nie może być prostą sekwencją (np. 123456, 111111)
        </li>
      </ul>
    )
  }

  return null
}
