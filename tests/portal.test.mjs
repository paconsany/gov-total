import assert from 'node:assert/strict'
import test from 'node:test'
import { initialPortalState } from '../src/features/portal/demoData.ts'
import { slugify } from '../src/features/portal/types.ts'

test('gera slug permanente sem acentos a partir do título',()=>{
 assert.equal(slugify('Prefeitura amplia o Atendimento Digital — DEMO'),'prefeitura-amplia-o-atendimento-digital-demo')
})

test('portal público recebe apenas notícias publicadas',()=>{
 const published=initialPortalState.news.filter(item=>item.status==='Publicado')
 assert.equal(published.length,2)
 assert.ok(published.every(item=>item.slug&&item.title.includes('DEMO')))
 assert.equal(initialPortalState.news.find(item=>item.status==='Agendado')?.title,'Agenda municipal recebe novos eventos — DEMO')
})
