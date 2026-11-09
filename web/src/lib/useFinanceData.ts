import { useCallback, useEffect, useRef, useState } from 'react'
import { supabase } from './supabase'
import type { SavingsGoal, Transaction } from './types'

export type TransactionInput = Pick<Transaction, 'amount' | 'merchant' | 'date' | 'category' | 'card' | 'notes'>

/**
 * Loads the signed-in user's data and keeps it live via Supabase Realtime,
 * so changes made on the iPhone appear here without a refresh.
 * Writes follow the same contract as the iOS sync engine:
 * client-generated UUIDs, `updated_at` for last-write-wins, soft deletes via `deleted_at`.
 */
export function useFinanceData(userId: string) {
  const [transactions, setTransactions] = useState<Transaction[]>([])
  const [goal, setGoal] = useState<SavingsGoal | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [live, setLive] = useState(false)
  const refetchTimer = useRef<number | undefined>(undefined)

  const load = useCallback(async () => {
    const [tx, g] = await Promise.all([
      supabase
        .from('transactions')
        .select('*')
        .eq('user_id', userId)
        .is('deleted_at', null)
        .order('date', { ascending: false })
        .limit(2000),
      supabase.from('savings_goals').select('*').eq('user_id', userId).maybeSingle(),
    ])
    if (tx.error || g.error) {
      setError('טעינת הנתונים נכשלה. בדוק את החיבור לאינטרנט.')
    } else {
      setError(null)
      setTransactions((tx.data as Transaction[]).map((t) => ({ ...t, amount: Number(t.amount) })))
      setGoal(
        g.data
          ? { ...g.data, monthly_income: Number(g.data.monthly_income), savings_target_percent: Number(g.data.savings_target_percent) }
          : null,
      )
    }
    setLoading(false)
  }, [userId])

  useEffect(() => {
    void load()

    // Any change to this user's rows (from any device) → debounced reload.
    const scheduleReload = () => {
      window.clearTimeout(refetchTimer.current)
      refetchTimer.current = window.setTimeout(() => void load(), 300)
    }
    const channel = supabase
      .channel(`finance-${userId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'transactions', filter: `user_id=eq.${userId}` }, scheduleReload)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'savings_goals', filter: `user_id=eq.${userId}` }, scheduleReload)
      .subscribe((status) => setLive(status === 'SUBSCRIBED'))

    const onFocus = () => void load()
    window.addEventListener('focus', onFocus)
    return () => {
      window.removeEventListener('focus', onFocus)
      window.clearTimeout(refetchTimer.current)
      void supabase.removeChannel(channel)
    }
  }, [userId, load])

  const saveTransaction = useCallback(
    async (input: TransactionInput, id?: string) => {
      const row = {
        id: id ?? crypto.randomUUID(),
        user_id: userId,
        ...input,
        updated_at: new Date().toISOString(),
        deleted_at: null,
      }
      // Optimistic update
      setTransactions((prev) =>
        [row as Transaction, ...prev.filter((t) => t.id !== row.id)].sort((a, b) => b.date.localeCompare(a.date)),
      )
      const { error } = await supabase.from('transactions').upsert(row)
      if (error) {
        await load()
        throw new Error('שמירת העסקה נכשלה.')
      }
    },
    [userId, load],
  )

  const deleteTransaction = useCallback(
    async (id: string) => {
      setTransactions((prev) => prev.filter((t) => t.id !== id))
      const now = new Date().toISOString()
      const { error } = await supabase.from('transactions').update({ deleted_at: now, updated_at: now }).eq('id', id)
      if (error) {
        await load()
        throw new Error('מחיקת העסקה נכשלה.')
      }
    },
    [load],
  )

  const saveGoal = useCallback(
    async (monthlyIncome: number, targetPercent: number) => {
      const now = new Date().toISOString()
      const row: SavingsGoal = {
        id: userId,
        user_id: userId,
        monthly_income: monthlyIncome,
        savings_target_percent: targetPercent,
        created_at: goal?.created_at ?? now,
        updated_at: now,
      }
      setGoal(row)
      const { error } = await supabase.from('savings_goals').upsert(row)
      if (error) {
        await load()
        throw new Error('שמירת היעד נכשלה.')
      }
    },
    [userId, goal, load],
  )

  return { transactions, goal, loading, error, live, reload: load, saveTransaction, deleteTransaction, saveGoal }
}

export type FinanceData = ReturnType<typeof useFinanceData>
