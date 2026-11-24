//! PAiA single update source.
//!
//! Every update, engine, catalog and model download a PAiA unit makes must come
//! from one origin that we operate. That origin is fixed at build time through
//! the `PAIA_UPDATE_BASE_URL` environment variable, so it cannot be changed from
//! user-editable settings on a shipped unit.
//!
//! Layout served by the PAiA Update Service (all paths relative to the base):
//!   /update-check                         app update manifest (Tauri/HMAC)
//!   /releases/latest.json                 app update manifest (fallback)
//!   /releases/notes.json                  release notes
//!   /catalog/models.json                  signed model catalog
//!   /catalog/latest-model.json            featured model
//!   /engines/llama.cpp/releases.json      engine release index
//!   /engines/llama.cpp/<version>/<file>   engine + CUDA runtime archives
//!   /models/<upstream host>/<path>        mirrored model files

use url::Url;

/// Base URL of the PAiA Update Service, with no trailing slash.
///
/// Set `PAIA_UPDATE_BASE_URL` in CI for release builds. The default is a
/// reserved placeholder domain that resolves nowhere, so a build without the
/// variable can never silently talk to a third party.
pub const PAIA_UPDATE_BASE_URL: &str = match option_env!("PAIA_UPDATE_BASE_URL") {
    Some(url) => url,
    None => "https://updates.paia.example",
};

/// Upstream hosts whose files we re-host under `/models/<host>/...`.
/// A URL on one of these hosts is rewritten to our mirror; it is never fetched
/// from the upstream host directly.
const MIRRORED_MODEL_HOSTS: &[&str] = &["huggingface.co", "hf.co"];

/// Join a path onto the PAiA base URL.
pub fn paia_url(path: &str) -> String {
    format!(
        "{}/{}",
        PAIA_UPDATE_BASE_URL.trim_end_matches('/'),
        path.trim_start_matches('/')
    )
}

fn host_matches(host: &str, domain: &str) -> bool {
    host == domain || host.ends_with(&format!(".{domain}"))
}

/// True when `url` points at the PAiA Update Service (same scheme, host and port).
pub fn is_paia_url(url: &str) -> bool {
    let (Ok(target), Ok(base)) = (Url::parse(url), Url::parse(PAIA_UPDATE_BASE_URL)) else {
        return false;
    };
    target.scheme() == base.scheme()
        && target.host_str().is_some()
        && target.host_str() == base.host_str()
        && target.port_or_known_default() == base.port_or_known_default()
}

/// Resolve a requested download URL to the URL a PAiA unit is allowed to fetch.
///
/// - PAiA URLs are returned unchanged.
/// - Mirrored upstream model URLs (Hugging Face) are rewritten to `/models/<host>/<path>`.
/// - Anything else is refused.
pub fn resolve_download_url(url: &str) -> Result<String, String> {
    if is_paia_url(url) {
        return Ok(url.to_string());
    }
    let parsed = Url::parse(url).map_err(|e| format!("Invalid download URL '{url}': {e}"))?;
    let host = parsed
        .host_str()
        .ok_or_else(|| format!("Download URL has no host: {url}"))?;

    if MIRRORED_MODEL_HOSTS.iter().any(|d| host_matches(host, d)) {
        let mut path = format!("models/{host}{}", parsed.path());
        if let Some(q) = parsed.query() {
            path.push('?');
            path.push_str(q);
        }
        return Ok(paia_url(&path));
    }

    Err(format!(
        "Blocked download from '{host}': PAiA units only download from {PAIA_UPDATE_BASE_URL}"
    ))
}

#[cfg(test)]
#[path = "paia_tests.rs"]
mod tests;
