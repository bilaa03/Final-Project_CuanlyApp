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
          bg: '#0F0F14',
          card: '#1C1C24',
          violet: '#534AB7',
          violetLight: '#7F77DD',
          mint: '#1D9E75',
          coral: '#D85A30',
          green: '#639922',
          yellow: '#EF9F27',
          red: '#E24B4A',
          border: 'rgba(255, 255, 255, 0.06)',
          textMuted: '#8B8A88',
        }
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
