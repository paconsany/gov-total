export type SecurityCheck = {
  id: string
  label: string
  passed: boolean
  detail: string
}

export const OFFICIAL_POC_ORIGIN = 'https://gov-total.pages.dev'

export const evaluateSecurityEnvironment = (
  origin: string,
  protocol: string,
  secureContext: boolean,
  resourceUrls: string[],
): SecurityCheck[] => {
  const insecureResources = resourceUrls.filter((url) => url.startsWith('http://'))
  const officialEnvironment = origin === OFFICIAL_POC_ORIGIN

  return [
    {
      id: 'official-origin',
      label: 'Ambiente oficial da POC',
      passed: officialEnvironment,
      detail: officialEnvironment
        ? `${OFFICIAL_POC_ORIGIN} reconhecido como produção/demonstração`
        : `Origem atual: ${origin || 'não identificada'}`,
    },
    {
      id: 'https',
      label: 'Página carregada por HTTPS',
      passed: protocol === 'https:',
      detail: protocol,
    },
    {
      id: 'secure-context',
      label: 'Contexto seguro do navegador',
      passed: secureContext,
      detail: secureContext ? 'window.isSecureContext = true' : 'window.isSecureContext = false',
    },
    {
      id: 'http-resources',
      label: 'Nenhum recurso HTTP observado',
      passed: insecureResources.length === 0,
      detail: insecureResources.length
        ? insecureResources.join(', ')
        : `${resourceUrls.length} recursos inspecionados; nenhum recurso HTTP observado`,
    },
    {
      id: 'mixed-content',
      label: 'Nenhum indício de conteúdo misto nos recursos observáveis',
      passed: protocol === 'https:' && insecureResources.length === 0,
      detail:
        protocol === 'https:' && insecureResources.length === 0
          ? 'Página HTTPS sem recurso HTTP identificado pela aplicação'
          : 'Requer inspeção manual do Console e da aba Network',
    },
  ]
}

export const securityEvidenceText = (url: string, checks: SecurityCheck[]) =>
  [
    `Ambiente oficial: ${OFFICIAL_POC_ORIGIN}`,
    `URL inspecionada: ${url}`,
    `Data/hora: ${new Date().toISOString()}`,
    ...checks.map(
      (item) => `${item.passed ? 'PASSOU' : 'FALHOU'} — ${item.label}: ${item.detail}`,
    ),
    'Verificação manual adicional obrigatória para 4.1.11: hostname, emissor, validade e ausência de erro de certificado.',
    'Verificação manual adicional obrigatória para 4.1.30: Console e Network sem mixed content ou comunicação HTTP.',
    'A comprovação formal ocorre somente durante a execução da POC e o registro da evidência.',
  ].join('\n')
