#!/usr/bin/env bash
# Build the PAiA offline pack for Windows x64: a default model plus llama.cpp
# engines laid out exactly as PAiA's data folder expects, and an installer
# script for the unit. Units never download anything; this script runs on OUR
# side (operator machine) and is the "we mirror, we sign" step in miniature.
#
# Usage: scripts/paia/make-offline-pack.sh <output-dir> [cache-dir]
#   output-dir  where PAiA-offline-pack/ is created
#   cache-dir   reuse previously downloaded files (default: <output-dir>/downloads)
#
# Requires: curl, tar, shasum (macOS/Linux) and the GitHub CLI (gh) for engines.
set -euo pipefail

OUT="${1:?usage: make-offline-pack.sh <output-dir> [cache-dir]}"
CACHE="${2:-$OUT/downloads}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---- Pinned contents (update together with their checksums) ----------------
ENGINE_VERSION="b9967"
ENGINE_REPO="janhq/llama.cpp"
ENGINES=(
  "win-common_cpus-x64:72d60f87e80bb097cedad7082f23d47da0243de990c1bdc3d02932f0932881e4"
  "win-vulkan-common_cpus-x64:ff93d9e5c9575e6bb1a8795c1a5999d98a239f2d2c97c74cecd561ac47411e7b"
)
MODEL_ID="qwen2.5-7b-instruct-q4km"
MODEL_NAME="Qwen2.5 7B Instruct (PAiA default)"
MODEL_FILE="Qwen2.5-7B-Instruct-Q4_K_M.gguf"
MODEL_URL="https://huggingface.co/bartowski/Qwen2.5-7B-Instruct-GGUF/resolve/main/$MODEL_FILE"
MODEL_SHA256="65b8fcd92af6b4fefa935c625d1ac27ea29dcb6ee14589c55a8f115ceaaa1423"
MODEL_LICENSE="Apache-2.0 (https://huggingface.co/Qwen/Qwen2.5-7B-Instruct/blob/main/LICENSE)"
# -----------------------------------------------------------------------------

sha() { shasum -a 256 "$1" | awk '{print $1}'; }
verify() { # file expected
  local got; got=$(sha "$1")
  [[ "$got" == "$2" ]] || { echo "Checksum mismatch for $1: $got != $2" >&2; exit 1; }
}

mkdir -p "$CACHE"
PACK="$OUT/PAiA-offline-pack"
rm -rf "$PACK"
mkdir -p "$PACK/data/llamacpp/backends/$ENGINE_VERSION" "$PACK/data/llamacpp/models/$MODEL_ID"

echo "==> Engines ($ENGINE_VERSION)"
for entry in "${ENGINES[@]}"; do
  backend="${entry%%:*}"; want="${entry##*:}"
  archive="llama-$ENGINE_VERSION-bin-$backend.tar.gz"
  [[ -f "$CACHE/$archive" ]] || gh release download "$ENGINE_VERSION" --repo "$ENGINE_REPO" \
    --pattern "$archive" --dir "$CACHE"
  verify "$CACHE/$archive" "$want"
  dest="$PACK/data/llamacpp/backends/$ENGINE_VERSION/$backend"
  mkdir -p "$dest"
  tar -xzf "$CACHE/$archive" -C "$dest"
  [[ -f "$dest/build/bin/llama-server.exe" ]] || { echo "llama-server.exe missing in $archive" >&2; exit 1; }
  echo "    $backend ok"
done

echo "==> Model $MODEL_FILE"
if [[ ! -f "$CACHE/$MODEL_FILE" ]] || [[ "$(sha "$CACHE/$MODEL_FILE")" != "$MODEL_SHA256" ]]; then
  curl -L --fail --retry 5 -C - -o "$CACHE/$MODEL_FILE" "$MODEL_URL"
fi
verify "$CACHE/$MODEL_FILE" "$MODEL_SHA256"
model_dir="$PACK/data/llamacpp/models/$MODEL_ID"
# Hard link when possible to avoid a second 4.7 GB copy on the build machine.
ln "$CACHE/$MODEL_FILE" "$model_dir/model.gguf" 2>/dev/null || cp "$CACHE/$MODEL_FILE" "$model_dir/model.gguf"
size=$(wc -c < "$model_dir/model.gguf" | tr -d ' ')
cat > "$model_dir/model.yml" <<YML
model_path: llamacpp/models/$MODEL_ID/model.gguf
name: $MODEL_NAME
size_bytes: $size
model_sha256: $MODEL_SHA256
model_size_bytes: $size
embedding: false
YML

echo "==> Installer scripts"
cp "$SCRIPT_DIR/offline-pack/Install-PAiA-Offline-Pack.ps1" "$PACK/"
cp "$SCRIPT_DIR/offline-pack/Install-PAiA-Offline-Pack.cmd" "$PACK/"
cp "$SCRIPT_DIR/offline-pack/README.txt" "$PACK/"
# Windows line endings for the files people open or run on the unit
for f in Install-PAiA-Offline-Pack.ps1 Install-PAiA-Offline-Pack.cmd README.txt; do
  perl -pi -e 's/\r?\n/\r\n/' "$PACK/$f"
done

echo "==> Manifest"
{
  echo "# PAiA offline pack manifest (SHA-256, paths relative to this folder)"
  echo "# engine=$ENGINE_VERSION model=$MODEL_ID license=$MODEL_LICENSE"
  (cd "$PACK" && find data -type f | LC_ALL=C sort | while read -r f; do
     echo "$(sha "$f")  $f"; done)
} > "$PACK/manifest.sha256"

du -sh "$PACK"
echo "Done: $PACK"
