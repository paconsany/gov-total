import { useState } from 'react'
import { defaultGazetteSettings } from './GazetteConfiguration'
import { downloadEditionHtml } from './electronicDocument'
import { downloadPersistentGazetteFile } from './gazetteService'
import { editionActs, editionLabel, groupedSummary } from './rules'
import type { GazetteEdition, GazetteState } from './types'

export default function GazetteEditionView({ edition, state }: { edition: GazetteEdition; state: GazetteState }) {
  const [downloadStatus, setDownloadStatus] = useState('')
  const groups = groupedSummary(edition, state.acts, state.sections)
  const settings = state.settings ?? defaultGazetteSettings
  const acts = editionActs(edition, state.acts)
  const total = acts.length + 1

  const download = async () => {
    if (!edition.electronicFile) {
      downloadEditionHtml(edition, state)
      return
    }
    setDownloadStatus('Baixando arquivo preservado...')
    try {
      const blob = await downloadPersistentGazetteFile(edition.electronicFile)
      const url = URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = edition.electronicFile.originalName
      link.click()
      URL.revokeObjectURL(url)
      setDownloadStatus(`Hash SHA-256 registrado para o arquivo: ${edition.electronicFile.sha256}`)
    } catch (error) {
      setDownloadStatus(error instanceof Error ? error.message : 'Não foi possível baixar o arquivo')
    }
  }

  return (
    <article className="gazette-paper">
      <button className="gazette-electronic-download" onClick={() => void download()}>
        {edition.electronicFile ? 'Baixar arquivo eletrônico preservado' : 'Baixar arquivo eletrônico HTML DEMO'}
      </button>
      {downloadStatus && <p className="gazette-download-status">{downloadStatus}</p>}
      <section className="gazette-page">
        <header>
          <strong className="gazette-demo-logo">{settings.logo}</strong>
          <span>{settings.municipality}</span>
          <h1>{settings.title}</h1>
          <small>{settings.headerText}</small>
          <p>Edição nº {editionLabel(edition)} · {edition.date} · {edition.type}</p>
          {edition.contentHash && <small>Integridade SHA-256: {edition.contentHash}</small>}
        </header>
        <section className="gazette-summary">
          <h2>SUMÁRIO</h2>
          {groups.map((group) => (
            <div key={group.section.id}>
              <h3>{group.section.name}</h3>
              {group.subsections.map((subsection) => (
                <div key={subsection.subsection.id}>
                  <strong>{subsection.subsection.name}</strong>
                  {subsection.acts.map((act) => <p key={act.id}>— {act.type} nº {act.number}/{act.year} · {act.title}</p>)}
                </div>
              ))}
            </div>
          ))}
        </section>
        <footer className="gazette-page-number">{settings.footerText} · Página 1 de {total}</footer>
      </section>
      {acts.map((act, index) => (
        <section className="gazette-page gazette-full-act" key={act.id}>
          <small>{act.department}</small>
          <h2>{act.type} nº {act.number}/{act.year}</h2>
          <h3>{act.title}</h3>
          <p><strong>{act.summary}</strong></p>
          <p>{act.content}</p>
          {act.attachments?.length ? (
            <aside className="gazette-act-attachments">
              <strong>Anexos</strong>
              {act.attachments.map((file) => <a href={file.path} target="_blank" rel="noreferrer" key={file.id}>{file.name} · {file.label}</a>)}
            </aside>
          ) : null}
          <p>Responsável: {act.owner}</p>
          {act.contentHash && <small>Hash do ato: {act.contentHash}</small>}
          <footer className="gazette-page-number">{settings.footerText} · Página {index + 2} de {total}</footer>
        </section>
      ))}
    </article>
  )
}
