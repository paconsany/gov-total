/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#eefbf5',
          600: '#08785b',
          700: '#076048',
          950: '#052e24',
        },
      },
    },
  },
  plugins: [],
}
