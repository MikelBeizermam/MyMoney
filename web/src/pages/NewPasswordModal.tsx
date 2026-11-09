import { useState, type FormEvent } from 'react'
import { useAuth } from '../auth/AuthProvider'
import { MIN_PASSWORD, passwordProblem } from '../auth/errors'
import { Banner, Button, Field, Modal } from '../components/ui'

/** "Choose a new password" – opened by a reset email link, or from Settings → change password. */
export default function NewPasswordModal({ context, onClose }: { context: 'recovery' | 'change'; onClose(): void }) {
  const auth = useAuth()
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [done, setDone] = useState(false)

  async function submit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    const problem = passwordProblem(password)
    if (problem) return setError(problem)
    if (password !== confirm) return setError('הסיסמאות אינן תואמות.')
    setBusy(true)
    try {
      await auth.updatePassword(password)
      setDone(true)
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(false)
    }
  }

  const close = () => {
    auth.finishRecovery()
    onClose()
  }

  return (
    <Modal title={done ? 'הסיסמה עודכנה' : 'בחר סיסמה חדשה'} onClose={close} dismissable={context === 'change' || done}>
      {done ? (
        <div className="stack">
          <Banner kind="success">מעכשיו התחבר עם הסיסמה החדשה, גם באתר וגם באפליקציה.</Banner>
          <Button block onClick={close}>המשך</Button>
        </div>
      ) : (
        <form className="stack" onSubmit={submit}>
          <Field label="סיסמה חדשה" password autoComplete="new-password" value={password} onChange={(e) => setPassword(e.target.value)} hint={`לפחות ${MIN_PASSWORD} תווים, אותיות ומספרים`} autoFocus />
          <Field label="אימות סיסמה" password autoComplete="new-password" value={confirm} onChange={(e) => setConfirm(e.target.value)} />
          {error && <Banner kind="error">{error}</Banner>}
          <Button type="submit" block loading={busy} disabled={!password || !confirm}>שמור סיסמה</Button>
        </form>
      )}
    </Modal>
  )
}
