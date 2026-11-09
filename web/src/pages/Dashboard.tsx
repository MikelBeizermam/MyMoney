import { useMemo, useState } from 'react'
import TransactionRow from '../components/TransactionRow'
import { money, monthYear, startOfMonth } from '../lib/format'
import { CARDS, categoryByLabel, type Transaction } from '../lib/types'
import type { FinanceData } from '../lib/useFinanceData'

interface Props {
  data: FinanceData
  name: string
  onEdit(tx: Transaction): void
  onSeeAll(): void
}

export default function Dashboard({ data, name, onEdit, onSeeAll }: Props) {
  const { transactions, goal } = data
  const month = useMemo(() => {
    const start = startOfMonth().toISOString()
    return transactions.filter((t) => t.date >= start)
  }, [transactions])

  const total = month.reduce((s, t) => s + t.amount, 0)
  const byCard = CARDS.map((c) => ({ ...c, total: month.filter((t) => t.card === c.value).reduce((s, t) => s + t.amount, 0) }))
  const byCategory = useMemo(() => {
    const map = new Map<string, number>()
    for (const t of month) map.set(t.category, (map.get(t.category) ?? 0) + t.amount)
    return [...map.entries()].sort((a, b) => b[1] - a[1])
  }, [month])
  const max = byCategory[0]?.[1] ?? 0
  const safe = goal ? goal.monthly_income * (1 - goal.savings_target_percent) - total : null

  return (
    <div className="stack">
      <header className="page-head">
        <div>
          <h1 className="page-title">שלום{name ? ` ${name}` : ''} 👋</h1>
          <p className="muted small">{monthYear()}</p>
        </div>
      </header>

      <section className="card hero" aria-label="סיכום החודש">
        <p className="hero-label">סה"כ הוצאות החודש</p>
        <p className="hero-amount num">{money(total)}</p>
        <p className="muted small">{month.length} עסקאות</p>
      </section>

      <div className="grid-2">
        {byCard.map((c) => (
          <div className="tile" key={c.value}>
            <p className="tile-label"><span className="dot" style={{ background: c.color }} aria-hidden />{c.value}</p>
            <p className="tile-value num">{money(c.total)}</p>
          </div>
        ))}
      </div>

      {safe !== null && (
        <div className="tile">
          <p className="tile-label">בטוח להוציא עוד החודש</p>
          <p className="tile-value num" style={{ color: safe >= 0 ? 'var(--green)' : 'var(--red)' }}>
            {safe >= 0 ? money(safe) : `חריגה של ${money(-safe)}`}
          </p>
        </div>
      )}

      {byCategory.length > 0 && (
        <section className="card" aria-labelledby="cat-title">
          <h2 className="card-title" id="cat-title">הוצאות לפי קטגוריה</h2>
          <CategoryBars rows={byCategory} max={max} total={total} />
        </section>
      )}

      <section className="card" aria-labelledby="recent-title">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <h2 className="card-title" id="recent-title">עסקאות אחרונות</h2>
          {transactions.length > 5 && <button className="link" onClick={onSeeAll}>הכל</button>}
        </div>
        {transactions.length === 0 ? (
          <div className="empty">
            <div className="empty-icon">💳</div>
            אין עסקאות עדיין. הוסף עסקה ראשונה, והיא תופיע גם באייפון.
          </div>
        ) : (
          <div className="tx-list">
            {transactions.slice(0, 5).map((t) => <TransactionRow key={t.id} tx={t} onClick={() => onEdit(t)} />)}
          </div>
        )}
      </section>
    </div>
  )
}

/** Horizontal bars, one series → one hue. Category identity is carried by the label, not by color. */
function CategoryBars({ rows, max, total }: { rows: [string, number][]; max: number; total: number }) {
  const [hover, setHover] = useState<string | null>(null)
  return (
    <div className="bars" role="list">
      {rows.map(([label, amount]) => {
        const cat = categoryByLabel(label)
        const pct = total > 0 ? Math.round((amount / total) * 100) : 0
        return (
          <div
            key={label} className="bar-row" role="listitem" tabIndex={0}
            aria-label={`${cat.label}: ${money(amount)}, ${pct}% מההוצאות`}
            onMouseEnter={() => setHover(label)} onMouseLeave={() => setHover(null)}
            onFocus={() => setHover(label)} onBlur={() => setHover(null)}
          >
            <span className="bar-label">{cat.emoji} {cat.label}</span>
            <span className="bar-track"><span className="bar-fill" style={{ width: `${Math.max(2, (amount / max) * 100)}%`, display: 'block' }} /></span>
            <span className="bar-value num">{money(amount)}</span>
            {hover === label && (
              <span className="tooltip" role="tooltip">
                <strong>{cat.label}</strong> · {money(amount)} · {pct}% מהחודש
              </span>
            )}
          </div>
        )
      })}
    </div>
  )
}
