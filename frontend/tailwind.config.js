export default {
  content: ['./index.html','./src/**/*.{js,jsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: { display: ['Syne','sans-serif'], body: ['DM Sans','sans-serif'] },
      colors: {
        campus: { 400:'#818cf8', 500:'#6366f1', 600:'#4f46e5' },
        surface: { DEFAULT:'#0f0f13', card:'#16161d', border:'#1f1f2e', hover:'#1a1a24' }
      },
      animation: { 'fade-in':'fadeIn .3s ease-out', 'slide-up':'slideUp .4s cubic-bezier(.16,1,.3,1)' },
      keyframes: {
        fadeIn: { '0%':{opacity:0}, '100%':{opacity:1} },
        slideUp: { '0%':{opacity:0,transform:'translateY(16px)'}, '100%':{opacity:1,transform:'translateY(0)'} }
      }
    }
  },
  plugins: []
}
