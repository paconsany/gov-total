export type PublicSupabaseConfig = {
  url: string
  publishableKey: string
}

export type SupabaseConfiguration =
  | { configured: true; config: PublicSupabaseConfig }
  | { configured: false; missing: string[] }

const cleanUrl = (value: string) => value.trim().replace(/\/+$/, '')

export function getPublicSupabaseConfiguration(): SupabaseConfiguration {
  const url = cleanUrl(import.meta.env.VITE_SUPABASE_URL ?? '')
  const publishableKey = (
    import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ?? import.meta.env.VITE_SUPABASE_ANON_KEY ?? ''
  ).trim()
  const missing = [
    !url && 'VITE_SUPABASE_URL',
    !publishableKey && 'VITE_SUPABASE_PUBLISHABLE_KEY',
  ].filter((item): item is string => Boolean(item))

  return missing.length ? { configured: false, missing } : { configured: true, config: { url, publishableKey } }
}

export async function supabaseRequest<T>(
  config: PublicSupabaseConfig,
  path: string,
  init: RequestInit = {},
  accessToken?: string,
): Promise<T> {
  const response = await fetch(`${config.url}${path}`, {
    ...init,
    headers: {
      apikey: config.publishableKey,
      Authorization: `Bearer ${accessToken ?? config.publishableKey}`,
      ...(init.body ? { 'Content-Type': 'application/json' } : {}),
      ...init.headers,
    },
  })

  if (!response.ok) {
    const detail = await response.text()
    throw new Error(`Supabase ${response.status}: ${detail || response.statusText}`)
  }

  if (response.status === 204) return undefined as T
  return (await response.json()) as T
}
