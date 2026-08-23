import { useState } from 'react'

export type CopilotItem = {
  id: string
  title: string
  reason: string
  probability?: string
  impact?: string
  prevention?: string
}

export default function GovCopilot({ action, context, suggestions, value = '', onChange, items, onAddItem }: {
  action: string
  context: string[]
  suggestions: string[]
  value?: string
  onChange?: (value: string) => void
  items?: CopilotItem[]
  onAddItem?: (item: CopilotItem) => void
}) {
  const [open, setOpen] = useState(false)
  const [attempt, setAttempt] = useState(0)
  const [previous, setPrevious] = useState<string | null>(null)
  const [added, setAdded] = useState<string[]>([])
  const suggestion = suggestions[attempt % suggestions.length]
  const apply = (mode: 'replace' | 'append') => {
    if (!onChange) return
    setPrevious(value)
    onChange(mode === 'replace' || !value.trim() ? suggestion : `${value.trim()}\n\n${suggestion}`)
    setOpen(false)
  }
  return <div className="gov-copilot">
    <button type="button" className="copilot-trigger" onClick={() => setOpen(!open)}><span>✨</span>{action}<small>DEMO</small></button>
    {previous !== null && !open && <button type="button" className="copilot-undo" onClick={() => { onChange?.(previous); setPrevious(null) }}>Desfazer sugestão</button>}
    {open && <div className="copilot-panel">
      <header><div><span>✨</span><div><strong>Copiloto GOV TOTAL</strong><small>Simulação local · nenhuma IA externa</small></div></div><button type="button" onClick={() => setOpen(false)} aria-label="Fechar">×</button></header>
      <section><h4>Contexto utilizado</h4><ul>{context.map((item) => <li key={item}>{item}</li>)}</ul></section>
      {items ? <section><h4>Sugestões para avaliar</h4><div className="copilot-items">{items.map((item) => <article key={item.id}><strong>{item.title}</strong><p>{item.reason}</p><div>{item.probability && <span>Probabilidade: {item.probability}</span>}{item.impact && <span>Impacto: {item.impact}</span>}</div>{item.prevention && <small><b>Prevenção sugerida:</b> {item.prevention}</small>}<button type="button" disabled={added.includes(item.id)} onClick={() => { onAddItem?.(item); setAdded([...added, item.id]) }}>{added.includes(item.id) ? 'Adicionado' : 'Adicionar à matriz'}</button></article>)}</div></section> : <section><h4>Sugestão</h4><div className="copilot-suggestion">{suggestion}</div></section>}
      <p className="copilot-warning">Conteúdo sugerido pelo GOV TOTAL. Revise antes de utilizar.</p>
      <footer>{!items && onChange && <><button type="button" className="primary" onClick={() => apply('replace')}>Usar sugestão</button><button type="button" className="secondary" onClick={() => apply('append')}>Inserir abaixo</button></>}<button type="button" className="secondary" onClick={() => setAttempt(attempt + 1)}>Tentar novamente</button><button type="button" className="copilot-cancel" onClick={() => setOpen(false)}>Cancelar</button></footer>
    </div>}
  </div>
}
