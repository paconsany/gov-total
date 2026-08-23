import assert from 'node:assert/strict'
import test from 'node:test'
import { deodapolisRequirements } from '../src/features/poc/deodapolisRequirements.ts'

test('matriz Deodápolis possui classificação oficial 45/49/94',()=>{
 assert.equal(deodapolisRequirements.length,94)
 assert.equal(deodapolisRequirements.filter(item=>item.kind==='OBRIGATÓRIO').length,45)
 assert.equal(deodapolisRequirements.filter(item=>item.kind==='COMPLEMENTAR').length,49)
 assert.equal(new Set(deodapolisRequirements.map(item=>item.number)).size,94)
})

test('checkpoint não marca requisito como comprovado',()=>{
 assert.equal(deodapolisRequirements.filter(item=>item.status==='COMPROVADO NA POC').length,0)
 assert.equal(deodapolisRequirements.filter(item=>item.kind==='OBRIGATÓRIO'&&item.status==='PRONTO PARA TESTE').length,33)
 assert.equal(deodapolisRequirements.find(item=>item.number==='4.1.11')?.status,'PRONTO PARA TESTE')
 assert.equal(deodapolisRequirements.find(item=>item.number==='4.1.30')?.status,'PRONTO PARA TESTE')
})

test('distribuição oficial por grupo não mistura obrigatórios e complementares',()=>{
 const expected={
  'Geral / Administração':[4,5],
  'Portal Institucional':[8,16],
  'Diário Oficial':[24,8],
  'Correio Eletrônico':[9,20],
 }
 for(const [group,[required,additional]] of Object.entries(expected)){
  const items=deodapolisRequirements.filter(item=>item.group===group)
  assert.equal(items.filter(item=>item.kind==='OBRIGATÓRIO').length,required,`${group}: obrigatórios`)
  assert.equal(items.filter(item=>item.kind==='COMPLEMENTAR').length,additional,`${group}: complementares`)
 }
 assert.equal(deodapolisRequirements.filter(item=>item.group==='Diário Oficial'&&item.kind==='OBRIGATÓRIO').length,24)
})
