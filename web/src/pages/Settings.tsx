import { useState } from 'react'
import { useAuth } from '../auth/AuthProvider'
import { Banner, Button, Field, Modal } from '../components/ui'
import type { FinanceData } from '../lib/useFinanceData'
import NewPasswordModal from './NewPasswordModal'

export default function Settings({ data }: { data: FinanceData }) {
  const auth = useAuth()
  const [changePassword, setChangePassword] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(false)
  const [signingOut, setSigningOut] = useState(false)

  async function signOut() {
    if (!window.confirm('להתנתק מהחשבון? הנתונים שמורים בענן ויחזרו כשתתחבר שוב.')) return
    setSigningOut(true)
    await auth.signOut()
  }

  return (
    <div className="stack">
      <header className="page-head"><h1 className="page-title">הגדרות</h1></header>

      <p className="section-label">החשבון שלי</p>
      <section className="list">
        <div className="list-row">
          <span className="avatar" aria-hidden>{auth.displayName.charAt(0).toUpperCase()}</span>
          <span style={{ flex: 1, minWidth: 0 }}>
            <strong style={{ display: 'block' }}>{auth.displayName}</strong>
            <span className="muted small ltr" style={{ display: 'block' }}>{auth.user?.email}</span>
          </span>
        </div>
        <button className="list-row" onClick={() => setChangePassword(true)}>🔑 <span style={{ flex: 1 }}>שינוי סיסמה</span><span className="muted">‹</span></button>
      </section>

      <p className="section-label">סנכרון</p>
      <section className="list">
        <div className="list-row">
          <span className={`live-dot${data.live ? ' on' : ''}`} aria-hidden />
          <span style={{ flex: 1 }}>{data.live ? 'מחובר בזמן אמת' : 'מתחבר…'}</span>
          <Button small variant="ghost" onClick={() => void data.reload()}>רענן</Button>
        </div>
        <div className="list-row muted small">שינויים שתעשה כאן מופיעים מיד באפליקציית האייפון, ולהפך.</div>
      </section>

      <p className="section-label">אפליקציית האייפון</p>
      <section className="list">
        <div className="list-row small">
          <span style={{ flex: 1 }}>
            כדי שעסקאות ייקלטו אוטומטית מ-Wallet, הגדר אוטומציה ב-Shortcuts שפותחת את הקישור:
            <code className="ltr" style={{ display: 'block', marginTop: 8, color: 'var(--green)', fontSize: 12, wordBreak: 'break-all' }}>
              mymoney://add?amount=[AMOUNT]&amp;merchant=[MERCHANT]&amp;card=[CARD]
            </code>
          </span>
        </div>
      </section>

      <section className="stack" style={{ marginTop: 8 }}>
        <Button variant="ghost" block loading={signingOut} onClick={signOut}>התנתקות</Button>
        <Button variant="danger" block onClick={() => setConfirmDelete(true)}>מחיקת חשבון</Button>
      </section>

      <p className="muted small" style={{ textAlign: 'center', marginTop: 8 }}>
        MyMoney Web · <a href="https://github.com/MikelBeizermam/MyMoney" target="_blank" rel="noreferrer">GitHub</a>
      </p>

      {changePassword && <NewPasswordModal context="change" onClose={() => setChangePassword(false)} />}
      {confirmDelete && <DeleteAccountModal onClose={() => setConfirmDelete(false)} />}
    </div>
  )
}

function DeleteAccountModal({ onClose }: { onClose(): void }) {
  const auth = useAuth()
  const [typed, setTyped] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const WORD = 'מחק'

  async function remove() {
    setBusy(true)
    setError(null)
    try {
      await auth.deleteAccount()
    } catch (err) {
      setError((err as Error).message)
      setBusy(false)
    }
  }

  return (
    <Modal title="מחיקת חשבון" onClose={onClose}>
      <div className="stack">
        <Banner kind="error">החשבון וכל העסקאות ויעדי החיסכון יימחקו לצמיתות, מהאתר ומהאייפון. אי אפשר לבטל את הפעולה.</Banner>
        <Field label={`כדי לאשר, הקלד "${WORD}"`} value={typed} onChange={(e) => setTyped(e.target.value)} />
        {error && <Banner kind="error">{error}</Banner>}
        <Button variant="danger" block loading={busy} disabled={typed.trim() !== WORD} onClick={remove}>מחק את החשבון לצמיתות</Button>
        <Button variant="ghost" block onClick={onClose}>ביטול</Button>
      </div>
    </Modal>
  )
}
