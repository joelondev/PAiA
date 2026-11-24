/**
 * PAiA single update source (web side).
 *
 * Mirrors `jan_utils::paia` in Rust: every catalog, metadata and model request
 * goes to the PAiA Update Service. Hugging Face URLs are rewritten to our
 * mirror at `/models/<host>/<path>`; any other third-party host is refused.
 */

const MIRRORED_MODEL_HOSTS = ['huggingface.co', 'hf.co']

const base = () => PAIA_UPDATE_BASE_URL.replace(/\/+$/, '')

const hostMatches = (host: string, domain: string) =>
  host === domain || host.endsWith(`.${domain}`)

export function isPaiaUrl(url: string): boolean {
  try {
    const target = new URL(url)
    const origin = new URL(base())
    return target.origin === origin.origin
  } catch {
    return false
  }
}

/** Rewrite a URL to the PAiA Update Service, or throw if it may not be fetched. */
export function toPaiaUrl(url: string): string {
  if (isPaiaUrl(url)) return url
  let parsed: URL
  try {
    parsed = new URL(url)
  } catch {
    throw new Error(`Invalid URL: ${url}`)
  }
  if (MIRRORED_MODEL_HOSTS.some((d) => hostMatches(parsed.hostname, d))) {
    return `${base()}/models/${parsed.hostname}${parsed.pathname}${parsed.search}`
  }
  throw new Error(
    `Blocked request to ${parsed.hostname}: PAiA units only fetch from ${base()}`
  )
}
