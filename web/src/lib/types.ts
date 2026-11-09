// Shared domain types. String values match the iOS app's raw values exactly,
// because both clients read and write the same Supabase rows.

export type CategoryKey =
  | 'supermarket' | 'restaurants' | 'fuel' | 'health' | 'shopping'
  | 'entertainment' | 'education' | 'housing' | 'coffee' | 'other'

export const CATEGORIES: { key: CategoryKey; label: string; emoji: string }[] = [
  { key: 'supermarket',   label: 'סופרמרקט',          emoji: '🛒' },
  { key: 'restaurants',   label: 'מסעדות',            emoji: '🍔' },
  { key: 'fuel',          label: 'דלק ותחבורה',       emoji: '⛽' },
  { key: 'health',        label: 'בריאות',            emoji: '💊' },
  { key: 'shopping',      label: 'קניות',             emoji: '👕' },
  { key: 'entertainment', label: 'בידור',             emoji: '🎬' },
  { key: 'education',     label: 'חינוך',             emoji: '📚' },
  { key: 'housing',       label: 'דיור',              emoji: '🏠' },
  { key: 'coffee',        label: 'קפה',               emoji: '☕' },
  { key: 'other',         label: 'בית עסק לא מוכר',   emoji: '💳' },
]

export const CARDS = [
  { value: 'ישראכארט', short: 'ישראכארט', color: '#FF6B6B' },
  { value: 'כאל',      short: 'כאל',      color: '#60A5FA' },
] as const

export type CardValue = (typeof CARDS)[number]['value']

export function categoryByLabel(label: string) {
  return CATEGORIES.find((c) => c.label === label) ?? CATEGORIES[CATEGORIES.length - 1]
}

export function cardColor(card: string) {
  return CARDS.find((c) => c.value === card)?.color ?? '#9CA3AF'
}

/** Row of public.transactions */
export interface Transaction {
  id: string
  user_id: string
  amount: number
  merchant: string
  date: string
  category: string
  card: string
  notes: string
  updated_at: string
  deleted_at: string | null
}

/** Row of public.savings_goals (one per user, id = user_id) */
export interface SavingsGoal {
  id: string
  user_id: string
  monthly_income: number
  savings_target_percent: number
  created_at: string
  updated_at: string
}
