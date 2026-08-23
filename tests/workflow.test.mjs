import assert from 'node:assert/strict'
import test from 'node:test'
import { nextProcurementPage, procurementFlow } from '../src/types/process.ts'

test('percorre o planejamento até a aprovação na ordem esperada', () => {
  assert.deepEqual(procurementFlow, [
    'new-purchase', 'dfd', 'etp', 'risks', 'prices', 'tr', 'review', 'approval',
  ])
  for (let index = 0; index < procurementFlow.length - 1; index += 1) {
    assert.equal(nextProcurementPage(procurementFlow[index]), procurementFlow[index + 1])
  }
})

test('preserva o mesmo estado do processo durante a navegação', () => {
  const sharedProcess = {
    demand: { object: 'DEMO — Plataforma digital de atendimento ao cidadão' },
    dfd: { status: 'Pronto para encaminhar' },
  }
  const snapshots = procurementFlow.map((page) => ({ page, process: sharedProcess }))
  assert.ok(snapshots.every((snapshot) => snapshot.process === sharedProcess))
  assert.equal(snapshots.at(-1)?.process.demand.object, sharedProcess.demand.object)
})
