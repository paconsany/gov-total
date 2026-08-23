import assert from 'node:assert/strict'
import test from 'node:test'
import { evaluateSecurityEnvironment,securityEvidenceText } from '../src/features/poc/securityEnvironment.ts'
test('ambiente HTTPS seguro sem recurso HTTP passa verificações automáticas',()=>{const checks=evaluateSecurityEnvironment('https:',true,['https://poc.example/assets/app.js']);assert.equal(checks.every(item=>item.passed),true);assert.match(securityEvidenceText('https://poc.example',checks),/Verificação manual adicional obrigatória/)})
test('HTTP, contexto inseguro ou mixed content falham explicitamente',()=>{const checks=evaluateSecurityEnvironment('http:',false,['http://poc.example/app.js']);assert.deepEqual(checks.map(item=>item.passed),[false,false,false])})
