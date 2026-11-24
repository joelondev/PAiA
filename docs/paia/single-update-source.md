# PAiA single update source

PAiA units take app updates, inference engines, the model catalog and model files
from exactly one origin: the **PAiA Update Service**. Nothing is fetched from Jan,
GitHub, Hugging Face, npm or PyPI at runtime.

## Build-time configuration

| Variable | Used by | Purpose |
| --- | --- | --- |
| `PAIA_UPDATE_BASE_URL` | Rust (`jan_utils::paia`) and web app (`vite.config.ts`) | Origin of the PAiA Update Service, e.g. `https://updates.paia.com`. Defaults to the placeholder `https://updates.paia.example`, which resolves nowhere. |
| `PAIA_SIGNING_KEY` | Rust updater + downloads | HMAC key for signed requests to the Update Service (replaces `JAN_SIGNING_KEY`). |
| `PAIA_APPLIANCE` | Web app | `1` (default) for appliance builds; set `0` only for internal dev builds. |

Also set before any release:

- `src-tauri/tauri.conf.json` → `plugins.updater.endpoints`: must be on `PAIA_UPDATE_BASE_URL`. The app ignores any endpoint on another origin.
- `src-tauri/tauri.conf.json` → `plugins.updater.pubkey`: replace `REPLACE_WITH_PAIA_UPDATER_PUBKEY` with our updater public key (`tauri signer generate`; keep the private key in the HSM / CI secret store). Until it is set, update installation fails closed.

## URL layout the Update Service must serve

| Path | Contents |
| --- | --- |
| `/update-check` | App update manifest (HMAC-signed request) |
| `/releases/latest.json` | App update manifest (fallback, Tauri format; see `src-tauri/latest.json.template`) |
| `/releases/notes.json` | Release notes, same shape as the GitHub releases API (array) |
| `/releases` | Human-readable release notes page (linked from Settings) |
| `/catalog/models.json` | PAiA model catalog (same schema as Jan `model_catalog_v2.json`) |
| `/catalog/latest-model.json` | Featured model |
| `/engines/llama.cpp/releases.json` | Engine release index (GitHub releases schema) |
| `/engines/llama.cpp/<version>/<file>` | Engine and CUDA runtime archives |
| `/models/huggingface.co/<path>` | Mirror of vetted Hugging Face files and `/api/models/...` metadata. Return 404 for models we have not approved. |

## Enforcement in code

- `src-tauri/utils/src/paia.rs`: `resolve_download_url` rewrites Hugging Face URLs to our mirror and refuses every other host. All model downloads (`core/downloads`) and CLI downloads go through it, with no fallback to the original host.
- `src-tauri/src/core/updater/commands.rs`: drops updater endpoints that are not on our origin.
- `tauri-plugin-llamacpp/src/backend.rs`: engine index and archives come only from `/engines/...`.
- `src-tauri/src/core/mcp`: no default MCP servers; `npx`/`uvx`/`bunx`/`pipx` servers are refused (they download packages from public registries).
- `web-app/src/lib/paia.ts`: the same URL rules for the web app (catalog, metadata, README).
- PostHog and Google Analytics are removed.
- `scripts/check-update-sources.sh`: CI guard that fails if a Jan, GitHub-release, raw GitHub, PostHog, Google Analytics or Exa host appears in shipped source.

## Not yet done

- Ship approved MCP servers pre-bundled and signed inside releases.
- Bundle engines per hardware SKU in the release instead of downloading them on first run.
- TUF metadata verification on the device, A/B install and rollback (see the PRD).
- Cloud model providers (OpenAI, Anthropic, …) hidden by default behind admin policy.
- Rebrand (product name, bundle id, icons) and replace Jan's CI release workflows, which still pass `JAN_SIGNING_KEY`.
