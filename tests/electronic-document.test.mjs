import assert from 'node:assert/strict'
import test from 'node:test'
import { gazetteDemoState } from '../src/features/official-gazette/demoData.ts'
import { buildEditionHtml,editionFileName } from '../src/features/official-gazette/electronicDocument.ts'
test('arquivo eletrônico HTML próprio contém identificação, sumário e texto integral',()=>{const edition=gazetteDemoState.editions[0];const html=buildEditionHtml(edition,gazetteDemoState);assert.match(html,/<!doctype html>/i);assert.match(html,/PREFEITURA MUNICIPAL DE DEODÁPOLIS/);assert.match(html,/SUMÁRIO/);assert.match(html,/proteção das informações do cidadão/);assert.equal(editionFileName(edition),'diario-2026-000001.html')})
test('paginação é determinística: sumário mais uma página por ato',()=>{const edition=gazetteDemoState.editions[0];const html=buildEditionHtml(edition,gazetteDemoState);assert.match(html,/Página 1 de 2/);assert.match(html,/Página 2 de 2/);assert.equal((html.match(/class="page"/g)??[]).length,2)})
