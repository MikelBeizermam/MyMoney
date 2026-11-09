import { CLASSIFIER_RULES } from './classifierRules'
import { CATEGORIES, type CategoryKey } from './types'

/** Same algorithm as the iOS CategoryClassifier: first rule whose keyword appears in the name wins. */
export function classifyMerchant(merchant: string): CategoryKey {
  const lower = merchant.toLowerCase()
  for (const [category, keywords] of CLASSIFIER_RULES) {
    if (keywords.some((k) => lower.includes(k.toLowerCase()))) return category
  }
  return 'other'
}

export function classifyToLabel(merchant: string): string {
  const key = classifyMerchant(merchant)
  return CATEGORIES.find((c) => c.key === key)!.label
}
