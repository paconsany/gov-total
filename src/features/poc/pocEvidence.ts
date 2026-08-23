export type PocEvidenceStatus='APROVADO'|'REPROVADO'
export type PocTestResult='PASSOU'|'FALHOU'
export type PocEvidence={id:string;requirement:string;testedAt:string;result:PocTestResult;status:PocEvidenceStatus;observed:string;evidence:string;note:string;url:string}
export const evidenceStorageKey='gov-total:deodapolis:poc-evidence:v1'
export const isCompleteEvidence=(item:Partial<PocEvidence>)=>Boolean(item.requirement&&item.testedAt&&item.result&&item.status&&item.observed?.trim()&&item.evidence?.trim())
export const canSupportFormalProof=(item:PocEvidence)=>isCompleteEvidence(item)&&item.result==='PASSOU'&&item.status==='APROVADO'
export const parseEvidence=(value:string|null):PocEvidence[]=>{if(!value)return[];try{const parsed=JSON.parse(value);return Array.isArray(parsed)?parsed.filter(isCompleteEvidence):[]}catch{return[]}}
export const serializeEvidence=(items:PocEvidence[])=>JSON.stringify({project:'GOV TOTAL',poc:'Deodápolis/MS',exportedAt:new Date().toISOString(),records:items},null,2)
