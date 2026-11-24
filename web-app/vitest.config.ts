import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    globals: true,
    css: true,
    testTimeout: 30000,
    hookTimeout: 30000,
    coverage: {
      reporter: ['text', 'json', 'html', 'lcov'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        'node_modules/',
        'dist/',
        'coverage/',
        'src/**/*.test.ts',
        'src/**/*.test.tsx',
        'src/test/**/*',
      ],
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  define: {
    IS_TAURI: JSON.stringify(false),
    IS_WEB_APP: JSON.stringify(false),
    IS_MACOS: JSON.stringify(false),
    IS_WINDOWS: JSON.stringify(false),
    IS_LINUX: JSON.stringify(false),
    IS_IOS: JSON.stringify(false),
    IS_ANDROID: JSON.stringify(false),
    PLATFORM: JSON.stringify('web'),
    VERSION: JSON.stringify('test'),
    AUTO_UPDATER_DISABLED: JSON.stringify('false'),
    PAIA_UPDATE_BASE_URL: JSON.stringify('https://updates.paia.example'),
    IS_PAIA_APPLIANCE: JSON.stringify(true),
    MODEL_CATALOG_URL: JSON.stringify('https://updates.paia.example/catalog/models.json'),
    LATEST_JAN_MODEL_URL: JSON.stringify('https://updates.paia.example/catalog/latest-model.json'),
    RELEASE_NOTES_URL: JSON.stringify('https://updates.paia.example/releases/notes.json'),
  },
})
