import assert from 'node:assert/strict'
import test from 'node:test'
import { initialPortalState } from '../src/features/portal/demoData.ts'
import { contentPath, findBySlug, isSlugUnique, slugify } from '../src/features/portal/types.ts'

test('4.2.18 documento publicado possui página e download local real',async()=>{
 const document=initialPortalState.documents.find(item=>item.status==='Publicado')
 assert.ok(document?.slug)
 assert.equal(contentPath('documentos',document.slug),`/documentos/${document.slug}`)
 const response=await fetch(new URL(document.file,'http://localhost:5173'))
 assert.equal(response.status,200)
 assert.match(await response.text(),/DOCUMENTO DEMONSTRATIVO \/ POC/)
})
test('4.2.19 slug é automático, único e recuperável nos três tipos',()=>{
 assert.equal(slugify('História do Município'),'historia-do-municipio')
 for(const collection of [initialPortalState.news,initialPortalState.pages,initialPortalState.documents]){const current=collection[0];assert.equal(isSlugUnique(collection,current.slug??'',current.id),true);assert.equal(isSlugUnique(collection,current.slug??''),false);assert.equal(findBySlug(collection,current.slug??'')?.id,current.id)}
})
test('4.2.24 ordens configuradas alimentam a home pública',()=>{
 assert.equal(initialPortalState.menuOrder[0],'Início')
 assert.equal(initialPortalState.banners.filter(item=>item.active).sort((a,b)=>a.order-b.order)[0].title,'Atendimento digital — DEMO')
 assert.equal(initialPortalState.news[0].title,'Prefeitura amplia atendimento digital ao cidadão — DEMO')
 assert.equal(initialPortalState.quickLinks.filter(item=>item.active).length,7)
})
