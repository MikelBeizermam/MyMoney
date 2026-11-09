import { isAuthApiError, type AuthError } from '@supabase/supabase-js'

/** Maps Supabase Auth errors to Hebrew messages (same wording as the iOS app). */
export function authErrorMessage(error: AuthError): string {
  if (!navigator.onLine) return 'אין חיבור לאינטרנט. נסה שוב.'
  const code = isAuthApiError(error) ? error.code : undefined
  switch (code) {
    case 'invalid_credentials':
      return 'אימייל או סיסמה שגויים.'
    case 'email_not_confirmed':
      return 'צריך לאשר את כתובת האימייל. בדוק את תיבת הדואר.'
    case 'user_already_exists':
    case 'email_exists':
      return 'כבר קיים משתמש עם האימייל הזה.'
    case 'weak_password':
      return 'הסיסמה חלשה מדי. בחר סיסמה של 8 תווים לפחות, עם אותיות ומספרים.'
    case 'same_password':
      return 'הסיסמה החדשה חייבת להיות שונה מהקודמת.'
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
      return 'יותר מדי ניסיונות. נסה שוב בעוד כמה דקות.'
    case 'otp_expired':
    case 'flow_state_expired':
    case 'flow_state_not_found':
    case 'bad_code_verifier':
      return 'הקישור פג תוקף או כבר נוצל. בקש קישור חדש.'
    case 'session_not_found':
    case 'session_expired':
      return 'פג תוקף ההתחברות. התחבר מחדש.'
    default:
      return 'משהו השתבש. נסה שוב.'
  }
}

export const MIN_PASSWORD = 8

export function passwordProblem(password: string): string | null {
  if (password.length < MIN_PASSWORD) return `הסיסמה צריכה להכיל לפחות ${MIN_PASSWORD} תווים.`
  if (!/\p{L}/u.test(password) || !/\d/.test(password)) return 'הסיסמה צריכה לכלול אותיות ומספרים.'
  return null
}

export const isValidEmail = (email: string) =>
  /^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/.test(email.trim())
