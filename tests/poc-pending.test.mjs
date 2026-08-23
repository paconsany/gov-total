import assert from 'node:assert/strict'
import test from 'node:test'
import { deodapolisRequirements } from '../src/features/poc/deodapolisRequirements.ts'
const pendingIds=['4.1.11','4.1.30','4.3.1','4.3.4','4.3.12','4.3.13','4.3.31']
test('existem exatamente sete obrigatórios pendentes fora do Correio',()=>{const pending=deodapolisRequirements.filter(item=>item.kind==='OBRIGATÓRIO'&&item.group!=='Correio Eletrônico'&&item.status!=='PRONTO PARA TESTE'&&item.status!=='COMPROVADO NA POC');assert.deepEqual(pending.map(item=>item.number),pendingIds)})
test('preparação técnica não promove requisito bloqueado',()=>{for(const id of pendingIds)assert.equal(deodapolisRequirements.find(item=>item.number===id)?.status,'EM DESENVOLVIMENTO');assert.equal(deodapolisRequirements.filter(item=>item.kind==='OBRIGATÓRIO'&&item.status==='PRONTO PARA TESTE').length,29);assert.equal(deodapolisRequirements.filter(item=>item.status==='COMPROVADO NA POC').length,0)})
