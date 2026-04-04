import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  plugins: [react()],
  server: {
    port: 3000,
    open: true
  },
  /** Production builds only (`npm run build`); dev server keeps console/debugger for DX. */
  esbuild:
    mode === "production" ? { drop: ["console", "debugger"] as const } : undefined,
}))
