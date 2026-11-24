import { defineConfig, loadEnv, Plugin } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'
import { TanStackRouterVite } from '@tanstack/router-plugin/vite'
import { nodePolyfills } from 'vite-plugin-node-polyfills'
import packageJson from './package.json'
const host = process.env.TAURI_DEV_HOST

// Plugin to inject GA scripts in HTML
/** PAiA Update Service origin. Must match PAIA_UPDATE_BASE_URL used for the Rust build. */
const PAIA_UPDATE_BASE_URL = (
  process.env.PAIA_UPDATE_BASE_URL || 'https://updates.paia.example'
).replace(/\/+$/, '')

/** PAiA: no third-party analytics. Strips the analytics placeholder from index.html. */
function stripAnalyticsPlaceholder(): Plugin {
  return {
    name: 'paia-strip-analytics-placeholder',
    transformIndexHtml(html) {
      return html.replace(/\s*<!-- INJECT_GOOGLE_ANALYTICS -->\n?/g, '')
    },
  }
}

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  // Load env file based on `mode` in the current working directory.
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [
      TanStackRouterVite({
        target: 'react',
        autoCodeSplitting: true,
        routeFileIgnorePattern: '.((test).ts)|test-page',
      }),
      react(),
      tailwindcss(),
      nodePolyfills({
        include: ['path'],
      }),
      stripAnalyticsPlaceholder(),
    ],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
        '@janhq/conversational-extension': path.resolve(__dirname, '../extensions/conversational-extension/src/index.ts'),
      },
    },
    define: {
      IS_TAURI: JSON.stringify(process.env.IS_TAURI),
      IS_DEV: JSON.stringify(process.env.IS_DEV),
      IS_WEB_APP: JSON.stringify(false),
      IS_MACOS: JSON.stringify(
        process.env.TAURI_ENV_PLATFORM?.includes('darwin') ?? false
      ),
      IS_WINDOWS: JSON.stringify(
        process.env.TAURI_ENV_PLATFORM?.includes('windows') ?? false
      ),
      IS_LINUX: JSON.stringify(
        process.env.TAURI_ENV_PLATFORM?.includes('linux') ?? false
      ),
      IS_IOS: JSON.stringify(
        process.env.TAURI_ENV_PLATFORM?.includes('ios') ?? false
      ),
      IS_ANDROID: JSON.stringify(
        process.env.TAURI_ENV_PLATFORM?.includes('android') ?? false
      ),
      PLATFORM: JSON.stringify(process.env.TAURI_ENV_PLATFORM),

      VERSION: JSON.stringify(packageJson.version),

      // PAiA single update source: catalog and release notes come only from us.
      PAIA_UPDATE_BASE_URL: JSON.stringify(PAIA_UPDATE_BASE_URL),
      IS_PAIA_APPLIANCE: JSON.stringify(process.env.PAIA_APPLIANCE !== '0'),
      MODEL_CATALOG_URL: JSON.stringify(`${PAIA_UPDATE_BASE_URL}/catalog/models.json`),
      LATEST_JAN_MODEL_URL: JSON.stringify(
        `${PAIA_UPDATE_BASE_URL}/catalog/latest-model.json`
      ),
      RELEASE_NOTES_URL: JSON.stringify(`${PAIA_UPDATE_BASE_URL}/releases/notes.json`),
      AUTO_UPDATER_DISABLED: JSON.stringify(
        env.AUTO_UPDATER_DISABLED === 'true'
      ),
      UPDATE_CHECK_INTERVAL_MS: JSON.stringify(
        Number(env.UPDATE_CHECK_INTERVAL_MS) || 60 * 60 * 1000
      ),
    },

    // Vite options tailored for Tauri development and only applied in `tauri dev` or `tauri build`
    //
    // 1. prevent vite from obscuring rust errors
    clearScreen: false,
    // 2. tauri expects a fixed port, fail if that port is not available
    server: {
      port: 1420,
      strictPort: true,
      host: host || false,
      hmr: host
        ? {
            protocol: 'ws',
            host,
            port: 1421,
          }
        : undefined,
      watch: {
        // 3. tell vite to ignore watching `src-tauri`
        ignored: ['**/src-tauri/**'],
        usePolling: true
      },
    },
  }
})
