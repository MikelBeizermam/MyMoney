import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Served from https://<user>.github.io/MyMoney/ on GitHub Pages.
export default defineConfig({
  base: '/MyMoney/',
  plugins: [react()],
})
