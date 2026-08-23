import type { Alternative, EtpData, Requirement } from '../../Etp'
import type { PriceData, PriceItem, PriceReference } from '../../PriceResearch'
import type { RiskItem, RiskMatrixData } from '../../RiskMatrix'
import type { TrData } from '../../TermReference'
import type { DemandData, DfdData, ScopeItem } from '../../types/process'

export const demoDemand: DemandData = {
  title: 'DEMO — Plataforma digital de atendimento ao cidadão',
  object: 'DEMO — Contratação de plataforma digital de atendimento ao cidadão',
  secretariat: 'Administração', sector: 'Atendimento ao Cidadão', owner: 'Mariana Costa — DEMO',
  email: 'demo@municipio.gov.br', phone: '(00) 0000-0000 / Ramal 101', type: 'Contratação de serviços',
  priority: 'Alta', desiredDate: '2026-11-30', estimatedValue: 'R$ 180.000,00',
  need: 'DEMO — Centralizar solicitações, protocolos e acompanhamento dos serviços municipais em um canal digital acessível.',
  problem: 'DEMO — O atendimento está disperso entre telefone, balcão e mensagens, dificultando o acompanhamento pelo cidadão.',
  result: 'DEMO — Reduzir o tempo de resposta e permitir acompanhamento transparente das solicitações.',
  pca: true, pcaItem: 'DEMO · PCA-2026 / Item 042',
}

export const demoDfd: DfdData = {
  justification: 'DEMO — A contratação permitirá padronizar o atendimento e medir prazos e qualidade dos serviços.',
  benefits: 'DEMO — Mais transparência, menor retrabalho e acesso digital simplificado para o cidadão.',
  strategicAlignment: 'DEMO — Programa Município Digital e diretriz de melhoria da experiência do cidadão.',
  budgetAction: 'DEMO — Modernização administrativa', valueSource: 'DEMO — estimativa interna inicial',
  continued: 'Sim', contractTerm: '12 meses', nonContracting: 'DEMO — Manutenção de filas, perda de solicitações e baixa rastreabilidade.',
  drafter: 'Mariana Costa — DEMO', authority: 'Secretaria de Administração — DEMO', status: 'Pronto para encaminhar', pcaYear: '2026',
}

export const demoItems: ScopeItem[] = [
  { id: 1, description: 'DEMO — Licença anual da plataforma de atendimento', quantity: '1', unit: 'serviço', note: 'Inclui implantação e suporte' },
  { id: 2, description: 'DEMO — Capacitação de usuários gestores', quantity: '20', unit: 'usuário', note: 'Turmas remotas ou presenciais' },
]

export const demoEtp: EtpData = {
  recommended: 'DEMO — Contratação de plataforma SaaS',
  solutionDescription: 'DEMO — Solução em nuvem para protocolo, atendimento omnicanal e acompanhamento pelo cidadão.',
  choiceReason: 'DEMO — Menor prazo de implantação e atualização contínua.', rejectionReason: 'DEMO — Desenvolvimento próprio exigiria equipe e prazo incompatíveis.',
  nature: 'Software/SaaS', methodology: 'DEMO — análise comparativa', sources: 'DEMO — referências de mercado', baseDate: '2026-08-20',
  parceling: 'Não', parcelingReason: 'DEMO — A integração dos módulos é essencial.', hasRelated: false,
  results: 'DEMO — Atendimento rastreável e redução do prazo médio.', adminBenefits: 'DEMO — Gestão centralizada e indicadores.',
  citizenBenefits: 'DEMO — Acompanhamento simples e transparente.', environmentalImpact: '', mitigation: '',
  sustainability: 'DEMO — Operação digital reduz uso de papel.', sustainabilityNA: false, viable: 'Sim',
  conclusion: 'DEMO — A contratação SaaS é técnica e economicamente viável diante dos requisitos e do prazo.',
  drafter: 'Paulo Mendes — DEMO', status: 'Concluído',
}

export const demoRequirements: Requirement[] = [
  { id: 1, title: 'DEMO — Acessibilidade', description: 'Atender boas práticas de acessibilidade digital.', type: 'Acessibilidade' },
  { id: 2, title: 'DEMO — Disponibilidade', description: 'Serviço disponível continuamente com SLA mensurável.', type: 'Desempenho' },
]

