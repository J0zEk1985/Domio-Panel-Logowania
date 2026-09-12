import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), 'VITE_')
  if (mode === 'production') {
    if (!env.VITE_SUPABASE_URL || !env.VITE_SUPABASE_ANON_KEY) {
      throw new Error(
        'Brak VITE_SUPABASE_URL lub VITE_SUPABASE_ANON_KEY. Produkcyjny npm run build wymaga pliku .env (albo secrets w CI).',
      )
    }
  }

  return {
    plugins: [react()],
    server: {
      port: 3000,
      open: true,
    },
    /** Production builds only (`npm run build`); dev server keeps console/debugger for DX. */
    esbuild: mode === 'production' ? { drop: ['console', 'debugger'] as const } : undefined,
  }
})
