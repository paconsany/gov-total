import {
  getPublicSupabaseConfiguration,
  supabaseRequest,
  type PublicSupabaseConfig,
} from '../../lib/supabaseRest'
import type {
  GazetteEdition,
  GazetteElectronicFile,
  GazetteSection,
  GazetteState,
  OfficialAct,
} from './types'

type PersistedFile = {
  id: string
  bucket_id: string
  object_path: string
  original_name: string
  mime_type: string
  size_bytes: number
  sha256: string
}

type PersistedAct = {
  id: string
  act_type: string
  act_number: string
  act_year: number
  issued_on: string
  department_name: string
  section_name: string
  subsection_name: string
  title: string
  summary: string
  content: string
  content_hash: string
  published_at: string
  created_at: string
  created_by: string | null
  approved_at: string | null
  approved_by: string | null
}

type PersistedEditionAct = {
  position: number
  official_gazette_acts: PersistedAct | null
}

type PersistedEdition = {
  id: string
  edition_number: number
  edition_year: number
  edition_type: 'ordinary' | 'extraordinary'
  publication_date: string
  public_slug: string
  status: 'published' | 'revoked'
  content_hash: string
  published_at: string
  published_by: string
  official_gazette_edition_acts: PersistedEditionAct[]
  official_gazette_files: PersistedFile[]
}

const resourceSelect = [
  'id,edition_number,edition_year,edition_type,publication_date,public_slug,status,content_hash,published_at,published_by',
  'official_gazette_edition_acts(position,official_gazette_acts(id,act_type,act_number,act_year,issued_on,department_name,section_name,subsection_name,title,summary,content,content_hash,published_at,created_at,created_by,approved_at,approved_by))',
  'official_gazette_files(id,bucket_id,object_path,original_name,mime_type,size_bytes,sha256)',
].join(',')

const stableId = (prefix: string, value: string) =>
  `${prefix}-${value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '')}`

function mapArchive(rows: PersistedEdition[]): GazetteState {
  const actsById = new Map<string, OfficialAct>()
  const sectionMap = new Map<string, GazetteSection>()

  for (const row of rows) {
    for (const link of row.official_gazette_edition_acts.sort((a, b) => a.position - b.position)) {
      const act = link.official_gazette_acts
      if (!act) continue
      const sectionId = stableId('section', act.section_name)
      const subsectionId = stableId('subsection', `${act.section_name}-${act.subsection_name}`)
      const section = sectionMap.get(sectionId) ?? {
        id: sectionId,
        name: act.section_name,
        active: true,
        order: sectionMap.size + 1,
        subsections: [],
      }
      if (!section.subsections.some((item) => item.id === subsectionId)) {
        section.subsections.push({
          id: subsectionId,
          name: act.subsection_name,
          active: true,
          order: section.subsections.length + 1,
        })
      }
      sectionMap.set(sectionId, section)
      actsById.set(act.id, {
        id: act.id,
        type: act.act_type,
        number: act.act_number,
        year: act.act_year,
        date: act.issued_on,
        department: act.department_name,
        sectionId,
        subsectionId,
        title: act.title,
        summary: act.summary,
        content: act.content,
        owner: act.created_by ?? 'Responsável registrado no banco',
        status: 'PUBLICADO',
        createdAt: act.created_at,
        createdBy: act.created_by ?? 'Usuário registrado no banco',
        approvedAt: act.approved_at ?? undefined,
        approvedBy: act.approved_by ?? undefined,
        events: [{ action: 'PUBLICADO', user: act.approved_by ?? 'Publicador registrado', at: act.published_at }],
        contentHash: act.content_hash,
        persistence: 'SUPABASE',
      })
    }
  }

  const editions: GazetteEdition[] = rows.map((row) => {
    const file = row.official_gazette_files[0]
    const electronicFile: GazetteElectronicFile | undefined = file
      ? {
          id: file.id,
          bucketId: file.bucket_id,
          objectPath: file.object_path,
          originalName: file.original_name,
          mimeType: file.mime_type,
          sizeBytes: file.size_bytes,
          sha256: file.sha256,
        }
      : undefined
    return {
      id: row.id,
      number: row.edition_number,
      year: row.edition_year,
      type: row.edition_type === 'ordinary' ? 'ORDINÁRIA' : 'EXTRAORDINÁRIA',
      date: row.publication_date,
      status: 'PUBLICADA',
      actIds: row.official_gazette_edition_acts
        .sort((a, b) => a.position - b.position)
        .flatMap((item) => (item.official_gazette_acts ? [item.official_gazette_acts.id] : [])),
      publishedAt: row.published_at,
      publishedBy: row.published_by,
      events: [{ action: row.status === 'revoked' ? 'REVOGAÇÃO REGISTRADA' : 'PUBLICADO', user: row.published_by, at: row.published_at }],
      contentHash: row.content_hash,
      publicSlug: row.public_slug,
      electronicFile,
      persistence: 'SUPABASE',
    }
  })

  return { sections: [...sectionMap.values()], acts: [...actsById.values()], editions }
}

