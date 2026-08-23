export type Page =
  | 'home'
  | 'purchases'
  | 'demo'
  | 'portal'
  | 'poc'
  | 'overview'
  | 'new-purchase'
  | 'dfd'
  | 'etp'
  | 'risks'
  | 'prices'
  | 'tr'
  | 'approval'
  | 'review'

export type DemandData = {
  title: string
  object: string
  secretariat: string
  sector: string
  owner: string
  email: string
  phone: string
  type: string
  priority: string
  desiredDate: string
  estimatedValue: string
  need: string
  problem: string
  result: string
  pca: boolean
  pcaItem: string
}

export type DfdData = {
  justification: string
  benefits: string
  strategicAlignment: string
  budgetAction: string
  valueSource: string
  continued: string
  contractTerm: string
  nonContracting: string
  drafter: string
  authority: string
  status: string
  pcaYear: string
}

export type ScopeItem = { id: number; description: string; quantity: string; unit: string; note: string }
export type InitialRisk = { id: number; risk: string; impact: string; note: string }

export const procurementFlow: Page[] = [
  'new-purchase', 'dfd', 'etp', 'risks', 'prices', 'tr', 'review', 'approval',
]

export function nextProcurementPage(page: Page): Page | undefined {
  const index = procurementFlow.indexOf(page)
  return index >= 0 ? procurementFlow[index + 1] : undefined
}
