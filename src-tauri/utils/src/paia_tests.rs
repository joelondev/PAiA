//! Tests for the PAiA single update source (kept separate so the CI host guard
//! can scan paia.rs without matching the blocked hosts used as test inputs).
use super::*;

#[test]
fn joins_paths() {
    assert_eq!(
        paia_url("/catalog/models.json"),
        format!("{PAIA_UPDATE_BASE_URL}/catalog/models.json")
    );
}

#[test]
fn paia_urls_pass_through() {
    let u = paia_url("engines/llama.cpp/b1/x.tar.gz");
    assert!(is_paia_url(&u));
    assert_eq!(resolve_download_url(&u).unwrap(), u);
}

#[test]
fn huggingface_is_rewritten_to_our_mirror() {
    let out =
        resolve_download_url("https://huggingface.co/org/repo/resolve/main/m.gguf").unwrap();
    assert_eq!(
        out,
        paia_url("models/huggingface.co/org/repo/resolve/main/m.gguf")
    );
    assert!(is_paia_url(&out));
}

#[test]
fn third_party_hosts_are_blocked() {
    for u in [
        "https://apps.jan.ai/update-check",
        "https://catalog.jan.ai/llama.cpp/releases/releases.json",
        "https://github.com/janhq/llama.cpp/releases/download/x/y.tar.gz",
        "https://example.com/file.bin",
        "https://huggingface.co.evil.com/file",
    ] {
        assert!(resolve_download_url(u).is_err(), "{u} should be blocked");
    }
}

#[test]
fn lookalike_hosts_are_not_paia() {
    let base = Url::parse(PAIA_UPDATE_BASE_URL).unwrap();
    let host = base.host_str().unwrap();
    assert!(!is_paia_url(&format!("https://{host}.evil.com/x")));
    assert!(!is_paia_url(&format!("http://{host}/x")));
}
