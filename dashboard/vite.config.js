import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/auth': 'http://localhost:8787',
      '/financial': 'http://localhost:8787',
      '/rag': 'http://localhost:8787',
      '/demo-questions': 'http://localhost:8787',
      '/chunks': 'http://localhost:8787',
    }
  },
  build: {
    outDir: path.resolve(__dirname, '../backend/public'),
    emptyOutDir: true,
  }
})
