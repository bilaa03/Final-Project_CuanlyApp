/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        cuanly: {
          bg: '#f8fafc',
          card: '#ffffff',
          violet: '#4f46e5',
          violetLight: '#818cf8',
          mint: '#059669',
          coral: '#ea580c',
          green: '#10b981',
          yellow: '#f59e0b',
          red: '#ef4444',
          border: 'rgba(0, 0, 0, 0.05)',
          textMuted: '#64748b',
          textDark: '#0f172a',
        }
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
