import { useState } from 'react'
import type { ReviewIssue, ReviewStage } from '../../SmartReview'
import type { Page } from '../../types/process'

type StageSummary = { label: string; status: string; responsible: string; updated: string; alerts: number; page: Page }
type Decision = 'Aprovar' | 'Solicitar ajustes' | 'Rejeitar' | 'Em análise'

export default function Approval({ stages, issues, onNavigate }: { stages: StageSummary[]; issues: ReviewIssue[]; onNavigate: (page: Page) => void }) {
  const [decision, setDecision] = useState<Decision>('Em análise')
  const [note, setNote] = useState('')
  const [responsible, setResponsible] = useState('Secretário responsável — DEMO')
  const critical = issues.filter((item) => item.severity === 'Crítico')
  const attention = issues.filter((item) => item.severity !== 'Informação')
  const checklist = [
    ...stages.slice(0, 6).map((stage) => ({ label: `${stage.label} concluíd${stage.label === 'Pesquisa de Preços' ? 'a' : 'o'}`, done: /Concluíd|Pront/.test(stage.status) })),
    { label: 'Revisão Inteligente executada', done: true },
    { label: 'Nenhum apontamento crítico pendente', done: critical.length === 0 },
  ]
  const targetPage = (target: ReviewStage) => target as Page

  return <>
    <header className="topbar"><div><span className="eyebrow">ETAPA 7 DE 7 · COMPRAS PÚBLICAS</span><h1>Revisão e Aprovação</h1><p>Revise o planejamento da contratação antes do encaminhamento final.</p></div></header>
    <div className="approval-notice"><strong>Fluxo demonstrativo</strong><span>Esta etapa representa o fluxo de aprovação. Assinaturas e registros oficiais serão implementados posteriormente.</span></div>
    <section className="panel approval-stages"><div className="panel-head"><div><h2>Resumo do planejamento</h2><p>Abra uma etapa para conferir seu conteúdo antes da decisão.</p></div></div>
      <div className="approval-stage-list">{stages.map((stage) => <article key={stage.label}>
        <div className="approval-stage-icon">✓</div><div className="approval-stage-main"><strong>{stage.label}</strong><span>{stage.responsible}</span></div>
        <div><small>Status</small><b>{stage.status}</b></div><div><small>Última atualização</small><b>{stage.updated}</b></div>
        <div><small>Alertas pendentes</small><b className={stage.alerts ? 'attention-count' : ''}>{stage.alerts}</b></div>
        <button className="secondary" onClick={() => onNavigate(stage.page)}>Revisar etapa</button>
      </article>)}</div>
    </section>
    <div className="approval-grid">
      <section className="panel final-checklist"><div className="panel-head"><div><h2>Checklist final</h2><p>Condições mínimas para o encaminhamento.</p></div></div>{checklist.map((item) => <div className={item.done ? 'check-done' : 'check-pending'} key={item.label}><span>{item.done ? '✓' : '!'}</span><strong>{item.label}</strong></div>)}</section>
      <section className="panel attention-points"><div className="panel-head"><div><h2>Pontos que exigem atenção</h2><p>Apontamentos existentes na Revisão Inteligente.</p></div><button onClick={() => onNavigate('review')}>Ver revisão completa</button></div>
        {attention.length === 0 ? <div className="empty-inline">Nenhum ponto pendente.</div> : attention.slice(0, 4).map((item) => <article key={item.id}><span>{item.severity}</span><div><strong>{item.stage}</strong><p>{item.description}</p></div><button onClick={() => onNavigate(targetPage(item.target))}>Corrigir</button></article>)}
      </section>
    </div>
    <section className="panel approval-opinion"><div className="panel-head"><div><h2>Parecer do responsável</h2><p>Registro visual para validação do fluxo. Não constitui ato jurídico.</p></div></div><div className="form-grid">
      <label className="field"><span>Decisão</span><select value={decision} onChange={(event) => setDecision(event.target.value as Decision)}>{['Aprovar', 'Solicitar ajustes', 'Rejeitar', 'Em análise'].map((value) => <option key={value}>{value}</option>)}</select></label>
      <label className="field"><span>Responsável</span><input value={responsible} onChange={(event) => setResponsible(event.target.value)} /></label>
      <label className="field"><span>Data</span><input type="date" value="2026-08-23" readOnly /></label>
      <label className="field wide"><span>Observação</span><textarea rows={4} value={note} onChange={(event) => setNote(event.target.value)} placeholder="Registre orientações ou ajustes necessários..." /></label>
    </div><div className="form-actions"><button className="secondary" onClick={() => onNavigate('tr')}>Voltar para o TR</button><button className="primary" type="button">Salvar parecer DEMO</button></div></section>
  </>
}
