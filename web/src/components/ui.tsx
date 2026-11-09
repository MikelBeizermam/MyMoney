import { useEffect, useId, useState, type InputHTMLAttributes, type ReactNode } from 'react'

export function Banner({ kind, children }: { kind: 'error' | 'success'; children: ReactNode }) {
  return (
    <div className={`banner banner-${kind}`} role={kind === 'error' ? 'alert' : 'status'}>
      <span aria-hidden>{kind === 'error' ? '⚠️' : '✓'}</span>
      <span>{children}</span>
    </div>
  )
}

export function Spinner() {
  return <span className="spinner" aria-label="טוען" />
}

export function Button({
  loading, children, variant = 'primary', block, small, ...rest
}: {
  loading?: boolean
  variant?: 'primary' | 'ghost' | 'danger'
  block?: boolean
  small?: boolean
} & React.ButtonHTMLAttributes<HTMLButtonElement>) {
  const cls = ['btn', `btn-${variant}`, block && 'btn-block', small && 'btn-sm', rest.className].filter(Boolean).join(' ')
  return (
    <button {...rest} className={cls} disabled={rest.disabled || loading}>
      {loading ? <Spinner /> : children}
    </button>
  )
}

export function Field({
  label, hint, password, ltr, ...input
}: { label: string; hint?: string; password?: boolean; ltr?: boolean } & InputHTMLAttributes<HTMLInputElement>) {
  const id = useId()
  const [reveal, setReveal] = useState(false)
  return (
    <div className="field">
      <label className="field-label" htmlFor={id}>{label}</label>
      {password ? (
        <div className="input-wrap">
          <input {...input} id={id} className="input ltr" type={reveal ? 'text' : 'password'} dir="ltr" />
          <button type="button" className="reveal" onClick={() => setReveal((r) => !r)} aria-label={reveal ? 'הסתר סיסמה' : 'הצג סיסמה'}>
            {reveal ? <EyeOff /> : <Eye />}
          </button>
        </div>
      ) : (
        <input {...input} id={id} className={`input${ltr ? ' ltr' : ''}`} dir={ltr ? 'ltr' : undefined} />
      )}
      {hint && <span className="hint">{hint}</span>}
    </div>
  )
}

export function Modal({ title, onClose, children, dismissable = true }: { title: string; onClose(): void; children: ReactNode; dismissable?: boolean }) {
  useEffect(() => {
    if (!dismissable) return
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose()
    window.addEventListener('keydown', onKey)
    const prev = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      window.removeEventListener('keydown', onKey)
      document.body.style.overflow = prev
    }
  }, [onClose, dismissable])

  return (
    <div className="overlay" onMouseDown={(e) => dismissable && e.target === e.currentTarget && onClose()}>
      <div className="modal" role="dialog" aria-modal="true" aria-label={title}>
        <div className="modal-head">
          <h2 className="modal-title">{title}</h2>
          {dismissable && (
            <button className="icon-btn" onClick={onClose} aria-label="סגור">
              <XIcon />
            </button>
          )}
        </div>
        {children}
      </div>
    </div>
  )
}

/* ---------- Icons (inline SVG, stroke = currentColor) ---------- */
const svg = (d: ReactNode) => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" aria-hidden>
    {d}
  </svg>
)
export const HomeIcon = () => svg(<><path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z" /></>)
export const ListIcon = () => svg(<><path d="M8 6h13M8 12h13M8 18h13" /><circle cx="3.5" cy="6" r="1" /><circle cx="3.5" cy="12" r="1" /><circle cx="3.5" cy="18" r="1" /></>)
export const PiggyIcon = () => svg(<><path d="M19 9c1.5.5 2 1.5 2 3v2h-2l-1 3h-3v-2H9v2H6l-1-3c-1.5-1-2-2.5-2-4 0-3.5 3.5-6 8-6 1.4 0 2.8.2 4 .6L17 3v4" /><circle cx="15.5" cy="10.5" r=".6" fill="currentColor" /></>)
export const GearIcon = () => svg(<><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z" /></>)
export const PlusIcon = () => svg(<path d="M12 5v14M5 12h14" />)
export const XIcon = () => svg(<path d="M18 6 6 18M6 6l12 12" />)
export const Eye = () => svg(<><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z" /><circle cx="12" cy="12" r="3" /></>)
export const EyeOff = () => svg(<><path d="M17.9 17.9A10.4 10.4 0 0 1 12 19c-6.5 0-10-7-10-7a18.5 18.5 0 0 1 5.1-5.9M9.9 4.2A9.6 9.6 0 0 1 12 4c6.5 0 10 7 10 7a18.6 18.6 0 0 1-2.2 3.2M14.1 14.1a3 3 0 1 1-4.2-4.2M2 2l20 20" /></>)
