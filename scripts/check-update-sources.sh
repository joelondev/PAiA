#!/usr/bin/env bash
# PAiA single update source guard.
#
# Fails if shipped source references any third-party update, catalog, engine,
# model-download or analytics host. Every such request must go to the PAiA
# Update Service (PAIA_UPDATE_BASE_URL). Test files are excluded.
#
# Usage: scripts/check-update-sources.sh   (run from the repo root; used in CI)
set -euo pipefail

cd "$(dirname "$0")/.."

FORBIDDEN=(
  'apps\.jan\.ai'                       # Jan app updates + HF mirror
  'apps-nightly\.jan\.ai'
  'catalog\.jan\.ai'                    # Jan llama.cpp engine CDN
  'api\.github\.com/repos/janhq'        # Jan releases / engine index
  'github\.com/janhq/[^/"]+/releases'   # Jan release downloads
  'raw\.githubusercontent\.com/janhq'   # Jan model catalog
  'posthog'                             # product analytics
  'googletagmanager'                    # Google Analytics
  'mcp\.exa\.ai'                        # hosted third-party MCP
)

PATHS=(
  src-tauri/src
  src-tauri/plugins
  src-tauri/utils/src
  src-tauri/tauri.conf.json
  web-app/src
  web-app/vite.config.ts
  extensions
)

pattern=$(IFS='|'; echo "${FORBIDDEN[*]}")

hits=$(grep -rniE "$pattern" "${PATHS[@]}" \
  --include='*.rs' --include='*.ts' --include='*.tsx' --include='*.js' --include='*.json' \
  --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=__tests__ --exclude-dir=target \
  --exclude='*.test.ts' --exclude='*.test.tsx' --exclude='*.spec.ts' --exclude='tests.rs' --exclude='*_tests.rs' \
  --exclude='package.json' --exclude='yarn.lock' \
  | grep -vE '^[^:]+:[0-9]+:\s*(//|\*|/\*)' \
  || true)

if [[ -n "$hits" ]]; then
  echo "PAiA update-source check FAILED: third-party hosts found in shipped source:" >&2
  echo "$hits" >&2
  echo >&2
  echo "Route these through the PAiA Update Service (jan_utils::paia / web-app/src/lib/paia.ts)." >&2
  exit 1
fi

echo "PAiA update-source check passed: no third-party update or download hosts."
