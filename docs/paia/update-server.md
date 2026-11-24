# Setting up the PAiA Update Service

Version 1 of the Update Service is **a folder of static files served over HTTPS**.
Every endpoint PAiA calls can be a plain file, so any static host works: an S3 /
R2 / Azure Blob bucket behind a CDN, or nginx/Caddy on a VM. Air-gapped customers
get the same folder as a mirror on their own network.

## 1. Pick the origin

1. Choose a domain you control, e.g. `https://updates.<company>.com`.
2. Get a TLS certificate for it (the CDN or Caddy can do this automatically).
3. Build PAiA with that origin:
   - `PAIA_UPDATE_BASE_URL=https://updates.<company>.com` when building.
   - Set the same origin in `src-tauri/tauri.conf.json` → `plugins.updater.endpoints`
     (`/update-check` and `/releases/latest.json`). The app ignores endpoints on any
     other origin.

## 2. Folder layout

```
/update-check                          app update manifest (same JSON as latest.json)
/releases/latest.json                  app update manifest
/releases/notes.json                   release notes: [{ "tag_name", "name", "body", "prerelease", "draft", "published_at" }]
/releases/<version>/<installer files>  signed installers + .sig files
/catalog/models.json                   model catalog (same schema as Jan's model_catalog_v2.json)
/catalog/latest-model.json             featured model
/engines/llama.cpp/releases.json       [{ "tag_name": "b9967", "assets": [{ "name": "llama-b9967-bin-win-common_cpus-x64.tar.gz" }, ...] }]
/engines/llama.cpp/<tag>/<asset>       engine archives (+ cudart-* for CUDA)
/models/huggingface.co/<repo>/resolve/main/<file>   vetted model files
/models/huggingface.co/api/models/<repo>            vetted model metadata (copy of the HF API JSON)
```

Anything not in the folder returns 404. That is the vetting mechanism: a unit can
only get a model, engine or release that we have deliberately put here.

## 3. Publish an app release

1. Build with `createUpdaterArtifacts: true` and the signing key in the environment
   (`TAURI_SIGNING_PRIVATE_KEY`, `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`). The build
   produces the installer plus a `.sig` file.
2. Upload them to `/releases/<version>/`.
3. Write `/releases/latest.json` and copy it to `/update-check`:

```json
{
  "version": "0.9.0",
  "notes": "Short release notes",
  "pub_date": "2026-12-01T09:00:00Z",
  "platforms": {
    "windows-x86_64": {
      "signature": "<contents of the .sig file>",
      "url": "https://updates.<company>.com/releases/0.9.0/PAiA_0.9.0_x64-setup.exe"
    }
  }
}
```

Units verify the signature against the public key compiled into the app
(key ID `F4564594B175B837`) before installing.

## 4. Publish engines and models (our "mirror and vet" step)

1. Download the upstream file on our side (llama.cpp from GitHub, models from
   Hugging Face). A Hugging Face account is only needed for gated models.
2. Check its SHA-256 against the upstream value, test it on each hardware SKU and
   review the licence.
3. Upload it to the matching path above and add it to `releases.json` /
   `catalog/models.json`.

`scripts/paia/make-offline-pack.sh` already does steps 1-2 for the default model and
engines; the same files can be uploaded to the server.

## 5. Air-gapped sites

Copy the whole folder to a server on the customer network and build/configure
units with that origin, or ship the offline pack on USB.

## 6. Local test server (for development only)

```bash
cd <folder with the layout above>
python3 -m http.server 8080
```

Build a test app with `PAIA_UPDATE_BASE_URL=http://<lan-ip>:8080`. Catalog, engine
and model downloads work over plain HTTP for testing. The Tauri updater requires
HTTPS for app updates unless `dangerousInsecureTransportProtocol` is enabled in a
test-only config.

## Later (not needed for v1)

- Validate the HMAC headers the app sends (`/update-check`, downloads) to restrict
  access to licensed units.
- TUF metadata, rollout rings and per-customer channels (see the PRD).
