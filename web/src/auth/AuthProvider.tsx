import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import type { Session, User } from '@supabase/supabase-js'
import { APP_URL, supabase } from '../lib/supabase'
import { authErrorMessage } from './errors'

interface AuthContextValue {
  user: User | null
  loading: boolean
  /** True after arriving from a password-reset email – show the "new password" screen. */
  recovering: boolean
  displayName: string
  signIn(email: string, password: string): Promise<void>
  /** Resolves to true when the user must confirm their email before signing in. */
  signUp(fullName: string, email: string, password: string): Promise<boolean>
  sendPasswordReset(email: string): Promise<void>
  updatePassword(password: string): Promise<void>
  finishRecovery(): void
  signOut(): Promise<void>
  deleteAccount(): Promise<void>
}

const AuthContext = createContext<AuthContextValue | null>(null)

// The reset link we send points back to `?flow=recovery`; Supabase appends `&code=…`.
const RECOVERY_REDIRECT = `${APP_URL}?flow=recovery`
const arrivedFromRecoveryLink = new URLSearchParams(window.location.search).get('flow') === 'recovery'

const normalize = (email: string) => email.trim().toLowerCase()

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)
  const [recovering, setRecovering] = useState(arrivedFromRecoveryLink)

  useEffect(() => {
    const { data } = supabase.auth.onAuthStateChange((event, s) => {
      setSession(s)
      setLoading(false)
      if (event === 'PASSWORD_RECOVERY') setRecovering(true)
      if (event === 'SIGNED_OUT') setRecovering(false)
      // Remove ?code=… / ?flow=… once Supabase has consumed them.
      if (s && window.location.search) {
        window.history.replaceState(null, '', window.location.pathname + window.location.hash)
      }
    })
    return () => data.subscription.unsubscribe()
  }, [])

  const user = session?.user ?? null
  const fullName = (user?.user_metadata?.full_name as string | undefined)?.trim()
  const displayName = fullName || user?.email?.split('@')[0] || ''

  const value: AuthContextValue = {
    user,
    loading,
    recovering: recovering && Boolean(user),
    displayName,

    async signIn(email, password) {
      const { error } = await supabase.auth.signInWithPassword({ email: normalize(email), password })
      if (error) throw new Error(authErrorMessage(error))
    },

    async signUp(fullName, email, password) {
      const { data, error } = await supabase.auth.signUp({
        email: normalize(email),
        password,
        options: { data: { full_name: fullName.trim() }, emailRedirectTo: APP_URL },
      })
      if (error) throw new Error(authErrorMessage(error))
      // With email confirmation on, an existing address returns a user with no identities.
      if (data.user && data.user.identities?.length === 0) {
        throw new Error('כבר קיים משתמש עם האימייל הזה.')
      }
      return !data.session
    },

    async sendPasswordReset(email) {
      const { error } = await supabase.auth.resetPasswordForEmail(normalize(email), { redirectTo: RECOVERY_REDIRECT })
      if (error) throw new Error(authErrorMessage(error))
    },

    async updatePassword(password) {
      const { error } = await supabase.auth.updateUser({ password })
      if (error) throw new Error(authErrorMessage(error))
    },

    finishRecovery() {
      setRecovering(false)
    },

    async signOut() {
      const { error } = await supabase.auth.signOut()
      if (error) await supabase.auth.signOut({ scope: 'local' })
    },

    async deleteAccount() {
      const { error } = await supabase.rpc('delete_my_account')
      if (error) throw new Error('מחיקת החשבון נכשלה. נסה שוב.')
      await supabase.auth.signOut({ scope: 'local' })
    },
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>')
  return ctx
}
