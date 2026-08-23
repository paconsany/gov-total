import assert from 'node:assert/strict'
import test from 'node:test'
import { canSupportFormalProof,isCompleteEvidence,parseEvidence,serializeEvidence } from '../src/features/poc/pocEvidence.ts'
const approved={id:'e-1',requirement:'4.2.12',testedAt:'2026-08-23T12:00:00.000Z',result:'PASSOU',status:'APROVADO',observed:'Fluxo concluído.',evidence:'captura-001.png',note:'',url:'https://poc.example/portal'}
test('evidência exige requisito, data, resultado, decisão, observação e prova textual',()=>{assert.equal(isCompleteEvidence(approved),true);assert.equal(isCompleteEvidence({...approved,evidence:''}),false);assert.equal(isCompleteEvidence({...approved,observed:''}),false)})
test('somente PASSOU e APROVADO sustenta comprovação futura',()=>{assert.equal(canSupportFormalProof(approved),true);assert.equal(canSupportFormalProof({...approved,result:'FALHOU'}),false);assert.equal(canSupportFormalProof({...approved,status:'REPROVADO'}),false)})
test('evidências podem ser persistidas e exportadas sem URL localhost fixa',()=>{assert.deepEqual(parseEvidence(JSON.stringify([approved])),[approved]);const exported=JSON.parse(serializeEvidence([approved]));assert.equal(exported.records[0].url,'https://poc.example/portal');assert.equal(serializeEvidence([approved]).includes('localhost'),false)})
