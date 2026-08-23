import { useCallback, useEffect, useState } from 'react'
import GazetteEditionView from './GazetteEditionView'
import { gazetteBackendConfiguration, loadPersistentGazetteArchive } from './gazetteService'
import { editionLabel, editionPath, emptyFilters, filterEditions } from './rules'
import type { GazetteEdition, GazetteFilters, GazetteState } from './types'

type PersistenceStatus = 'loading' | 'connected' | 'unconfigured' | 'error'

export default function GazettePublicArchive({ state, onBack }: { state: GazetteState; onBack: () => void }) {
  const [archive, setArchive] = useState(state)
  const [persistence, setPersistence] = useState<PersistenceStatus>('loading')
  const [persistenceDetail, setPersistenceDetail] = useState('Consultando o acervo persistente...')
  const [filters, setFilters] = useState<GazetteFilters>(emptyFilters)
  const [selected, setSelected] = useState<GazetteEdition | null>(null)

  const loadArchive = useCallback(async () => {
    const configuration = gazetteBackendConfiguration()
    if (!configuration.configured) {
      setArchive(state)
      setPersistence('unconfigured')
      setPersistenceDetail(`Configuração pendente: ${configuration.missing.join(', ')}`)
      return
    }
    setPersistence('loading')
    setPersistenceDetail('Consultando o Supabase...')
    try {
      const persisted = await loadPersistentGazetteArchive()
      setArchive(persisted)
      setPersistence('connected')
      setPersistenceDetail(`${persisted.editions.length} edição(ões) carregada(s) do banco`)
    } catch (error) {
      setArchive(state)
      setPersistence('error')
      setPersistenceDetail(error instanceof Error ? error.message : 'Falha ao consultar o acervo')
    }
  }, [state])

  useEffect(() => {
    void loadArchive()
  }, [loadArchive])

  useEffect(() => {
    const [, root, year, number] = location.pathname.split('/')
    if (root !== 'diario') return
    setSelected(
      archive.editions.find(
        (item) => item.year === Number(year) && item.number === Number(number) && item.status === 'PUBLICADA',
      ) ?? null,
    )
  }, [archive])

  const update = (key: keyof GazetteFilters, value: string) => setFilters({ ...filters, [key]: value })
  const open = (edition: GazetteEdition) => {
    setSelected(edition)
    history.pushState({}, '', editionPath(edition))
    scrollTo({ top: 0 })
  }

  if (selected) {
    return (
      <section className="gazette-public">
        <div className="gazette-public-actions">
          <button
            onClick={() => {
              setSelected(null)
              history.pushState({}, '', '/')
            }}
          >
            ← Voltar ao acervo
          </button>
          <button onClick={() => window.print()}>Imprimir / salvar pelo navegador</button>
          <button onClick={() => navigator.clipboard?.writeText(`${location.origin}${editionPath(selected)}`)}>
            Copiar link
          </button>
        </div>
        <GazetteEditionView edition={selected} state={archive} />
      </section>
    )
  }

  const result = filterEditions(archive.editions, archive.acts, filters)
  const persistent = persistence === 'connected'

  return (
    <section className="gazette-public">
      <header className="gazette-public-title">
        <button onClick={onBack}>← Voltar ao Portal</button>
        <span>CONSULTA PÚBLICA · POC</span>
        <h1>Diário Oficial</h1>
        <p>Consulte edições publicadas e o conteúdo integral dos atos.</p>
      </header>

      <aside className={`gazette-persistence-status ${persistent ? 'connected' : 'demo'}`}>
        <div>
          <strong>{persistent ? 'ACERVO PERSISTENTE · SUPABASE' : 'ACERVO DEMO LOCAL · NÃO PERSISTENTE'}</strong>
          <span>{persistenceDetail}</span>
          {!persistent && (
            <small>Este conteúdo local não comprova os requisitos 4.3.1 e 4.3.12.</small>
          )}
        </div>
        <button disabled={persistence === 'loading'} onClick={() => void loadArchive()}>
          {persistence === 'loading' ? 'Consultando...' : 'Recarregar acervo'}
        </button>
      </aside>

      <div className="gazette-filters">
        <label>
          Palavra-chave
          <input value={filters.keyword} onChange={(event) => update('keyword', event.target.value)} placeholder="Busca no texto integral" />
        </label>
        <label>
          Número da edição
          <input value={filters.number} onChange={(event) => update('number', event.target.value)} placeholder="000001/2026" />
        </label>
        <label>
          Data
          <input type="date" value={filters.date} onChange={(event) => update('date', event.target.value)} />
        </label>
        <label>
          De
          <input type="date" value={filters.from} onChange={(event) => update('from', event.target.value)} />
        </label>
        <label>
          Até
          <input type="date" value={filters.to} onChange={(event) => update('to', event.target.value)} />
        </label>
        <label>
          Seção
          <select value={filters.sectionId} onChange={(event) => update('sectionId', event.target.value)}>
            <option value="">Todas</option>
            {archive.sections.map((item) => <option value={item.id} key={item.id}>{item.name}</option>)}
          </select>
        </label>
        <label>
          Subseção
          <select value={filters.subsectionId} onChange={(event) => update('subsectionId', event.target.value)}>
            <option value="">Todas</option>
            {archive.sections.flatMap((item) => item.subsections).map((item) => <option value={item.id} key={item.id}>{item.name}</option>)}
          </select>
        </label>
        <label>
          Órgão/Secretaria
          <input value={filters.department} onChange={(event) => update('department', event.target.value)} placeholder="Secretaria" />
        </label>
        <label>
          Tipo do ato
          <select value={filters.actType} onChange={(event) => update('actType', event.target.value)}>
            <option value="">Todos</option>
            {['Decreto', 'Portaria', 'Lei', 'Resolução', 'Aviso de Licitação', 'Extrato de Contrato', 'Homologação', 'Outros'].map((item) => <option key={item}>{item}</option>)}
          </select>
        </label>
        <button onClick={() => setFilters(emptyFilters)}>Limpar filtros</button>
      </div>

      <p className="gazette-result-count">{result.length} edição(ões) encontrada(s).</p>
      <div className="gazette-archive-list">
        {result.map((edition) => (
          <article key={edition.id}>
            <div>
              <span>{edition.type}</span>
              <h2>Edição nº {editionLabel(edition)}</h2>
              <p>{edition.date} · {edition.actIds.length} ato(s) · PUBLICADA</p>
              <code>{editionPath(edition)}</code>
              {edition.contentHash && <small>SHA-256: {edition.contentHash}</small>}
            </div>
            <button onClick={() => open(edition)}>Abrir edição</button>
          </article>
        ))}
        {!result.length && <p>Nenhuma edição publicada corresponde aos filtros.</p>}
      </div>
    </section>
  )
}
