/**
 * Password and PIN validation utilities
 * Provides centralized validation logic for Owner passwords and Worker PINs
 */

export interface PasswordValidationResult {
  isLong: boolean
  hasUpper: boolean
  hasSpecial: boolean
  allValid: boolean
}

export interface PINValidationResult {
  isSixDigits: boolean
  isNotSimple: boolean
  allValid: boolean
}

/**
 * Validates password for Owner accounts
 * Requirements:
 * - Minimum 8 characters
 * - At least 1 uppercase letter
 * - At least 1 number or special character
 */
export function validatePassword(password: string): PasswordValidationResult {
  const isLong = password.length >= 8
  const hasUpper = /[A-Z]/.test(password)
  const hasSpecial = /[0-9!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)
  const allValid = isLong && hasUpper && hasSpecial

  return {
    isLong,
    hasUpper,
    hasSpecial,
    allValid,
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
  const isSixDigits = pin.length === 6 && /^\d+$/.test(pin)
  const isNotSimple = !isSimpleSequence(pin)
  const allValid = isSixDigits && isNotSimple

  return {
    isSixDigits,
    isNotSimple,
    allValid,
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