export function gazetteBackendConfiguration() {
  const configuration = getPublicSupabaseConfiguration()
  const organizationId = (import.meta.env.VITE_GOV_TOTAL_ORGANIZATION_ID ?? '').trim()
  if (!configuration.configured) return configuration
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(organizationId)) {
    return { configured: false as const, missing: ['VITE_GOV_TOTAL_ORGANIZATION_ID'] }
  }
  return { configured: true as const, config: configuration.config, organizationId }
}

export async function loadPersistentGazetteArchive(): Promise<GazetteState> {
  const configuration = gazetteBackendConfiguration()
  if (!configuration.configured) {
    throw new Error(`Supabase não configurado: ${configuration.missing.join(', ')}`)
  }
  const query = new URLSearchParams({
    select: resourceSelect,
    organization_id: `eq.${configuration.organizationId}`,
    status: 'in.(published,revoked)',
    order: 'publication_date.desc,edition_year.desc,edition_number.desc',
  })
  const rows = await supabaseRequest<PersistedEdition[]>(
    configuration.config,
    `/rest/v1/official_gazette_editions?${query}`,
  )
  return mapArchive(rows)
}

export async function downloadPersistentGazetteFile(file: GazetteElectronicFile): Promise<Blob> {
  const configuration = getPublicSupabaseConfiguration()
  if (!configuration.configured) throw new Error('Supabase público não configurado')
  const path = file.objectPath.split('/').map(encodeURIComponent).join('/')
  const response = await fetch(
    `${configuration.config.url}/storage/v1/object/${encodeURIComponent(file.bucketId)}/${path}`,
    {
      headers: {
        apikey: configuration.config.publishableKey,
        Authorization: `Bearer ${configuration.config.publishableKey}`,
      },
    },
  )
  if (!response.ok) throw new Error(`Falha ao baixar arquivo persistente (${response.status})`)
  return response.blob()
}

export async function stageGazetteFile(
  config: PublicSupabaseConfig,
  accessToken: string,
  organizationId: string,
  editionId: string,
  file: File,
) {
  if (!accessToken) throw new Error('Sessão administrativa obrigatória')
  const digest = await crypto.subtle.digest('SHA-256', await file.arrayBuffer())
  const sha256 = [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, '0')).join('')
  const fileId = crypto.randomUUID()
  const safeName = file.name.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-zA-Z0-9._-]+/g, '-')
  const objectPath = `${organizationId}/${editionId}/${fileId}-${safeName}`
  const metadata = {
    id: fileId,
    organization_id: organizationId,
    edition_id: editionId,
    bucket_id: 'official-gazette',
    object_path: objectPath,
    original_name: file.name,
    mime_type: file.type || 'application/octet-stream',
    size_bytes: file.size,
    sha256,
  }

  await supabaseRequest(config, '/rest/v1/official_gazette_files', {
    method: 'POST',
    headers: { Prefer: 'return=minimal' },
    body: JSON.stringify(metadata),
  }, accessToken)

  try {
    const uploadResponse = await fetch(
      `${config.url}/storage/v1/object/official-gazette/${objectPath.split('/').map(encodeURIComponent).join('/')}`,
      {
        method: 'POST',
        headers: {
          apikey: config.publishableKey,
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': metadata.mime_type,
          'x-upsert': 'false',
        },
        body: file,
      },
    )
    if (!uploadResponse.ok) throw new Error(await uploadResponse.text())
    return metadata
  } catch (error) {
    await supabaseRequest(
      config,
      `/rest/v1/official_gazette_files?id=eq.${encodeURIComponent(fileId)}`,
      { method: 'DELETE' },
      accessToken,
    ).catch(() => undefined)
    throw error
  }
}

export async function publishGazetteEdition(
  config: PublicSupabaseConfig,
  accessToken: string,
  editionId: string,
) {
  if (!accessToken) throw new Error('Sessão administrativa obrigatória')
  return supabaseRequest<PersistedEdition>(
    config,
    '/rest/v1/rpc/publish_official_gazette',
    { method: 'POST', body: JSON.stringify({ p_edition_id: editionId }) },
    accessToken,
  )
}
