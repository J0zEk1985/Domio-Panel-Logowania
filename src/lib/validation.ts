/**
 * Password and PIN validation utilities
 * Provides centralized validation logic for Owner passwords and Worker PINs
 */

export interface PasswordValidationResult {
  isValid: boolean
  errors: string[]
  checks: {
    minLength: boolean
    hasUpperCase: boolean
    hasNumberOrSpecial: boolean
  }
}

export interface PINValidationResult {
  isValid: boolean
  errors: string[]
  checks: {
    exactLength: boolean
    isNumeric: boolean
    notSimpleSequence: boolean
  }
}

/**
 * Validates password for Owner accounts
 * Requirements:
 * - Minimum 8 characters
 * - At least 1 uppercase letter
 * - At least 1 number or special character
 */
export function validatePassword(password: string): PasswordValidationResult {
  const checks = {
    minLength: password.length >= 8,
    hasUpperCase: /[A-Z]/.test(password),
    hasNumberOrSpecial: /[0-9!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password),
  }

  const errors: string[] = []
  if (!checks.minLength) errors.push('Hasło musi mieć minimum 8 znaków')
  if (!checks.hasUpperCase) errors.push('Hasło musi zawierać przynajmniej jedną wielką literę')
  if (!checks.hasNumberOrSpecial) errors.push('Hasło musi zawierać przynajmniej jedną cyfrę lub znak specjalny')

  return {
    isValid: checks.minLength && checks.hasUpperCase && checks.hasNumberOrSpecial,
    errors,
    checks,
  }
}

/**
 * Validates PIN for Worker accounts
 * Requirements:
 * - Exactly 6 digits
 * - Must be numeric
 * - Cannot be simple sequences (e.g., 123456, 111111, 000000)
 */
export function validatePIN(pin: string): PINValidationResult {
  const checks = {
    exactLength: pin.length === 6,
    isNumeric: /^\d+$/.test(pin),
    notSimpleSequence: !isSimpleSequence(pin),
  }

  const errors: string[] = []
  if (!checks.exactLength) errors.push('PIN musi składać się z dokładnie 6 cyfr')
  if (!checks.isNumeric) errors.push('PIN może zawierać tylko cyfry')
  if (!checks.notSimpleSequence) errors.push('PIN nie może być prostą sekwencją (np. 123456, 111111)')

  return {
    isValid: checks.exactLength && checks.isNumeric && checks.notSimpleSequence,
    errors,
    checks,
  }
}

/**
 * Checks if PIN is a simple sequence that should be rejected
 * Rejects:
 * - Sequential numbers (123456, 654321)
 * - Same digit repeated (111111, 000000)
 * - Common patterns (112233, 121212)
 */
function isSimpleSequence(pin: string): boolean {
  if (pin.length !== 6) return false

  // Check if all digits are the same
  if (/^(\d)\1{5}$/.test(pin)) return true

  // Check for sequential ascending (123456, 234567, etc.)
  let isAscending = true
  for (let i = 1; i < pin.length; i++) {
    if (parseInt(pin[i]) !== parseInt(pin[i - 1]) + 1) {
      isAscending = false
      break
    }
  }
  if (isAscending) return true

  // Check for sequential descending (654321, 543210, etc.)
  let isDescending = true
  for (let i = 1; i < pin.length; i++) {
    if (parseInt(pin[i]) !== parseInt(pin[i - 1]) - 1) {
      isDescending = false
      break
    }
  }
  if (isDescending) return true

  // Check for repeating pairs (112233, 121212, etc.)
  if (/^(\d{2})\1{2}$/.test(pin)) return true
  if (/^(\d)(\d)\1\2\1\2$/.test(pin)) return true

  return false
}

/**
 * Checks if new password is different from old password
 * Used to prevent reusing the same password
 */
export function isPasswordHistoryValid(newPassword: string, oldPassword: string | null): boolean {
  if (!oldPassword) return true
  return newPassword !== oldPassword
}
