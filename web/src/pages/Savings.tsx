import { useState, type FormEvent } from 'react'
import { Banner, Button, Field, Modal } from '../components/ui'
import { money, startOfMonth } from '../lib/format'
import type { FinanceData } from '../lib/useFinanceData'

export default function Savings({ data }: { data: FinanceData }) {
  const { goal, transactions } = data
  const [editing, setEditing] = useState(false)

  const start = startOfMonth().toISOString()
  const spent = transactions.filter((t) => t.date >= start).reduce((s, t) => s + t.amount, 0)

  if (!goal) {
    return (
      <div className="stack">
        <header className="page-head"><h1 className="page-title">חיסכון</h1></header>
        <section className="card empty">
          <div className="empty-icon">🐷</div>
          <h2 className="card-title">הגדר יעד חיסכון</h2>
          <p style={{ marginBottom: 18 }}>הזן את ההכנסה החודשית ואת אחוז החיסכון, ונחשב כמה בטוח להוציא כל חודש.</p>
          <Button onClick={() => setEditing(true)}>הגדרת יעד</Button>
        </section>
        {editing && <GoalForm data={data} onClose={() => setEditing(false)} />}
      </div>
    )
  }

  const target = goal.monthly_income * goal.savings_target_percent
  const budget = goal.monthly_income - target
  const safe = budget - spent
  const usedPct = budget > 0 ? Math.min(100, (spent / budget) * 100) : 100
  const projectedSaving = goal.monthly_income - spent
  const savingProgress = target > 0 ? Math.max(0, Math.min(100, (projectedSaving / target) * 100)) : 0

  return (
    <div className="stack">
      <header className="page-head">
        <h1 className="page-title">חיסכון</h1>
        <Button small variant="ghost" onClick={() => setEditing(true)}>עריכת יעד</Button>
      </header>

      <section className="card hero">
        <p className="hero-label">בטוח להוציא עוד החודש</p>
        <p className="hero-amount num" style={{ color: safe >= 0 ? 'var(--green)' : 'var(--red)' }}>{money(Math.max(0, safe))}</p>
        {safe < 0 && <p style={{ color: 'var(--red)' }}>חרגת ב-{money(-safe)} מהתקציב</p>}
      </section>

      <section className="card stack">
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
          <span className="card-title" style={{ margin: 0 }}>ניצול תקציב ההוצאות</span>
          <span className="num muted">{Math.round(usedPct)}%</span>
        </div>
        <div className="progress" role="progressbar" aria-valuenow={Math.round(usedPct)} aria-valuemin={0} aria-valuemax={100} aria-label="ניצול תקציב">
          <div style={{ width: `${usedPct}%`, background: usedPct >= 100 ? 'var(--red)' : usedPct >= 80 ? '#fbbf24' : 'var(--green-bar)' }} />
        </div>
        <p className="muted small num">{money(spent)} מתוך {money(budget)}</p>
      </section>

      <section className="card stack">
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
          <span className="card-title" style={{ margin: 0 }}>התקדמות ליעד החיסכון</span>
          <span className="num muted">{Math.round(savingProgress)}%</span>
        </div>
        <div className="progress" role="progressbar" aria-valuenow={Math.round(savingProgress)} aria-valuemin={0} aria-valuemax={100} aria-label="התקדמות חיסכון">
          <div style={{ width: `${savingProgress}%`, background: 'var(--green-bar)' }} />
        </div>
        <p className="muted small">בקצב הנוכחי יישארו לך {money(Math.max(0, projectedSaving))} בסוף החודש. היעד: {money(target)}.</p>
      </section>

      <section className="list">
        <div className="list-row"><span style={{ flex: 1 }}>הכנסה חודשית</span><span className="num">{money(goal.monthly_income)}</span></div>
        <div className="list-row"><span style={{ flex: 1 }}>יעד חיסכון ({Math.round(goal.savings_target_percent * 100)}%)</span><span className="num">{money(target)}</span></div>
        <div className="list-row"><span style={{ flex: 1 }}>תקציב להוצאות</span><span className="num">{money(budget)}</span></div>
        <div className="list-row"><span style={{ flex: 1 }}>הוצאת עד כה</span><span className="num">{money(spent)}</span></div>
      </section>

      {editing && <GoalForm data={data} onClose={() => setEditing(false)} />}
    </div>
  )
}

function GoalForm({ data, onClose }: { data: FinanceData; onClose(): void }) {
  const [income, setIncome] = useState(data.goal ? String(data.goal.monthly_income) : '')
  const [percent, setPercent] = useState(data.goal ? Math.round(data.goal.savings_target_percent * 100) : 20)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const value = Number(income.replace(',', '.'))
  const valid = Number.isFinite(value) && value > 0

  async function submit(e: FormEvent) {
    e.preventDefault()
    setBusy(true)
    try {
      await data.saveGoal(value, percent / 100)
      onClose()
    } catch (err) {
      setError((err as Error).message)
      setBusy(false)
    }
  }

  return (
    <Modal title="יעד חיסכון" onClose={onClose}>
      <form className="stack" onSubmit={submit}>
        <Field label="הכנסה חודשית נטו (₪)" inputMode="decimal" value={income} onChange={(e) => setIncome(e.target.value)} autoFocus ltr />
        <div className="field">
          <label className="field-label" htmlFor="pct">יעד חיסכון: {percent}%{valid && ` · ${money((value * percent) / 100)} בחודש`}</label>
          <input id="pct" type="range" min={5} max={50} step={5} value={percent} onChange={(e) => setPercent(Number(e.target.value))} />
        </div>
        {error && <Banner kind="error">{error}</Banner>}
        <Button type="submit" block loading={busy} disabled={!valid}>שמירה</Button>
      </form>
    </Modal>
  )
}
