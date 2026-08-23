import type { Page } from '../../types/process'
import GovCopilot from '../../components/GovCopilot'

export type OverviewStage = { label: string; summary: string; status: string; page: Page }

export default function ProcessOverview({ data, stages, currentPage, onNavigate }: {
  data: { object: string; secretariat: string; owner: string; status: string; value: string; desiredDate: string }
  stages: OverviewStage[]
  currentPage: Page
  onNavigate: (page: Page) => void
}) {
  return <>
    <header className="topbar"><div><span className="eyebrow">PROCESSO DEMO · VISÃO EXECUTIVA</span><h1>Visão Geral do Processo</h1><p>Entenda a contratação inteira em menos de 30 segundos.</p></div><button className="primary" onClick={() => onNavigate(currentPage)}>Continuar de onde parei</button></header>
    <div className="demo-banner"><strong>DEMO</strong><span>Todos os dados desta contratação são fictícios e destinados exclusivamente à demonstração do GOV TOTAL.</span></div>
    <section className="panel overview-copilot"><div><span>✨</span><div><small>COPILOTO GOV TOTAL · DEMO</small><h2>Processo pronto para revisão assistida</h2><p>A análise permanece sob responsabilidade do servidor.</p></div></div><ul><li><b>2</b> textos podem ser melhorados</li><li><b>1</b> risco merece revisão</li><li>TR possui seção sem detalhamento suficiente</li></ul><GovCopilot action="Ver orientação do Copiloto" context={['Textos do planejamento','Riscos registrados','Seções do Termo de Referência']} suggestions={['DEMO — Priorize a revisão da conclusão do ETP, do tratamento do risco de indisponibilidade e do detalhamento dos critérios de aceite no TR.']}/></section>
    <section className="panel overview-identity"><div><small>Número</small><strong>Rascunho DEMO</strong></div><div className="overview-object"><small>Objeto</small><strong>{data.object}</strong></div><div><small>Secretaria</small><strong>{data.secretariat}</strong></div><div><small>Responsável</small><strong>{data.owner}</strong></div><div><small>Etapa atual</small><strong>Aprovação</strong></div><div><small>Status</small><strong>{data.status}</strong></div><div><small>Valor estimado</small><strong>{data.value}</strong></div><div><small>Data desejada</small><strong>{data.desiredDate}</strong></div></section>
    <section className="panel process-timeline"><div className="panel-head"><div><h2>Linha do tempo</h2><p>Resumo das decisões construídas ao longo do planejamento.</p></div></div><div className="timeline-flow">{stages.map((stage, index) => <article key={stage.label}>
      <button onClick={() => onNavigate(stage.page)}><span>{index + 1}</span><div><strong>{stage.label}</strong><small>{stage.status}</small></div></button><p>{stage.summary}</p>{index < stages.length - 1 && <i>→</i>}
    </article>)}</div></section>
    <div className="overview-actions"><button className="secondary" onClick={() => onNavigate('purchases')}>Voltar para Compras Públicas</button><button className="primary" onClick={() => onNavigate(currentPage)}>Continuar de onde parei</button></div>
  </>
}
