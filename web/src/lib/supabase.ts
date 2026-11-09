import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const key = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined

export const isConfigured = Boolean(url && key && !url.includes('YOUR-PROJECT-REF'))

/** Where Supabase sends users back after confirming their email or resetting a password. */
export const APP_URL = `${window.location.origin}${import.meta.env.BASE_URL}`

export const supabase = createClient(url ?? 'http://localhost', key ?? 'missing', {
  auth: {
    flowType: 'pkce',
    detectSessionInUrl: true,
    persistSession: true,
    autoRefreshToken: true,
  },
})
