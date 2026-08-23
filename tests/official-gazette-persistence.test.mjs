import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../supabase/migrations/20260823075524_official_gazette_persistence.sql', import.meta.url),
  'utf8',
)
const service = readFileSync(
  new URL('../src/features/official-gazette/gazetteService.ts', import.meta.url),
  'utf8',
)
const client = readFileSync(new URL('../src/lib/supabaseRest.ts', import.meta.url), 'utf8')
const publicPortal = readFileSync(new URL('../src/features/portal/PortalPublic.tsx', import.meta.url), 'utf8')

test('migration cria acervo, atos, vínculo de edição, arquivos e auditoria', () => {
  for (const table of [
    'official_gazette_editions',
    'official_gazette_acts',
    'official_gazette_edition_acts',
    'official_gazette_files',
  ]) {
    assert.match(migration, new RegExp(`create table public\\.${table}`))
    assert.match(migration, new RegExp(`alter table public\\.${table} force row level security`))
    assert.match(migration, new RegExp(`create trigger ${table}.*_audit`, 's'))
  }
})

test('publicação é RPC autenticada e registros publicados são imutáveis', () => {
  assert.match(migration, /create or replace function public\.publish_official_gazette/)
  assert.match(migration, /missing gazette\.publish permission/)
  assert.match(migration, /published Official Gazette records are immutable/)
  assert.match(migration, /revoke all on function public\.publish_official_gazette\(uuid\) from public, anon/)
  assert.doesNotMatch(migration, /grant execute on function public\.publish_official_gazette\(uuid\) to anon/)
})

test('leitura pública exige publicação e Storage permanece privado', () => {
  assert.match(migration, /status in \('published', 'revoked'\)/)
  assert.match(migration, /values \('official-gazette', 'official-gazette', false\)/)
  assert.match(migration, /official_gazette_storage_public_download/)
  assert.doesNotMatch(migration, /values \('official-gazette', 'official-gazette', true\)/)
})

test('frontend usa somente configuração pública e não contém service role', () => {
  assert.match(client, /VITE_SUPABASE_URL/)
  assert.match(client, /VITE_SUPABASE_PUBLISHABLE_KEY/)
  assert.match(service, /loadPersistentGazetteArchive/)
  assert.match(service, /stageGazetteFile/)
  assert.match(service, /VITE_GOV_TOTAL_ORGANIZATION_ID/)
  assert.match(service, /organization_id: `eq\.\$\{configuration\.organizationId\}`/)
  assert.doesNotMatch(`${client}\n${service}`, /service.role|service_role/i)
  assert.doesNotMatch(service, /localStorage/)
})

test('URL permanente do Diário abre diretamente o acervo', () => {
  assert.match(publicPortal, /location\.pathname\.startsWith\('\/diario\/'\)\?'gazette':'home'/)
})
