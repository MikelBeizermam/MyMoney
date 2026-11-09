import { useEffect, useState } from 'react'
import { AuthProvider, useAuth } from './auth/AuthProvider'
import TransactionForm from './components/TransactionForm'
import { Banner, GearIcon, HomeIcon, ListIcon, PiggyIcon, PlusIcon, Spinner } from './components/ui'
import { isConfigured } from './lib/supabase'
import type { Transaction } from './lib/types'
import { useFinanceData } from './lib/useFinanceData'
import AuthPage from './pages/AuthPage'
import Dashboard from './pages/Dashboard'
import NewPasswordModal from './pages/NewPasswordModal'
import Savings from './pages/Savings'
import Settings from './pages/Settings'
import Transactions from './pages/Transactions'

const TABS = [
  { id: 'home', label: 'בית', Icon: HomeIcon },
  { id: 'transactions', label: 'עסקאות', Icon: ListIcon },
  { id: 'savings', label: 'חיסכון', Icon: PiggyIcon },
  { id: 'settings', label: 'הגדרות', Icon: GearIcon },
] as const
type TabId = (typeof TABS)[number]['id']

/** Tab lives in the URL hash (#/transactions) so the back button and refresh work. */
function useHashTab(): [TabId, (t: TabId) => void] {
  const read = (): TabId => {
    const id = window.location.hash.replace(/^#\/?/, '')
    return (TABS.find((t) => t.id === id)?.id ?? 'home') as TabId
  }
  const [tab, setTab] = useState<TabId>(read)
  useEffect(() => {
    const onHash = () => setTab(read())
    window.addEventListener('hashchange', onHash)
    return () => window.removeEventListener('hashchange', onHash)
  }, [])
  return [tab, (t) => { window.location.hash = `/${t}`; window.scrollTo(0, 0) }]
}

export default function App() {
  if (!isConfigured) {
    return (
      <main className="auth">
        <div className="auth-card">
          <Banner kind="error">חסרה הגדרת Supabase. העתק את web/.env.example ל-web/.env.local ומלא את הערכים.</Banner>
        </div>
      </main>
    )
  }
  return (
    <AuthProvider>
      <Root />
    </AuthProvider>
  )
}

function Root() {
  const auth = useAuth()
  if (auth.loading) return <div className="center-screen"><Spinner /></div>
  if (!auth.user) return <AuthPage />
  return <SignedInApp key={auth.user.id} userId={auth.user.id} />
}

function SignedInApp({ userId }: { userId: string }) {
  const auth = useAuth()
  const data = useFinanceData(userId)
  const [tab, setTab] = useHashTab()
  const [editing, setEditing] = useState<Transaction | 'new' | null>(null)
  const firstName = auth.displayName.split(' ')[0]

  return (
    <div className="app">
      <nav className="sidebar" aria-label="ניווט ראשי">
        <div className="brand"><img src={`${import.meta.env.BASE_URL}icon.png`} alt="" />MyMoney</div>
        {TABS.map(({ id, label, Icon }) => (
          <button key={id} className="side-link" aria-current={tab === id ? 'page' : undefined} onClick={() => setTab(id)}>
            <Icon /> {label}
          </button>
        ))}
        <button className="btn btn-primary btn-sm" style={{ marginTop: 16 }} onClick={() => setEditing('new')}>
          <PlusIcon /> עסקה חדשה
        </button>
        <div className="side-foot">
          <span className={`live-dot${data.live ? ' on' : ''}`} aria-hidden />
          {data.live ? 'מסונכרן בזמן אמת' : 'מתחבר…'}
        </div>
      </nav>

      <main className="main">
        {data.error && <Banner kind="error">{data.error}</Banner>}
        {data.loading ? (
          <div className="center-screen" style={{ minHeight: '60dvh' }}><Spinner /></div>
        ) : (
          <>
            {tab === 'home' && <Dashboard data={data} name={firstName} onEdit={setEditing} onSeeAll={() => setTab('transactions')} />}
            {tab === 'transactions' && <Transactions data={data} onEdit={setEditing} onAdd={() => setEditing('new')} />}
            {tab === 'savings' && <Savings data={data} />}
            {tab === 'settings' && <Settings data={data} />}
          </>
        )}
      </main>

      {(tab === 'home' || tab === 'transactions') && (
        <button className="fab" onClick={() => setEditing('new')} aria-label="הוספת עסקה"><PlusIcon /></button>
      )}

      <nav className="tabbar" aria-label="ניווט ראשי">
        {TABS.map(({ id, label, Icon }) => (
          <button key={id} className="tab" aria-current={tab === id ? 'page' : undefined} onClick={() => setTab(id)}>
            <Icon />
            {label}
          </button>
        ))}
      </nav>

      {editing && (
        <TransactionForm
          existing={editing === 'new' ? undefined : editing}
          onSave={data.saveTransaction}
          onDelete={data.deleteTransaction}
          onClose={() => setEditing(null)}
        />
      )}
      {auth.recovering && <NewPasswordModal context="recovery" onClose={() => auth.finishRecovery()} />}
    </div>
  )
}
