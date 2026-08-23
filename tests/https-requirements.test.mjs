import assert from 'node:assert/strict'
import test from 'node:test'
import { deodapolisRequirements } from '../src/features/poc/deodapolisRequirements.ts'
test('4.1.11 e 4.1.30 usam ambiente público e possuem roteiro formal',()=>{for(const id of ['4.1.11','4.1.30']){const item=deodapolisRequirements.find(requirement=>requirement.number===id);assert.equal(item?.status,'PRONTO PARA TESTE');assert.match(item?.note??'',/https:\/\/gov-total\.pages\.dev/);assert.ok((item?.steps.length??0)>=4);assert.equal(item?.status==='COMPROVADO NA POC',false)}})
