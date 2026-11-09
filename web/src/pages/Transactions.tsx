import { useMemo, useState } from 'react'
import TransactionRow from '../components/TransactionRow'
import { PlusIcon, Button } from '../components/ui'
import { money } from '../lib/format'
import { CARDS, CATEGORIES, type Transaction } from '../lib/types'
import type { FinanceData } from '../lib/useFinanceData'

export default function Transactions({ data, onEdit, onAdd }: { data: FinanceData; onEdit(tx: Transaction): void; onAdd(): void }) {
  const [card, setCard] = useState<string | null>(null)
  const [category, setCategory] = useState<string | null>(null)
  const [query, setQuery] = useState('')

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    return data.transactions.filter(
      (t) =>
        (!card || t.card === card) &&
        (!category || t.category === category) &&
        (!q || t.merchant.toLowerCase().includes(q) || t.notes.toLowerCase().includes(q)),
    )
  }, [data.transactions, card, category, query])

  // Group by calendar day for scannability
  const groups = useMemo(() => {
    const out: { day: string; items: Transaction[]; total: number }[] = []
    for (const t of filtered) {
      const day = new Date(t.date).toLocaleDateString('he-IL', { weekday: 'long', day: 'numeric', month: 'long' })
      const last = out[out.length - 1]
      if (last?.day === day) { last.items.push(t); last.total += t.amount } else out.push({ day, items: [t], total: t.amount })
    }
    return out
  }, [filtered])

  const usedCategories = CATEGORIES.filter((c) => data.transactions.some((t) => t.category === c.label))

  return (
    <div className="stack">
      <header className="page-head">
        <h1 className="page-title">עסקאות</h1>
        <Button small onClick={onAdd} className="desktop-only"><PlusIcon /> עסקה חדשה</Button>
      </header>

      <input className="search" type="search" placeholder="חיפוש לפי בית עסק או הערה" value={query} onChange={(e) => setQuery(e.target.value)} aria-label="חיפוש" />

      <div className="chips" role="group" aria-label="סינון לפי כרטיס">
        <button className="chip" aria-pressed={card === null} onClick={() => setCard(null)}>כל הכרטיסים</button>
        {CARDS.map((c) => (
          <button key={c.value} className="chip" aria-pressed={card === c.value} onClick={() => setCard(card === c.value ? null : c.value)}>
            <span className="dot" style={{ background: c.color, marginInlineEnd: 6 }} aria-hidden />{c.value}
          </button>
        ))}
      </div>
      {usedCategories.length > 1 && (
        <div className="chips" role="group" aria-label="סינון לפי קטגוריה">
          <button className="chip" aria-pressed={category === null} onClick={() => setCategory(null)}>הכל</button>
          {usedCategories.map((c) => (
            <button key={c.key} className="chip" aria-pressed={category === c.label} onClick={() => setCategory(category === c.label ? null : c.label)}>
              {c.emoji} {c.label}
            </button>
          ))}
        </div>
      )}

      <section className="card" style={{ paddingTop: 6 }}>
        {filtered.length === 0 ? (
          <div className="empty">
            <div className="empty-icon">🔍</div>
            {data.transactions.length === 0 ? 'אין עסקאות עדיין.' : 'לא נמצאו עסקאות שמתאימות לסינון.'}
          </div>
        ) : (
          groups.map((g) => (
            <div key={g.day}>
              <div className="day-head" style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>{g.day}</span><span className="num">{money(g.total)}</span>
              </div>
              <div className="tx-list">
                {g.items.map((t) => <TransactionRow key={t.id} tx={t} showDate={false} onClick={() => onEdit(t)} />)}
              </div>
            </div>
          ))
        )}
      </section>
      {filtered.length > 0 && (
        <p className="muted small" style={{ textAlign: 'center' }}>
          {filtered.length} עסקאות · סה"כ {money(filtered.reduce((s, t) => s + t.amount, 0))}
        </p>
      )}
    </div>
  )
}
