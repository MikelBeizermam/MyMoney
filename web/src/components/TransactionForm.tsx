import { useState, type FormEvent } from 'react'
import { classifyToLabel } from '../lib/classifier'
import { fromDateInput, toDateInput } from '../lib/format'
import { CARDS, CATEGORIES, type Transaction } from '../lib/types'
import type { TransactionInput } from '../lib/useFinanceData'
import { Banner, Button, Field, Modal } from './ui'

interface Props {
  existing?: Transaction
  onSave(input: TransactionInput, id?: string): Promise<void>
  onDelete?(id: string): Promise<void>
  onClose(): void
}

export default function TransactionForm({ existing, onSave, onDelete, onClose }: Props) {
  const [amount, setAmount] = useState(existing ? String(existing.amount) : '')
  const [merchant, setMerchant] = useState(existing?.merchant ?? '')
  const [date, setDate] = useState(toDateInput(existing?.date ?? new Date().toISOString()))
  const [card, setCard] = useState<string>(existing?.card ?? CARDS[0].value)
  const [category, setCategory] = useState(existing?.category ?? CATEGORIES[CATEGORIES.length - 1].label)
  // Auto-suggest the category from the merchant name until the user picks one by hand.
  const [categoryTouched, setCategoryTouched] = useState(Boolean(existing))
  const [notes, setNotes] = useState(existing?.notes ?? '')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const parsedAmount = Number(amount.replace(',', '.'))
  const valid = amount !== '' && Number.isFinite(parsedAmount) && parsedAmount > 0 && merchant.trim() !== ''

  function onMerchant(value: string) {
    setMerchant(value)
    if (!categoryTouched) setCategory(classifyToLabel(value))
  }

  async function submit(e: FormEvent) {
    e.preventDefault()
    if (!valid) return
    setBusy(true)
    setError(null)
    try {
      await onSave(
        { amount: Math.round(parsedAmount * 100) / 100, merchant: merchant.trim(), date: fromDateInput(date, existing?.date), card, category, notes: notes.trim() },
        existing?.id,
      )
      onClose()
    } catch (err) {
      setError((err as Error).message)
      setBusy(false)
    }
  }

  async function remove() {
    if (!existing || !onDelete) return
    if (!window.confirm(`למחוק את העסקה ב${existing.merchant}?`)) return
    setBusy(true)
    try {
      await onDelete(existing.id)
      onClose()
    } catch (err) {
      setError((err as Error).message)
      setBusy(false)
    }
  }

  return (
    <Modal title={existing ? 'עריכת עסקה' : 'עסקה חדשה'} onClose={onClose}>
      <form className="stack" onSubmit={submit}>
        <Field label="סכום (₪)" inputMode="decimal" value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="0" autoFocus={!existing} ltr />
        <Field label="בית עסק" value={merchant} onChange={(e) => onMerchant(e.target.value)} placeholder="למשל: שופרסל" />
        <div className="grid-2">
          <Field label="תאריך" type="date" value={date} onChange={(e) => setDate(e.target.value)} />
          <div className="field">
            <span className="field-label">כרטיס</span>
            <div className="segmented" role="group" aria-label="כרטיס" style={{ height: 50, alignItems: 'center' }}>
              {CARDS.map((c) => (
                <button key={c.value} type="button" aria-pressed={card === c.value} onClick={() => setCard(c.value)} style={{ height: 42 }}>
                  {c.short}
                </button>
              ))}
            </div>
          </div>
        </div>
        <div className="field">
          <span className="field-label">קטגוריה{!categoryTouched && merchant ? ' · זוהתה אוטומטית' : ''}</span>
          <div className="chips" style={{ flexWrap: 'wrap' }}>
            {CATEGORIES.map((c) => (
              <button
                key={c.key} type="button" className="chip" aria-pressed={category === c.label}
                onClick={() => { setCategory(c.label); setCategoryTouched(true) }}
              >
                {c.emoji} {c.label}
              </button>
            ))}
          </div>
        </div>
        <Field label="הערה (לא חובה)" value={notes} onChange={(e) => setNotes(e.target.value)} />
        {error && <Banner kind="error">{error}</Banner>}
        <Button type="submit" block loading={busy} disabled={!valid}>{existing ? 'שמור שינויים' : 'הוסף עסקה'}</Button>
        {existing && onDelete && (
          <Button type="button" variant="danger" block onClick={remove} disabled={busy}>מחק עסקה</Button>
        )}
      </form>
    </Modal>
  )
}
