import { useMemo, useState } from 'react'
import {
  evaluateSecurityEnvironment,
  OFFICIAL_POC_ORIGIN,
  securityEvidenceText,
} from './securityEnvironment'

export default function PublicSecurityCheck() {
  const [copied, setCopied] = useState(false)
  const checks = useMemo(
    () =>
      evaluateSecurityEnvironment(
        location.origin,
        location.protocol,
        window.isSecureContext,
        performance.getEntriesByType('resource').map((entry) => entry.name),
      ),
    [],
  )
  const allPassed = checks.every((item) => item.passed)
  const evidence = securityEvidenceText(location.href, checks)

  return (
    <section className="poc-security-check">
      <header>
        <div>
          <span>DIAGNÓSTICO DO AMBIENTE OFICIAL</span>
          <h2>HTTPS e comunicação criptografada</h2>
          <p>
            Ambiente público oficial de produção/demonstração:{' '}
            <a href={OFFICIAL_POC_ORIGIN} target="_blank" rel="noreferrer">
              gov-total.pages.dev
            </a>
            . O navegador não permite que a aplicação inspecione toda a cadeia do certificado.
          </p>
        </div>
        <strong className={allPassed ? 'security-pass' : 'security-fail'}>
          {allPassed ? 'VERIFICAÇÕES AUTOMÁTICAS PASSARAM' : 'REQUER ATENÇÃO'}
        </strong>
      </header>

      {checks.map((item) => (
        <article key={item.id}>
          <b>
            {item.passed ? '✓' : '×'} {item.label}
          </b>
          <span>{item.detail}</span>
        </article>
      ))}

      <button
        onClick={async () => {
          await navigator.clipboard?.writeText(evidence)
          setCopied(true)
        }}
      >
        {copied ? 'Evidência copiada' : 'Copiar evidência técnica'}
      </button>

      <aside>
        Para o 4.1.11, registre manualmente hostname, emissor, validade e ausência de erro de
        certificado. Para o 4.1.30, confirme Console e Network sem conteúdo misto ou comunicação
        HTTP. A comprovação formal ocorre somente na execução da POC; esta tela não promove
        requisitos automaticamente.
      </aside>
    </section>
  )
}
