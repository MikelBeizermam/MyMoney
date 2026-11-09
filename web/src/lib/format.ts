const ils = new Intl.NumberFormat('he-IL', { style: 'currency', currency: 'ILS', maximumFractionDigits: 0 })
const ilsPrecise = new Intl.NumberFormat('he-IL', { style: 'currency', currency: 'ILS', maximumFractionDigits: 2 })

export const money = (n: number) => ils.format(Math.round(n))
export const moneyPrecise = (n: number) => ilsPrecise.format(n)

export const dayMonth = (iso: string) =>
  new Date(iso).toLocaleDateString('he-IL', { day: 'numeric', month: 'long' })

export const monthYear = (d = new Date()) =>
  d.toLocaleDateString('he-IL', { month: 'long', year: 'numeric' })

export const startOfMonth = (d = new Date()) => new Date(d.getFullYear(), d.getMonth(), 1)

/** yyyy-mm-dd in local time, for <input type="date"> */
export const toDateInput = (iso: string) => {
  const d = new Date(iso)
  const p = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
}

/** Keep the original time of day when only the date changes; new dates get the current time. */
export const fromDateInput = (value: string, previousIso?: string) => {
  const [y, m, d] = value.split('-').map(Number)
  const base = previousIso ? new Date(previousIso) : new Date()
  return new Date(y, m - 1, d, base.getHours(), base.getMinutes(), base.getSeconds()).toISOString()
}
