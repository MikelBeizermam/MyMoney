import { dayMonth, moneyPrecise } from '../lib/format'
import { cardColor, categoryByLabel, type Transaction } from '../lib/types'

export default function TransactionRow({ tx, onClick, showDate = true }: { tx: Transaction; onClick?(): void; showDate?: boolean }) {
  const cat = categoryByLabel(tx.category)
  const content = (
    <>
      <span className="tx-icon" title={cat.label} aria-label={cat.label} role="img">{cat.emoji}</span>
      <span className="tx-main">
        <span className="tx-merchant" style={{ display: 'block' }}>{tx.merchant}</span>
        <span className="tx-sub">
          <span className="dot" style={{ background: cardColor(tx.card) }} aria-hidden />
          {tx.card}
          {showDate && <> · {dayMonth(tx.date)}</>}
        </span>
      </span>
      <span className="tx-amount num">{moneyPrecise(tx.amount)}</span>
    </>
  )
  return onClick ? (
    <button className="tx" onClick={onClick} aria-label={`${tx.merchant}, ${moneyPrecise(tx.amount)}. לחץ לעריכה`}>{content}</button>
  ) : (
    <div className="tx">{content}</div>
  )
}
