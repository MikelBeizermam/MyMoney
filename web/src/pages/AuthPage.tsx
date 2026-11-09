import { useState, type FormEvent } from 'react'
import { useAuth } from '../auth/AuthProvider'
import { isValidEmail, MIN_PASSWORD, passwordProblem } from '../auth/errors'
import { Banner, Button, Field } from '../components/ui'

type Mode = 'signIn' | 'signUp' | 'forgot'

/** Errors Supabase puts in the URL when an email link is expired or already used. */
function linkErrorFromUrl(): string | null {
  const params = new URLSearchParams(window.location.search || window.location.hash.replace(/^#/, ''))
  if (!params.get('error_code') && !params.get('error')) return null
  window.history.replaceState(null, '', window.location.pathname)
  return 'הקישור פג תוקף או כבר נוצל. בקש קישור חדש.'
}

export default function AuthPage() {
  const auth = useAuth()
  const [mode, setMode] = useState<Mode>('signIn')
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(linkErrorFromUrl)
  const [info, setInfo] = useState<string | null>(null)

  const switchMode = (m: Mode) => {
    setMode(m)
    setError(null)
    setInfo(null)
  }

  const canSubmit =
    mode === 'forgot'
      ? isValidEmail(email)
      : isValidEmail(email) && password.length > 0 && (mode === 'signIn' || (fullName.trim() !== '' && confirm !== ''))

  async function submit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setInfo(null)
    if (mode === 'signUp') {
      const problem = passwordProblem(password)
      if (problem) return setError(problem)
      if (password !== confirm) return setError('הסיסמאות אינן תואמות.')
    }
    setBusy(true)
    try {
      if (mode === 'signIn') {
        await auth.signIn(email, password)
      } else if (mode === 'signUp') {
        const needsConfirmation = await auth.signUp(fullName, email, password)
        if (needsConfirmation) {
          setMode('signIn')
          setPassword('')
          setConfirm('')
          setInfo('שלחנו אליך מייל לאישור החשבון. לחץ על הקישור שבמייל ותועבר חזרה לכאן, מחובר.')
        }
      } else {
        await auth.sendPasswordReset(email)
        setInfo(`אם קיים חשבון עם ${email.trim().toLowerCase()}, נשלח אליו קישור לאיפוס הסיסמה.`)
      }
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <main className="auth">
      <form className="auth-card" onSubmit={submit} noValidate>
        <img className="auth-logo" src={`${import.meta.env.BASE_URL}icon.png`} alt="" />
        <div>
          <h1 className="auth-title">{mode === 'forgot' ? 'איפוס סיסמה' : 'MyMoney'}</h1>
        </div>
        <p className="auth-sub">
          {mode === 'signIn' && 'ברוך שובך! התחבר כדי לראות את ההוצאות שלך'}
          {mode === 'signUp' && 'צור חשבון והנתונים שלך יסונכרנו בין האתר לאייפון'}
          {mode === 'forgot' && 'הזן את האימייל שאיתו נרשמת ונשלח לך קישור לבחירת סיסמה חדשה'}
        </p>

        {mode !== 'forgot' && (
          <div className="segmented" role="group" aria-label="מצב">
            <button type="button" aria-pressed={mode === 'signIn'} onClick={() => switchMode('signIn')}>התחברות</button>
            <button type="button" aria-pressed={mode === 'signUp'} onClick={() => switchMode('signUp')}>הרשמה</button>
          </div>
        )}

        {mode === 'signUp' && (
          <Field label="שם מלא" autoComplete="name" value={fullName} onChange={(e) => setFullName(e.target.value)} />
        )}
        <Field
          label="אימייל" type="email" inputMode="email" autoComplete="username" ltr
          value={email} onChange={(e) => setEmail(e.target.value)} placeholder="name@example.com"
        />
        {mode !== 'forgot' && (
          <Field
            label="סיסמה" password autoComplete={mode === 'signUp' ? 'new-password' : 'current-password'}
            value={password} onChange={(e) => setPassword(e.target.value)}
            hint={mode === 'signUp' ? `לפחות ${MIN_PASSWORD} תווים, אותיות ומספרים` : undefined}
          />
        )}
        {mode === 'signUp' && (
          <Field label="אימות סיסמה" password autoComplete="new-password" value={confirm} onChange={(e) => setConfirm(e.target.value)} />
        )}

        {error && <Banner kind="error">{error}</Banner>}
        {info && <Banner kind="success">{info}</Banner>}

        <Button type="submit" block loading={busy} disabled={!canSubmit}>
          {mode === 'signIn' ? 'התחברות' : mode === 'signUp' ? 'יצירת חשבון' : 'שלח קישור איפוס'}
        </Button>

        {mode === 'signIn' && (
          <button type="button" className="link" onClick={() => switchMode('forgot')}>שכחתי סיסמה</button>
        )}
        {mode === 'forgot' && (
          <button type="button" className="link" onClick={() => switchMode('signIn')}>חזרה להתחברות</button>
        )}

        <p className="auth-foot">
          אותו חשבון עובד גם באפליקציית האייפון ·{' '}
          <a href="https://github.com/MikelBeizermam/MyMoney" target="_blank" rel="noreferrer">קוד המקור</a>
        </p>
      </form>
    </main>
  )
}
