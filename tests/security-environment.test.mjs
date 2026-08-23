import assert from 'node:assert/strict'
import test from 'node:test'
import {
  evaluateSecurityEnvironment,
  OFFICIAL_POC_ORIGIN,
  securityEvidenceText,
} from '../src/features/poc/securityEnvironment.ts'

test('ambiente oficial HTTPS seguro sem recurso HTTP passa verificações automáticas', () => {
  const checks = evaluateSecurityEnvironment(OFFICIAL_POC_ORIGIN, 'https:', true, [
    'https://gov-total.pages.dev/assets/app.js',
  ])

  assert.equal(OFFICIAL_POC_ORIGIN, 'https://gov-total.pages.dev')
  assert.equal(checks.every((item) => item.passed), true)
  assert.match(
    securityEvidenceText(`${OFFICIAL_POC_ORIGIN}/`, checks),
    /comprovação formal ocorre somente durante a execução da POC/,
  )
})

test('origem não oficial, HTTP, contexto inseguro e mixed content falham explicitamente', () => {
  const checks = evaluateSecurityEnvironment('http://localhost:5173', 'http:', false, [
    'http://localhost:5173/app.js',
  ])

  assert.deepEqual(checks.map((item) => item.passed), [false, false, false, false, false])
})

test('domínio parecido não é reconhecido como ambiente oficial', () => {
  const checks = evaluateSecurityEnvironment('https://gov-total.pages.dev.example', 'https:', true, [])
  assert.equal(checks.find((item) => item.id === 'official-origin')?.passed, false)
})