export const demoAlternatives: Alternative[] = [
  { id: 1, name: 'DEMO — Desenvolvimento próprio', description: '', advantages: '', disadvantages: '', cost: '', viability: 'Parcialmente viável' },
  { id: 2, name: 'DEMO — Contratação SaaS', description: '', advantages: '', disadvantages: '', cost: '', viability: 'Viável' },
  { id: 3, name: 'DEMO — Solução existente no mercado', description: '', advantages: '', disadvantages: '', cost: '', viability: 'Em análise' },
]

export const demoMatrix: RiskMatrixData = { notes: 'DEMO — riscos iniciais revisados pela equipe.', status: 'Concluída' }
export const demoMatrixRisks: RiskItem[] = [{
  id: 1, title: 'DEMO — Atraso na implantação', description: 'Risco de atraso na configuração inicial.', category: 'Execução', phase: 'Implantação',
  probability: 'Média', impact: 'Alto', responsible: 'Gestor do contrato — DEMO', note: '', preventive: 'Cronograma validado e reuniões semanais.',
  contingency: 'Priorização dos serviços essenciais.', actionOwner: 'Gestor do contrato — DEMO', deadline: '2026-11-15', status: 'Monitorado',
}]

export const demoPriceData: PriceData = { methodologyReason: 'DEMO — mediana reduz influência de valores extremos.', finalNotes: 'DEMO — referências comparáveis.', responsible: 'Ana Oliveira — DEMO', status: 'Concluída' }
export const demoPriceItems: PriceItem[] = demoItems.map((item) => ({ ...item, currentEstimate: item.id === 1 ? '175000' : '250', method: 'Mediana', customValue: '' }))
export const demoPriceReferences: PriceReference[] = [1, 2, 3].flatMap((ref) => demoItems.map((item) => ({
  id: ref * 10 + item.id, itemId: item.id, source: `DEMO — Referência ${ref}`, sourceType: 'Fornecedor', provider: `Fornecedor ${ref} — DEMO`,
  cnpj: '', description: item.description, quantity: item.quantity, unitValue: item.id === 1 ? String(168000 + ref * 7000) : String(220 + ref * 30),
  date: '2026-08-15', identifier: `DEMO-REF-${ref}`, note: 'Referência exclusivamente demonstrativa.', consider: true, reason: '', justification: '',
})))

export const demoTr: TrData = {
  startDeadline: 'Até 10 dias após a ordem de serviço', deliveryDeadline: 'Implantação em até 60 dias', executionPlace: 'Município — ambiente digital', restrictions: '',
  supplierDuties: 'DEMO — Implantar, capacitar e prestar suporte.', administrationDuties: 'DEMO — Disponibilizar equipe e informações.', hasSla: true,
  managementUnit: 'Administração', contractManager: 'Gestor DEMO', technicalInspector: 'Fiscal técnico DEMO', administrativeInspector: 'Fiscal administrativo DEMO',
  monitoring: 'DEMO — Reuniões, relatórios mensais e painel de indicadores.', evidence: 'Relatórios e registros da plataforma', inspectionFrequency: 'Mensal',
  measurement: 'DEMO — Disponibilidade e chamados atendidos.', acceptance: 'DEMO — Homologação funcional e atendimento aos requisitos.', paymentFrequency: 'Mensal',
  paymentDeadline: '30 dias', requiredDocuments: 'Nota fiscal e relatório mensal', paymentType: 'Mensal', judgment: 'Menor preço', contractingMethod: 'Pregão eletrônico',
  minimumQualification: 'DEMO — Regularidade fiscal e jurídica.', technicalQualification: 'DEMO — Experiência compatível.', certificates: '', responsibleSectorDefines: false,
  budget: 'R$ 180.000,00', fundingSource: 'Recursos próprios — DEMO', budgetProgram: 'Modernização administrativa — DEMO', budgetUndefined: false,
  drafter: 'Carlos Souza — DEMO', department: 'Compras Públicas', finalNotes: 'DEMO — Documento preparado para validação visual.', status: 'Concluído',
}
