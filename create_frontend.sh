#!/bin/bash
FRONT="$HOME/Downloads/files/frontend"
mkdir -p "$FRONT/src/components" "$FRONT/src/pages" "$FRONT/src/services" "$FRONT/src/context"

# ── index.html ────────────────────────────────────────────────────────────────
cat > "$FRONT/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en" class="dark">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>CampusConnect</title>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet" />
  </head>
  <body class="bg-[#0f0f13] text-white antialiased">
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

# ── vite.config.js ────────────────────────────────────────────────────────────
cat > "$FRONT/vite.config.js" << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
export default defineConfig({ plugins: [react()], server: { port: 5173 } })
EOF

# ── tailwind.config.js ────────────────────────────────────────────────────────
cat > "$FRONT/tailwind.config.js" << 'EOF'
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
EOF

# ── postcss.config.js ─────────────────────────────────────────────────────────
cat > "$FRONT/postcss.config.js" << 'EOF'
export default { plugins: { tailwindcss: {}, autoprefixer: {} } }
EOF

# ── src/index.css ─────────────────────────────────────────────────────────────
cat > "$FRONT/src/index.css" << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
@layer base {
  body { font-family: 'DM Sans', sans-serif; background: #0f0f13; color: #f0f0f5; }
  ::-webkit-scrollbar { width: 6px; }
  ::-webkit-scrollbar-track { background: #0f0f13; }
  ::-webkit-scrollbar-thumb { background: #1f1f2e; border-radius: 8px; }
}
@layer components {
  .btn-primary { @apply bg-campus-500 hover:bg-campus-600 text-white font-semibold px-4 py-2.5 rounded-xl transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed; }
  .btn-ghost { @apply bg-transparent hover:bg-surface-hover border border-surface-border text-gray-300 hover:text-white font-medium px-4 py-2.5 rounded-xl transition-all duration-200; }
  .card { @apply bg-surface-card border border-surface-border rounded-2xl; }
  .input { @apply w-full bg-surface-hover border border-surface-border rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-campus-500 focus:ring-1 focus:ring-campus-500 transition-all; }
  .label { @apply block text-sm font-medium text-gray-400 mb-1.5; }
}
EOF

# ── src/main.jsx ──────────────────────────────────────────────────────────────
cat > "$FRONT/src/main.jsx" << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'
import App from './App.jsx'
import './index.css'
ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
      <Toaster position="top-right" toastOptions={{ style: { background:'#16161d', color:'#fff', border:'1px solid #1f1f2e', borderRadius:'12px' } }} />
    </BrowserRouter>
  </React.StrictMode>
)
EOF

# ── src/services/api.js ───────────────────────────────────────────────────────
cat > "$FRONT/src/services/api.js" << 'EOF'
import axios from 'axios'
import toast from 'react-hot-toast'
const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'
const api = axios.create({ baseURL: BASE_URL, headers: { 'Content-Type': 'application/json' } })
api.interceptors.request.use(c => { const t = localStorage.getItem('cc_token'); if(t) c.headers.Authorization=`Bearer ${t}`; return c })
api.interceptors.response.use(r => r, e => { if(e.response?.status===401){ localStorage.removeItem('cc_token'); localStorage.removeItem('cc_user'); window.location.href='/login' } return Promise.reject(e) })
export const authAPI = {
  signup: d => api.post('/auth/signup', d),
  verifyOTP: d => api.post('/auth/verify-otp', d),
  resendOTP: e => api.post(`/auth/resend-otp?email=${encodeURIComponent(e)}`),
  login: d => api.post('/auth/login', d),
  me: () => api.get('/auth/me'),
  updateProfile: d => api.put('/auth/profile', d),
  uploadAvatar: fd => api.post('/auth/upload-avatar', fd, { headers:{'Content-Type':'multipart/form-data'} }),
}
export const postsAPI = {
  getFeed: (p=1) => api.get(`/posts/feed?page=${p}&limit=10`),
  getTrending: () => api.get('/posts/trending'),
  getUserPosts: (uid,p=1) => api.get(`/posts/user/${uid}?page=${p}`),
  create: fd => api.post('/posts/create', fd, { headers:{'Content-Type':'multipart/form-data'} }),
  like: id => api.post('/posts/like', { post_id:id }),
  unlike: id => api.delete('/posts/unlike', { data:{ post_id:id } }),
  report: (id,reason) => api.post('/posts/report', { post_id:id, reason }),
  delete: id => api.delete(`/posts/${id}`),
}
export const commentsAPI = {
  add: (pid,content) => api.post('/comments/add', { post_id:pid, content }),
  get: pid => api.get(`/comments/${pid}`),
  delete: id => api.delete(`/comments/${id}`),
}
export const pollsAPI = {
  getAll: () => api.get('/poll/all'),
  get: id => api.get(`/poll/${id}`),
  create: d => api.post('/poll/create', d),
  vote: (pid,oid) => api.post('/poll/vote', { poll_id:pid, option_id:oid }),
}
export const notificationsAPI = {
  getAll: () => api.get('/notifications/'),
  getUnreadCount: () => api.get('/notifications/unread-count'),
  markAllRead: () => api.put('/notifications/read-all'),
  markRead: id => api.put(`/notifications/${id}/read`),
}
export default api
EOF

# ── src/context/AuthContext.jsx ───────────────────────────────────────────────
cat > "$FRONT/src/context/AuthContext.jsx" << 'EOF'
import { createContext, useContext, useState, useEffect, useCallback } from 'react'
import { authAPI } from '../services/api'
const AuthContext = createContext(null)
export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => { try { return JSON.parse(localStorage.getItem('cc_user')) } catch { return null } })
  const [token, setToken] = useState(() => localStorage.getItem('cc_token'))
  const [loading, setLoading] = useState(true)
  useEffect(() => {
    if (token) { authAPI.me().then(r => { setUser(r.data); localStorage.setItem('cc_user', JSON.stringify(r.data)) }).catch(() => logout()).finally(() => setLoading(false)) }
    else setLoading(false)
  }, [])
  const login = useCallback((t, u) => { localStorage.setItem('cc_token',t); localStorage.setItem('cc_user',JSON.stringify(u)); setToken(t); setUser(u) }, [])
  const logout = useCallback(() => { localStorage.removeItem('cc_token'); localStorage.removeItem('cc_user'); setToken(null); setUser(null) }, [])
  const refreshUser = useCallback(async () => { try { const r = await authAPI.me(); setUser(r.data); localStorage.setItem('cc_user', JSON.stringify(r.data)) } catch {} }, [])
  return <AuthContext.Provider value={{ user, token, loading, login, logout, refreshUser }}>{children}</AuthContext.Provider>
}
export const useAuth = () => { const c = useContext(AuthContext); if (!c) throw new Error('useAuth outside provider'); return c }
EOF

# ── src/App.jsx ───────────────────────────────────────────────────────────────
cat > "$FRONT/src/App.jsx" << 'EOF'
import { Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Login from './pages/Login'
import Signup from './pages/Signup'
import Verify from './pages/Verify'
import Feed from './pages/Feed'
import Trending from './pages/Trending'
import Polls from './pages/Polls'
import Notifications from './pages/Notifications'
import Profile from './pages/Profile'

function Protected({ children }) {
  const { user, loading } = useAuth()
  if (loading) return <div className="min-h-screen flex items-center justify-center"><div className="w-10 h-10 border-2 border-campus-500 border-t-transparent rounded-full animate-spin"/></div>
  return user ? children : <Navigate to="/login" replace />
}
function Guest({ children }) {
  const { user, loading } = useAuth()
  if (loading) return null
  return !user ? children : <Navigate to="/feed" replace />
}
function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/feed" replace />} />
      <Route path="/login" element={<Guest><Login /></Guest>} />
      <Route path="/signup" element={<Guest><Signup /></Guest>} />
      <Route path="/verify" element={<Guest><Verify /></Guest>} />
      <Route path="/feed" element={<Protected><Feed /></Protected>} />
      <Route path="/trending" element={<Protected><Trending /></Protected>} />
      <Route path="/polls" element={<Protected><Polls /></Protected>} />
      <Route path="/notifications" element={<Protected><Notifications /></Protected>} />
      <Route path="/profile" element={<Protected><Profile /></Protected>} />
      <Route path="/profile/:id" element={<Protected><Profile /></Protected>} />
      <Route path="*" element={<Navigate to="/feed" replace />} />
    </Routes>
  )
}
export default function App() {
  return <AuthProvider><AppRoutes /></AuthProvider>
}
EOF

# ── src/components/Layout.jsx ─────────────────────────────────────────────────
cat > "$FRONT/src/components/Layout.jsx" << 'EOF'
import { useState, useEffect } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { Home, TrendingUp, BarChart2, Bell, User, LogOut, GraduationCap } from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import { notificationsAPI } from '../services/api'
const BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000'
function Navbar() {
  const { user, logout } = useAuth()
  const location = useLocation(); const navigate = useNavigate()
  const [unread, setUnread] = useState(0)
  useEffect(() => {
    notificationsAPI.getUnreadCount().then(r => setUnread(r.data.unread_count)).catch(()=>{})
    const t = setInterval(() => notificationsAPI.getUnreadCount().then(r => setUnread(r.data.unread_count)).catch(()=>{}), 30000)
    return () => clearInterval(t)
  }, [])
  const links = [
    { to:'/feed', icon:Home, label:'Feed' },
    { to:'/trending', icon:TrendingUp, label:'Trending' },
    { to:'/polls', icon:BarChart2, label:'Polls' },
    { to:'/notifications', icon:Bell, label:'Alerts', badge:unread },
    { to:'/profile', icon:User, label:'Profile' },
  ]
  const src = user?.profile_picture ? (user.profile_picture.startsWith('http') ? user.profile_picture : `${BASE}${user.profile_picture}`) : null
  return (
    <>
      <aside className="hidden md:flex flex-col fixed left-0 top-0 h-screen w-60 bg-surface-card border-r border-surface-border z-40 p-6">
        <Link to="/feed" className="flex items-center gap-2.5 mb-10">
          <div className="w-9 h-9 bg-campus-500 rounded-xl flex items-center justify-center"><GraduationCap size={20} className="text-white"/></div>
          <span className="font-display font-bold text-lg">Campus<span className="text-campus-400">Connect</span></span>
        </Link>
        <nav className="flex-1 flex flex-col gap-1">
          {links.map(({ to, icon:Icon, label, badge }) => {
            const active = location.pathname === to
            return (
              <Link key={to} to={to} className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all relative ${active ? 'bg-campus-500/15 text-campus-400' : 'text-gray-400 hover:bg-surface-hover hover:text-white'}`}>
                <Icon size={18}/>{label}
                {badge > 0 && <span className="ml-auto bg-campus-500 text-white text-xs font-bold px-1.5 py-0.5 rounded-full min-w-[20px] text-center">{badge > 99 ? '99+' : badge}</span>}
              </Link>
            )
          })}
        </nav>
        <div className="flex items-center gap-3 pt-4 border-t border-surface-border">
          {src ? <img src={src} alt="" className="w-9 h-9 rounded-full object-cover ring-2 ring-surface-border"/> : <div className="w-9 h-9 rounded-full bg-campus-500/20 flex items-center justify-center text-campus-400 font-bold text-sm">{user?.name?.[0]?.toUpperCase()}</div>}
          <div className="flex-1 min-w-0"><p className="text-sm font-semibold truncate">{user?.name}</p><p className="text-xs text-gray-500 truncate">{user?.email?.split('@')[0]}</p></div>
          <button onClick={() => { logout(); navigate('/login') }} className="p-1.5 text-gray-500 hover:text-red-400 hover:bg-red-400/10 rounded-lg transition-all"><LogOut size={16}/></button>
        </div>
      </aside>
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-surface-card border-t border-surface-border z-40 flex">
        {links.map(({ to, icon:Icon, badge }) => (
          <Link key={to} to={to} className={`flex-1 flex flex-col items-center py-3 relative transition-colors ${location.pathname===to ? 'text-campus-400' : 'text-gray-500'}`}>
            <div className="relative"><Icon size={20}/>{badge > 0 && <span className="absolute -top-1 -right-1 bg-campus-500 text-white text-[9px] font-bold px-1 rounded-full">{badge > 9 ? '9+' : badge}</span>}</div>
          </Link>
        ))}
      </nav>
    </>
  )
}
export default function Layout({ children }) {
  return (
    <div className="min-h-screen bg-surface">
      <Navbar/>
      <div className="md:pl-60">
        <div className="max-w-xl mx-auto px-4 py-6 pb-24 md:pb-8">{children}</div>
      </div>
    </div>
  )
}
EOF

# ── src/components/PostCard.jsx ───────────────────────────────────────────────
cat > "$FRONT/src/components/PostCard.jsx" << 'EOF'
import { useState } from 'react'
import { formatDistanceToNow } from 'date-fns'
import { Heart, MessageCircle, Flag, Trash2, Ghost, MoreHorizontal, X } from 'lucide-react'
import { postsAPI, commentsAPI } from '../services/api'
import { useAuth } from '../context/AuthContext'
import toast from 'react-hot-toast'
const BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000'
function Avatar({ user, size=9 }) {
  const src = user?.profile_picture ? (user.profile_picture.startsWith('http') ? user.profile_picture : `${BASE}${user.profile_picture}`) : null
  const cls = `w-${size} h-${size} rounded-full object-cover`
  return src ? <img src={src} alt="" className={cls}/> : <div className={`${cls} bg-campus-500/20 flex items-center justify-center text-campus-400 font-bold text-sm`}>{user?.name?.[0]?.toUpperCase()||'?'}</div>
}
export default function PostCard({ post, onDeleted }) {
  const { user } = useAuth()
  const [liked, setLiked] = useState(post.is_liked_by_me)
  const [likes, setLikes] = useState(post.likes_count)
  const [showComments, setShowComments] = useState(false)
  const [comments, setComments] = useState([])
  const [commentText, setCommentText] = useState('')
  const [loadingC, setLoadingC] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [menu, setMenu] = useState(false)
  const isOwn = user?.id === post.author?.id
  const imgUrl = post.image_url ? (post.image_url.startsWith('http') ? post.image_url : `${BASE}${post.image_url}`) : null
  const handleLike = async () => {
    try {
      if (liked) { await postsAPI.unlike(post.id); setLiked(false); setLikes(c=>c-1) }
      else { await postsAPI.like(post.id); setLiked(true); setLikes(c=>c+1) }
    } catch(e) { toast.error(e.response?.data?.detail||'Action failed') }
  }
  const toggleComments = async () => {
    if (!showComments && comments.length===0) { setLoadingC(true); try { const r = await commentsAPI.get(post.id); setComments(r.data) } catch{} setLoadingC(false) }
    setShowComments(v=>!v)
  }
  const submitComment = async () => {
    if (!commentText.trim()) return; setSubmitting(true)
    try { const r = await commentsAPI.add(post.id, commentText.trim()); setComments(c=>[...c,r.data]); setCommentText('') }
    catch(e) { toast.error(e.response?.data?.detail||'Failed') }
    setSubmitting(false)
  }
  return (
    <article className="card p-5 animate-fade-in">
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-3">
          {post.is_anonymous ? <div className="w-9 h-9 rounded-full bg-surface-hover flex items-center justify-center text-gray-500"><Ghost size={18}/></div> : <Avatar user={post.author}/>}
          <div>
            <p className="text-sm font-semibold">{post.is_anonymous ? 'Anonymous' : (post.author?.name||'Unknown')}</p>
            <p className="text-xs text-gray-500">{formatDistanceToNow(new Date(post.created_at),{addSuffix:true})}</p>
          </div>
          {post.is_anonymous && <span className="text-[10px] bg-gray-700/60 text-gray-400 px-2 py-0.5 rounded-full">anon</span>}
        </div>
        <div className="relative">
          <button onClick={()=>setMenu(v=>!v)} className="p-1.5 text-gray-500 hover:text-white hover:bg-surface-hover rounded-lg transition-all"><MoreHorizontal size={16}/></button>
          {menu && (
            <div className="absolute right-0 top-8 bg-surface-card border border-surface-border rounded-xl shadow-xl z-20 py-1 w-40 animate-fade-in">
              <button onClick={()=>setMenu(false)} className="absolute top-2 right-2 text-gray-500 hover:text-white"><X size={12}/></button>
              {isOwn && <button onClick={async()=>{setMenu(false);try{await postsAPI.delete(post.id);toast.success('Deleted');onDeleted?.(post.id)}catch(e){toast.error(e.response?.data?.detail||'Failed')}}} className="w-full flex items-center gap-2 px-4 py-2 text-sm text-red-400 hover:bg-red-400/10 transition-colors"><Trash2 size={14}/>Delete</button>}
              <button onClick={async()=>{setMenu(false);try{await postsAPI.report(post.id,'Inappropriate');toast.success('Reported!')}catch(e){toast.error(e.response?.data?.detail||'Failed')}}} className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-400 hover:bg-surface-hover transition-colors"><Flag size={14}/>Report</button>
            </div>
          )}
        </div>
      </div>
      <p className="text-gray-200 leading-relaxed text-sm mb-3 whitespace-pre-wrap">{post.content}</p>
      {imgUrl && <div className="mb-3 rounded-xl overflow-hidden"><img src={imgUrl} alt="Post" className="w-full max-h-96 object-cover"/></div>}
      <div className="flex items-center gap-4 pt-3 border-t border-surface-border">
        <button onClick={handleLike} className={`flex items-center gap-1.5 text-sm font-medium transition-all ${liked?'text-rose-400':'text-gray-500 hover:text-rose-400'}`}><Heart size={16} className={liked?'fill-rose-400':''}/>{likes}</button>
        <button onClick={toggleComments} className="flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-campus-400 transition-colors"><MessageCircle size={16}/>{post.comments_count}</button>
      </div>
      {showComments && (
        <div className="mt-4 pt-4 border-t border-surface-border space-y-3 animate-fade-in">
          {loadingC && <p className="text-xs text-gray-500 text-center py-2">Loading…</p>}
          {comments.map(c=>(
            <div key={c.id} className="flex gap-2.5">
              <Avatar user={c.author} size={7}/>
              <div className="flex-1 bg-surface-hover rounded-xl px-3 py-2">
                <p className="text-xs font-semibold text-campus-300 mb-0.5">{c.author?.name}</p>
                <p className="text-sm text-gray-300">{c.content}</p>
              </div>
            </div>
          ))}
          {!loadingC && comments.length===0 && <p className="text-xs text-gray-600 text-center py-2">No comments yet. Be first!</p>}
          <div className="flex gap-2 pt-1">
            <Avatar user={user} size={7}/>
            <input value={commentText} onChange={e=>setCommentText(e.target.value)} onKeyDown={e=>e.key==='Enter'&&!e.shiftKey&&submitComment()} placeholder="Write a comment…" className="flex-1 bg-surface-hover border border-surface-border rounded-xl px-3 py-2 text-sm text-white placeholder-gray-600 focus:outline-none focus:border-campus-500"/>
            <button onClick={submitComment} disabled={submitting||!commentText.trim()} className="btn-primary text-xs px-3 py-2 disabled:opacity-40">{submitting?'…':'Post'}</button>
          </div>
        </div>
      )}
    </article>
  )
}
EOF

# ── src/components/CreatePostModal.jsx ───────────────────────────────────────
cat > "$FRONT/src/components/CreatePostModal.jsx" << 'EOF'
import { useState, useRef } from 'react'
import { X, Image as Img, Ghost, Loader2 } from 'lucide-react'
import { postsAPI } from '../services/api'
import { useAuth } from '../context/AuthContext'
import toast from 'react-hot-toast'
const BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000'
export default function CreatePostModal({ onClose, onCreated }) {
  const { user } = useAuth()
  const [content, setContent] = useState('')
  const [isAnon, setIsAnon] = useState(false)
  const [image, setImage] = useState(null)
  const [preview, setPreview] = useState(null)
  const [submitting, setSubmitting] = useState(false)
  const fileRef = useRef()
  const src = user?.profile_picture ? (user.profile_picture.startsWith('http') ? user.profile_picture : `${BASE}${user.profile_picture}`) : null
  const handleSubmit = async () => {
    if (!content.trim()) return toast.error('Write something first!')
    setSubmitting(true)
    try {
      const fd = new FormData(); fd.append('content',content.trim()); fd.append('is_anonymous',isAnon)
      if (image) fd.append('image',image)
      await postsAPI.create(fd); toast.success('Post published! 🎉'); onCreated?.(); onClose()
    } catch(e) { toast.error(e.response?.data?.detail||'Failed') }
    setSubmitting(false)
  }
  return (
    <div className="fixed inset-0 z-50 flex items-end md:items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
      <div className="w-full max-w-lg bg-surface-card border border-surface-border rounded-2xl shadow-2xl animate-slide-up">
        <div className="flex items-center justify-between px-5 py-4 border-b border-surface-border">
          <h2 className="font-display font-bold text-white">New Post</h2>
          <button onClick={onClose} className="p-1.5 text-gray-500 hover:text-white hover:bg-surface-hover rounded-lg transition-all"><X size={18}/></button>
        </div>
        <div className="p-5 space-y-4">
          <div className="flex gap-3">
            <div className="flex-shrink-0">
              {isAnon ? <div className="w-10 h-10 rounded-full bg-surface-hover flex items-center justify-center text-gray-500"><Ghost size={20}/></div>
                : src ? <img src={src} alt="" className="w-10 h-10 rounded-full object-cover"/>
                : <div className="w-10 h-10 rounded-full bg-campus-500/20 flex items-center justify-center text-campus-400 font-bold">{user?.name?.[0]?.toUpperCase()}</div>}
            </div>
            <textarea className="flex-1 bg-transparent text-white placeholder-gray-600 resize-none focus:outline-none text-sm leading-relaxed" rows={4} placeholder="What's on your mind?" value={content} onChange={e=>setContent(e.target.value)} maxLength={2000} autoFocus/>
          </div>
          {preview && <div className="relative rounded-xl overflow-hidden"><img src={preview} alt="" className="w-full max-h-56 object-cover"/><button onClick={()=>{setImage(null);setPreview(null)}} className="absolute top-2 right-2 bg-black/60 text-white p-1.5 rounded-full hover:bg-black/80"><X size={14}/></button></div>}
          <div className="flex items-center justify-between pt-2 border-t border-surface-border">
            <div className="flex items-center gap-2">
              <button onClick={()=>fileRef.current?.click()} className="flex items-center gap-1.5 text-xs text-gray-500 hover:text-campus-400 px-3 py-2 rounded-xl hover:bg-campus-500/10 transition-all"><Img size={16}/>Photo</button>
              <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={e=>{const f=e.target.files[0];if(f){setImage(f);setPreview(URL.createObjectURL(f))}}}/>
              <button onClick={()=>setIsAnon(v=>!v)} className={`flex items-center gap-1.5 text-xs px-3 py-2 rounded-xl transition-all ${isAnon?'bg-campus-500/20 text-campus-400 border border-campus-500/30':'text-gray-500 hover:text-campus-400 hover:bg-campus-500/10'}`}><Ghost size={16}/>{isAnon?'Anon ON':'Anon'}</button>
            </div>
            <button onClick={handleSubmit} disabled={submitting||!content.trim()} className="btn-primary text-sm px-5 py-2 flex items-center gap-2">
              {submitting&&<Loader2 size={14} className="animate-spin"/>}{submitting?'Posting…':'Post'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
EOF

# ── src/components/PollCard.jsx ───────────────────────────────────────────────
cat > "$FRONT/src/components/PollCard.jsx" << 'EOF'
import { useState } from 'react'
import { formatDistanceToNow } from 'date-fns'
import { BarChart2, CheckCircle2 } from 'lucide-react'
import { pollsAPI } from '../services/api'
import toast from 'react-hot-toast'
export default function PollCard({ poll:init }) {
  const [poll, setPoll] = useState(init)
  const [voting, setVoting] = useState(false)
  const hasVoted = poll.my_vote_option_id != null
  const total = poll.total_votes || 1
  const handleVote = async (oid) => {
    if (hasVoted||voting) return; setVoting(true)
    try { await pollsAPI.vote(poll.id,oid); const r = await pollsAPI.get(poll.id); setPoll(r.data); toast.success('Voted!') }
    catch(e) { toast.error(e.response?.data?.detail||'Failed') }
    setVoting(false)
  }
  return (
    <article className="card p-5 animate-fade-in">
      <div className="flex items-start gap-3 mb-4">
        <div className="w-8 h-8 rounded-xl bg-campus-500/20 flex items-center justify-center flex-shrink-0"><BarChart2 size={16} className="text-campus-400"/></div>
        <div><p className="text-sm font-semibold text-white leading-snug">{poll.question}</p><p className="text-xs text-gray-500 mt-0.5">{poll.total_votes} votes · {formatDistanceToNow(new Date(poll.created_at),{addSuffix:true})}</p></div>
      </div>
      <div className="space-y-2">
        {poll.options.map(opt => {
          const pct = Math.round((opt.votes_count/total)*100)
          const mine = poll.my_vote_option_id===opt.id
          return (
            <button key={opt.id} onClick={()=>handleVote(opt.id)} disabled={hasVoted||voting} className={`w-full relative overflow-hidden rounded-xl border text-left transition-all ${hasVoted?(mine?'border-campus-500/60 bg-campus-500/10':'border-surface-border bg-surface-hover'):'border-surface-border bg-surface-hover hover:border-campus-400/50 hover:bg-campus-500/5'} cursor-${hasVoted?'default':'pointer'}`}>
              {hasVoted && <div className="absolute inset-y-0 left-0 h-full" style={{width:`${pct}%`,background:mine?'rgba(99,102,241,0.15)':'rgba(255,255,255,0.03)',transition:'width .6s ease'}}/>}
              <div className="relative flex items-center justify-between px-4 py-3">
                <div className="flex items-center gap-2">{mine&&<CheckCircle2 size={14} className="text-campus-400"/>}<span className={`text-sm font-medium ${mine?'text-campus-300':'text-gray-300'}`}>{opt.option_text}</span></div>
                {hasVoted && <span className={`text-xs font-bold font-mono ${mine?'text-campus-400':'text-gray-500'}`}>{pct}%</span>}
              </div>
            </button>
          )
        })}
      </div>
    </article>
  )
}
EOF

# ── src/components/CreatePollModal.jsx ───────────────────────────────────────
cat > "$FRONT/src/components/CreatePollModal.jsx" << 'EOF'
import { useState } from 'react'
import { X, Plus, Trash2, Loader2 } from 'lucide-react'
import { pollsAPI } from '../services/api'
import toast from 'react-hot-toast'
export default function CreatePollModal({ onClose, onCreated }) {
  const [question, setQuestion] = useState('')
  const [options, setOptions] = useState(['',''])
  const [submitting, setSubmitting] = useState(false)
  const handleSubmit = async () => {
    if (!question.trim()) return toast.error('Enter a question')
    const filled = options.filter(o=>o.trim())
    if (filled.length<2) return toast.error('Add at least 2 options')
    setSubmitting(true)
    try { await pollsAPI.create({question:question.trim(),options:filled}); toast.success('Poll created!'); onCreated?.(); onClose() }
    catch(e) { toast.error(e.response?.data?.detail||'Failed') }
    setSubmitting(false)
  }
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
      <div className="w-full max-w-md bg-surface-card border border-surface-border rounded-2xl shadow-2xl animate-slide-up">
        <div className="flex items-center justify-between px-5 py-4 border-b border-surface-border">
          <h2 className="font-display font-bold text-white">Create Poll</h2>
          <button onClick={onClose} className="p-1.5 text-gray-500 hover:text-white hover:bg-surface-hover rounded-lg transition-all"><X size={18}/></button>
        </div>
        <div className="p-5 space-y-4">
          <div><label className="label">Question</label><input className="input" placeholder="Ask your campus…" value={question} onChange={e=>setQuestion(e.target.value)} maxLength={300}/></div>
          <div><label className="label">Options</label>
            <div className="space-y-2">
              {options.map((opt,i)=>(
                <div key={i} className="flex gap-2">
                  <input className="input flex-1" placeholder={`Option ${i+1}`} value={opt} onChange={e=>setOptions(o=>o.map((v,idx)=>idx===i?e.target.value:v))} maxLength={200}/>
                  {options.length>2 && <button onClick={()=>setOptions(o=>o.filter((_,idx)=>idx!==i))} className="p-2.5 text-gray-600 hover:text-red-400 hover:bg-red-400/10 rounded-xl transition-all"><Trash2 size={16}/></button>}
                </div>
              ))}
            </div>
            {options.length<6 && <button onClick={()=>setOptions(o=>[...o,''])} className="mt-2 flex items-center gap-1.5 text-xs text-campus-400 hover:text-campus-300 font-medium"><Plus size={14}/>Add option</button>}
          </div>
        </div>
        <div className="px-5 pb-5 flex justify-end gap-3">
          <button onClick={onClose} className="btn-ghost text-sm">Cancel</button>
          <button onClick={handleSubmit} disabled={submitting} className="btn-primary text-sm flex items-center gap-2">{submitting&&<Loader2 size={14} className="animate-spin"/>}Create Poll</button>
        </div>
      </div>
    </div>
  )
}
EOF

# ── pages ─────────────────────────────────────────────────────────────────────
cat > "$FRONT/src/pages/Login.jsx" << 'EOF'
import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { GraduationCap, Eye, EyeOff, Loader2 } from 'lucide-react'
import { authAPI } from '../services/api'
import { useAuth } from '../context/AuthContext'
import toast from 'react-hot-toast'
export default function Login() {
  const { login } = useAuth(); const navigate = useNavigate()
  const [form, setForm] = useState({ email:'', password:'' })
  const [show, setShow] = useState(false); const [loading, setLoading] = useState(false)
  const set = k => e => setForm(f=>({...f,[k]:e.target.value}))
  const handleSubmit = async e => {
    e.preventDefault(); setLoading(true)
    try { const r = await authAPI.login(form); login(r.data.access_token,r.data.user); toast.success(`Welcome back, ${r.data.user.name}! 👋`); navigate('/feed') }
    catch(err) { toast.error(err.response?.data?.detail||'Login failed') }
    setLoading(false)
  }
  return (
    <div className="min-h-screen flex items-center justify-center p-6">
      <div className="w-full max-w-sm">
        <div className="flex items-center gap-2.5 mb-8"><div className="w-10 h-10 bg-campus-500 rounded-xl flex items-center justify-center"><GraduationCap size={22} className="text-white"/></div><span className="font-display font-bold text-xl">Campus<span className="text-campus-400">Connect</span></span></div>
        <h1 className="font-display font-bold text-2xl mb-1">Welcome back</h1>
        <p className="text-gray-500 text-sm mb-8">Sign in to your campus account</p>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div><label className="label">University Email</label><input className="input" type="email" placeholder="you@gla.ac.in" value={form.email} onChange={set('email')} required/></div>
          <div><label className="label">Password</label>
            <div className="relative"><input className="input pr-11" type={show?'text':'password'} placeholder="Your password" value={form.password} onChange={set('password')} required/>
              <button type="button" onClick={()=>setShow(v=>!v)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-300">{show?<EyeOff size={16}/>:<Eye size={16}/>}</button>
            </div>
          </div>
          <button type="submit" disabled={loading} className="btn-primary w-full py-3 flex items-center justify-center gap-2">{loading&&<Loader2 size={16} className="animate-spin"/>}{loading?'Signing in…':'Sign In'}</button>
        </form>
        <p className="text-center text-sm text-gray-500 mt-6">New here? <Link to="/signup" className="text-campus-400 hover:text-campus-300 font-medium">Create account</Link></p>
      </div>
    </div>
  )
}
EOF

cat > "$FRONT/src/pages/Signup.jsx" << 'EOF'
import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { GraduationCap, Eye, EyeOff, Loader2, AlertCircle } from 'lucide-react'
import { authAPI } from '../services/api'
import toast from 'react-hot-toast'
export default function Signup() {
  const navigate = useNavigate()
  const [form, setForm] = useState({ name:'', email:'', password:'' })
  const [show, setShow] = useState(false); const [loading, setLoading] = useState(false); const [error, setError] = useState('')
  const set = k => e => { setError(''); setForm(f=>({...f,[k]:e.target.value})) }
  const handleSubmit = async e => {
    e.preventDefault(); setError('')
    if (!form.email.endsWith('@gla.ac.in')) return setError('Only @gla.ac.in emails are allowed.')
    if (form.password.length<6) return setError('Password must be at least 6 characters.')
    setLoading(true)
    try { await authAPI.signup(form); toast.success('Account created! Check your email for the OTP.'); navigate('/verify',{state:{email:form.email}}) }
    catch(err) { setError(err.response?.data?.detail||'Signup failed.') }
    setLoading(false)
  }
  return (
    <div className="min-h-screen flex items-center justify-center p-6">
      <div className="w-full max-w-sm">
        <div className="flex items-center gap-2.5 mb-8"><div className="w-10 h-10 bg-campus-500 rounded-xl flex items-center justify-center"><GraduationCap size={22} className="text-white"/></div><span className="font-display font-bold text-xl">Campus<span className="text-campus-400">Connect</span></span></div>
        <h1 className="font-display font-bold text-2xl mb-1">Create your account</h1>
        <p className="text-gray-500 text-sm mb-8">Join your campus community</p>
        {error && <div className="flex items-start gap-2.5 bg-red-500/10 border border-red-500/30 rounded-xl px-4 py-3 mb-5"><AlertCircle size={16} className="text-red-400 flex-shrink-0 mt-0.5"/><p className="text-sm text-red-400">{error}</p></div>}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div><label className="label">Full Name</label><input className="input" type="text" placeholder="Your full name" value={form.name} onChange={set('name')} required/></div>
          <div><label className="label">University Email</label><input className="input" type="email" placeholder="you@gla.ac.in" value={form.email} onChange={set('email')} required/><p className="text-xs text-gray-600 mt-1.5">Only @gla.ac.in emails accepted</p></div>
          <div><label className="label">Password</label>
            <div className="relative"><input className="input pr-11" type={show?'text':'password'} placeholder="Min. 6 characters" value={form.password} onChange={set('password')} required/>
              <button type="button" onClick={()=>setShow(v=>!v)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-300">{show?<EyeOff size={16}/>:<Eye size={16}/>}</button>
            </div>
          </div>
          <button type="submit" disabled={loading} className="btn-primary w-full py-3 flex items-center justify-center gap-2">{loading&&<Loader2 size={16} className="animate-spin"/>}{loading?'Creating…':'Create Account'}</button>
        </form>
        <p className="text-center text-sm text-gray-500 mt-6">Already have an account? <Link to="/login" className="text-campus-400 hover:text-campus-300 font-medium">Sign in</Link></p>
      </div>
    </div>
  )
}
EOF

cat > "$FRONT/src/pages/Verify.jsx" << 'EOF'
import { useState, useRef, useEffect } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { GraduationCap, Loader2, RefreshCw } from 'lucide-react'
import { authAPI } from '../services/api'
import { useAuth } from '../context/AuthContext'
import toast from 'react-hot-toast'
export default function Verify() {
  const { login } = useAuth(); const navigate = useNavigate(); const location = useLocation()
  const email = location.state?.email || ''
  const [otp, setOtp] = useState(['','','','','',''])
  const [loading, setLoading] = useState(false); const [resending, setResending] = useState(false); const [cooldown, setCooldown] = useState(0)
  const refs = useRef([])
  useEffect(() => { if (cooldown<=0) return; const t = setTimeout(()=>setCooldown(c=>c-1),1000); return ()=>clearTimeout(t) }, [cooldown])
  const handleChange = (i,val) => { if (!/^\d?$/.test(val)) return; const n=[...otp]; n[i]=val; setOtp(n); if(val&&i<5) refs.current[i+1]?.focus() }
  const handleKeyDown = (i,e) => { if(e.key==='Backspace'&&!otp[i]&&i>0) refs.current[i-1]?.focus() }
  const handlePaste = e => { e.preventDefault(); const p=e.clipboardData.getData('text').replace(/\D/g,'').slice(0,6); const n=[...otp]; p.split('').forEach((c,i)=>{n[i]=c}); setOtp(n); refs.current[Math.min(p.length,5)]?.focus() }
  const handleSubmit = async e => {
    e.preventDefault(); const code=otp.join('')
    if(code.length<6) return toast.error('Enter the full 6-digit OTP')
    if(!email) return toast.error('Email not found. Please sign up again.')
    setLoading(true)
    try { const r=await authAPI.verifyOTP({email,otp:code}); login(r.data.access_token,r.data.user); toast.success('Email verified! Welcome 🎓'); navigate('/feed') }
    catch(err) { toast.error(err.response?.data?.detail||'Invalid OTP'); setOtp(['','','','','','']); refs.current[0]?.focus() }
    setLoading(false)
  }
  const handleResend = async () => {
    if(!email||cooldown>0) return; setResending(true)
    try { await authAPI.resendOTP(email); toast.success('New OTP sent!'); setCooldown(60) }
    catch(err) { toast.error(err.response?.data?.detail||'Failed') }
    setResending(false)
  }
  return (
    <div className="min-h-screen flex items-center justify-center p-6">
      <div className="w-full max-w-sm text-center">
        <div className="w-16 h-16 bg-campus-500/20 rounded-2xl flex items-center justify-center mx-auto mb-6"><GraduationCap size={32} className="text-campus-400"/></div>
        <h1 className="font-display font-bold text-2xl mb-2">Verify your email</h1>
        <p className="text-gray-500 text-sm mb-2">We sent a 6-digit OTP to</p>
        <p className="text-campus-400 font-medium text-sm mb-8 break-all">{email||'your email'}</p>
        <form onSubmit={handleSubmit}>
          <div className="flex gap-2.5 justify-center mb-6" onPaste={handlePaste}>
            {otp.map((digit,i)=>(
              <input key={i} ref={el=>refs.current[i]=el} type="text" inputMode="numeric" maxLength={1} value={digit} onChange={e=>handleChange(i,e.target.value)} onKeyDown={e=>handleKeyDown(i,e)} className={`w-12 h-14 text-center text-xl font-bold font-mono rounded-xl border bg-surface-hover text-white focus:outline-none focus:border-campus-500 focus:ring-1 focus:ring-campus-500 transition-all ${digit?'border-campus-500/60':'border-surface-border'}`}/>
            ))}
          </div>
          <button type="submit" disabled={loading||otp.join('').length<6} className="btn-primary w-full py-3 flex items-center justify-center gap-2 mb-4">{loading&&<Loader2 size={16} className="animate-spin"/>}{loading?'Verifying…':'Verify Email'}</button>
        </form>
        <button onClick={handleResend} disabled={resending||cooldown>0} className="flex items-center gap-2 text-sm text-gray-500 hover:text-campus-400 transition-colors mx-auto disabled:opacity-50">
          <RefreshCw size={14} className={resending?'animate-spin':''}/>{cooldown>0?`Resend in ${cooldown}s`:'Resend OTP'}
        </button>
        <p className="text-xs text-gray-600 mt-6">💡 In dev mode, OTP is printed in the backend terminal.</p>
      </div>
    </div>
  )
}
EOF

cat > "$FRONT/src/pages/Feed.jsx" << 'EOF'
import { useState, useEffect, useCallback } from 'react'
import { Plus, Loader2, RefreshCw } from 'lucide-react'
import Layout from '../components/Layout'
import PostCard from '../components/PostCard'
import CreatePostModal from '../components/CreatePostModal'
import { postsAPI } from '../services/api'
import toast from 'react-hot-toast'
export default function Feed() {
  const [posts, setPosts] = useState([]); const [page, setPage] = useState(1); const [hasMore, setHasMore] = useState(true)
  const [loading, setLoading] = useState(true); const [loadingMore, setLoadingMore] = useState(false); const [showCreate, setShowCreate] = useState(false)
  const fetchPosts = useCallback(async (p=1, replace=false) => {
    if(p===1) setLoading(true); else setLoadingMore(true)
    try { const r=await postsAPI.getFeed(p); const n=r.data; setPosts(prev=>replace?n:[...prev,...n]); setHasMore(n.length===10); setPage(p) }
    catch { toast.error('Failed to load feed') }
    setLoading(false); setLoadingMore(false)
  }, [])
  useEffect(()=>{ fetchPosts(1,true) },[fetchPosts])
  return (
    <Layout>
      <div className="flex items-center justify-between mb-6">
        <div><h1 className="font-display font-bold text-xl">Campus Feed</h1><p className="text-xs text-gray-500 mt-0.5">What's happening on campus</p></div>
        <div className="flex items-center gap-2">
          <button onClick={()=>fetchPosts(1,true)} className="p-2.5 text-gray-500 hover:text-white hover:bg-surface-hover rounded-xl transition-all"><RefreshCw size={16}/></button>
          <button onClick={()=>setShowCreate(true)} className="btn-primary flex items-center gap-2 text-sm px-4 py-2.5"><Plus size={16}/>New Post</button>
        </div>
      </div>
      {loading ? <div className="flex items-center justify-center py-16"><Loader2 size={28} className="animate-spin text-campus-400"/></div>
        : posts.length===0 ? <div className="text-center py-20"><p className="text-4xl mb-3">🎓</p><p className="text-gray-400 font-medium">No posts yet</p><p className="text-gray-600 text-sm mt-1">Be the first to share!</p><button onClick={()=>setShowCreate(true)} className="btn-primary mt-4 text-sm">Create First Post</button></div>
        : <div className="space-y-4">
            {posts.map(p=><PostCard key={p.id} post={p} onDeleted={id=>setPosts(prev=>prev.filter(x=>x.id!==id))}/>)}
            {hasMore && <div className="flex justify-center pt-2 pb-4"><button onClick={()=>fetchPosts(page+1)} disabled={loadingMore} className="btn-ghost flex items-center gap-2 text-sm">{loadingMore&&<Loader2 size={14} className="animate-spin"/>}{loadingMore?'Loading…':'Load more'}</button></div>}
            {!hasMore&&posts.length>0&&<p className="text-center text-xs text-gray-600 py-4">You've seen it all! 🎉</p>}
          </div>
      }
      {showCreate && <CreatePostModal onClose={()=>setShowCreate(false)} onCreated={()=>fetchPosts(1,true)}/>}
    </Layout>
  )
}
EOF

cat > "$FRONT/src/pages/Trending.jsx" << 'EOF'
import { useState, useEffect } from 'react'
import { Loader2, Flame } from 'lucide-react'
import Layout from '../components/Layout'
import PostCard from '../components/PostCard'
import { postsAPI } from '../services/api'
import toast from 'react-hot-toast'
export default function Trending() {
  const [posts, setPosts] = useState([]); const [loading, setLoading] = useState(true)
  useEffect(()=>{ postsAPI.getTrending().then(r=>setPosts(r.data)).catch(()=>toast.error('Failed')).finally(()=>setLoading(false)) },[])
  return (
    <Layout>
      <div className="flex items-center gap-3 mb-6"><div className="w-9 h-9 bg-orange-500/20 rounded-xl flex items-center justify-center"><Flame size={18} className="text-orange-400"/></div><div><h1 className="font-display font-bold text-xl">Trending</h1><p className="text-xs text-gray-500 mt-0.5">Most liked posts in last 7 days</p></div></div>
      {loading ? <div className="flex items-center justify-center py-16"><Loader2 size={28} className="animate-spin text-campus-400"/></div>
        : posts.length===0 ? <div className="text-center py-20"><p className="text-4xl mb-3">🔥</p><p className="text-gray-400 font-medium">Nothing trending yet</p></div>
        : <div className="space-y-4">{posts.map((p,i)=><div key={p.id} className="relative">{i<3&&<div className={`absolute -left-3 -top-2 z-10 w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold ${i===0?'bg-yellow-400 text-yellow-900':i===1?'bg-gray-300 text-gray-800':'bg-orange-400 text-orange-900'}`}>{i+1}</div>}<PostCard post={p} onDeleted={id=>setPosts(prev=>prev.filter(x=>x.id!==id))}/></div>)}</div>
      }
    </Layout>
  )
}
EOF

cat > "$FRONT/src/pages/Polls.jsx" << 'EOF'
import { useState, useEffect } from 'react'
import { BarChart2, Plus, Loader2 } from 'lucide-react'
import Layout from '../components/Layout'
import PollCard from '../components/PollCard'
import CreatePollModal from '../components/CreatePollModal'
import { pollsAPI } from '../services/api'
import toast from 'react-hot-toast'
export default function Polls() {
  const [polls, setPolls] = useState([]); const [loading, setLoading] = useState(true); const [showCreate, setShowCreate] = useState(false)
  const fetch = () => { setLoading(true); pollsAPI.getAll().then(r=>setPolls(r.data)).catch(()=>toast.error('Failed')).finally(()=>setLoading(false)) }
  useEffect(()=>fetch(),[])
  return (
    <Layout>
      <div className="flex items-center justify-between mb-6"><div className="flex items-center gap-3"><div className="w-9 h-9 bg-campus-500/20 rounded-xl flex items-center justify-center"><BarChart2 size={18} className="text-campus-400"/></div><div><h1 className="font-display font-bold text-xl">Campus Polls</h1><p className="text-xs text-gray-500 mt-0.5">Vote and see what campus thinks</p></div></div><button onClick={()=>setShowCreate(true)} className="btn-primary flex items-center gap-2 text-sm px-4 py-2.5"><Plus size={16}/>New Poll</button></div>
      {loading ? <div className="flex items-center justify-center py-16"><Loader2 size={28} className="animate-spin text-campus-400"/></div>
        : polls.length===0 ? <div className="text-center py-20"><p className="text-4xl mb-3">📊</p><p className="text-gray-400 font-medium">No polls yet</p><button onClick={()=>setShowCreate(true)} className="btn-primary mt-4 text-sm">Create First Poll</button></div>
        : <div className="space-y-4">{polls.map(p=><PollCard key={p.id} poll={p}/>)}</div>
      }
      {showCreate&&<CreatePollModal onClose={()=>setShowCreate(false)} onCreated={fetch}/>}
    </Layout>
  )
}
EOF

cat > "$FRONT/src/pages/Notifications.jsx" << 'EOF'
import { useState, useEffect } from 'react'
import { Bell, Heart, MessageCircle, Loader2, CheckCheck } from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'
import Layout from '../components/Layout'
import { notificationsAPI } from '../services/api'
import toast from 'react-hot-toast'
const BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000'
export default function Notifications() {
  const [notifications, setNotifications] = useState([]); const [loading, setLoading] = useState(true)
  useEffect(()=>{ notificationsAPI.getAll().then(r=>setNotifications(r.data)).catch(()=>toast.error('Failed')).finally(()=>setLoading(false)) },[])
  const markAll = async () => { try { await notificationsAPI.markAllRead(); setNotifications(n=>n.map(x=>({...x,is_read:true}))); toast.success('All read') } catch { toast.error('Failed') } }
  const unread = notifications.filter(n=>!n.is_read).length
  return (
    <Layout>
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3"><div className="w-9 h-9 bg-campus-500/20 rounded-xl flex items-center justify-center relative"><Bell size={18} className="text-campus-400"/>{unread>0&&<span className="absolute -top-1 -right-1 bg-campus-500 text-white text-[9px] font-bold w-4 h-4 rounded-full flex items-center justify-center">{unread>9?'9+':unread}</span>}</div><div><h1 className="font-display font-bold text-xl">Notifications</h1><p className="text-xs text-gray-500 mt-0.5">{unread} unread</p></div></div>
        {unread>0&&<button onClick={markAll} className="btn-ghost flex items-center gap-2 text-sm"><CheckCheck size={14}/>Mark all read</button>}
      </div>
      {loading ? <div className="flex items-center justify-center py-16"><Loader2 size={28} className="animate-spin text-campus-400"/></div>
        : notifications.length===0 ? <div className="text-center py-20"><p className="text-4xl mb-3">🔔</p><p className="text-gray-400 font-medium">No notifications yet</p></div>
        : <div className="space-y-2">{notifications.map(n=>{
            const src = n.sender?.profile_picture ? (n.sender.profile_picture.startsWith('http')?n.sender.profile_picture:`${BASE}${n.sender.profile_picture}`) : null
            return (
              <button key={n.id} onClick={()=>!n.is_read&&notificationsAPI.markRead(n.id).then(()=>setNotifications(x=>x.map(i=>i.id===n.id?{...i,is_read:true}:i))).catch(()=>{})} className={`w-full card px-4 py-3.5 flex items-center gap-3 text-left transition-all hover:border-surface-hover ${!n.is_read?'border-campus-500/30 bg-campus-500/5':''}`}>
                <div className="relative flex-shrink-0">{src?<img src={src} alt="" className="w-9 h-9 rounded-full object-cover"/>:<div className="w-9 h-9 rounded-full bg-campus-500/20 flex items-center justify-center text-campus-400 font-bold text-sm">{n.sender?.name?.[0]?.toUpperCase()||'?'}</div>}<span className="absolute -bottom-0.5 -right-0.5 bg-surface-card rounded-full p-0.5">{n.type==='like'?<Heart size={12} className="text-rose-400"/>:<MessageCircle size={12} className="text-campus-400"/>}</span></div>
                <div className="flex-1 min-w-0"><p className={`text-sm leading-snug ${!n.is_read?'text-white font-medium':'text-gray-300'}`}>{n.message}</p><p className="text-xs text-gray-600 mt-0.5">{formatDistanceToNow(new Date(n.created_at),{addSuffix:true})}</p></div>
                {!n.is_read&&<div className="w-2 h-2 rounded-full bg-campus-400 flex-shrink-0"/>}
              </button>
            )
          })}</div>
      }
    </Layout>
  )
}
EOF

cat > "$FRONT/src/pages/Profile.jsx" << 'EOF'
import { useState, useEffect, useRef } from 'react'
import { useParams } from 'react-router-dom'
import { Edit2, Camera, Loader2, LogOut, CheckCircle } from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'
import Layout from '../components/Layout'
import PostCard from '../components/PostCard'
import { authAPI, postsAPI } from '../services/api'
import { useAuth } from '../context/AuthContext'
import toast from 'react-hot-toast'
const BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000'
export default function Profile() {
  const { id } = useParams(); const { user:me, logout, refreshUser } = useAuth()
  const isOwn = !id || parseInt(id)===me?.id
  const [profile, setProfile] = useState(isOwn?me:null)
  const [posts, setPosts] = useState([]); const [loading, setLoading] = useState(true)
  const [editMode, setEditMode] = useState(false); const [editForm, setEditForm] = useState({name:'',bio:''})
  const [saving, setSaving] = useState(false); const [uploadingAvatar, setUploadingAvatar] = useState(false)
  const fileRef = useRef()
  useEffect(()=>{
    const uid = isOwn?me?.id:id; if(!uid) return
    if(isOwn) authAPI.me().then(r=>{setProfile(r.data)}).catch(()=>{})
    postsAPI.getUserPosts(uid).then(r=>setPosts(r.data)).catch(()=>toast.error('Failed')).finally(()=>setLoading(false))
  },[id,me?.id,isOwn])
  const handleSave = async () => {
    setSaving(true)
    try { const r=await authAPI.updateProfile({name:editForm.name||undefined,bio:editForm.bio}); await refreshUser(); setProfile(r.data); setEditMode(false); toast.success('Updated!') }
    catch(e) { toast.error(e.response?.data?.detail||'Failed') }
    setSaving(false)
  }
  const handleAvatar = async e => {
    const file=e.target.files[0]; if(!file) return; setUploadingAvatar(true)
    const fd=new FormData(); fd.append('file',file)
    try { const r=await authAPI.uploadAvatar(fd); await refreshUser(); setProfile(r.data); toast.success('Avatar updated!') }
    catch(e) { toast.error(e.response?.data?.detail||'Failed') }
    setUploadingAvatar(false)
  }
  const pu = isOwn?(profile||me):profile
  const src = pu?.profile_picture?(pu.profile_picture.startsWith('http')?pu.profile_picture:`${BASE}${pu.profile_picture}`):null
  if(!pu&&loading) return <Layout><div className="flex items-center justify-center py-20"><Loader2 size={28} className="animate-spin text-campus-400"/></div></Layout>
  return (
    <Layout>
      <div className="card p-6 mb-6">
        <div className="flex items-start gap-5">
          <div className="relative flex-shrink-0">
            {src?<img src={src} alt="" className="w-20 h-20 rounded-2xl object-cover ring-2 ring-surface-border"/>:<div className="w-20 h-20 rounded-2xl bg-campus-500/20 flex items-center justify-center text-campus-400 font-bold text-2xl ring-2 ring-surface-border">{pu?.name?.[0]?.toUpperCase()}</div>}
            {isOwn&&<><button onClick={()=>fileRef.current?.click()} disabled={uploadingAvatar} className="absolute -bottom-2 -right-2 w-8 h-8 bg-campus-500 rounded-xl flex items-center justify-center text-white hover:bg-campus-600 transition-all shadow-lg">{uploadingAvatar?<Loader2 size={14} className="animate-spin"/>:<Camera size={14}/>}</button><input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={handleAvatar}/></>}
          </div>
          <div className="flex-1 min-w-0">
            {editMode?(
              <div className="space-y-3">
                <input className="input text-sm" value={editForm.name} onChange={e=>setEditForm(f=>({...f,name:e.target.value}))} placeholder="Display name"/>
                <textarea className="input text-sm resize-none" rows={2} value={editForm.bio} onChange={e=>setEditForm(f=>({...f,bio:e.target.value}))} placeholder="Bio (optional)" maxLength={300}/>
                <div className="flex gap-2">
                  <button onClick={handleSave} disabled={saving} className="btn-primary text-xs px-4 py-2 flex items-center gap-1.5">{saving&&<Loader2 size={12} className="animate-spin"/>}Save</button>
                  <button onClick={()=>setEditMode(false)} className="btn-ghost text-xs px-4 py-2">Cancel</button>
                </div>
              </div>
            ):(
              <>
                <div className="flex items-center gap-2 mb-1"><h1 className="font-display font-bold text-xl truncate">{pu?.name}</h1>{pu?.is_verified&&<CheckCircle size={16} className="text-campus-400 flex-shrink-0"/>}</div>
                <p className="text-sm text-gray-500 mb-1">@{pu?.email?.split('@')[0]}</p>
                {pu?.bio&&<p className="text-sm text-gray-300 mb-2 leading-snug">{pu.bio}</p>}
                <p className="text-xs text-gray-600">Joined {pu?.created_at?formatDistanceToNow(new Date(pu.created_at),{addSuffix:true}):''}</p>
              </>
            )}
          </div>
          {isOwn&&!editMode&&(
            <div className="flex flex-col gap-2">
              <button onClick={()=>{setEditForm({name:pu?.name||'',bio:pu?.bio||''});setEditMode(true)}} className="btn-ghost flex items-center gap-1.5 text-sm px-3 py-2"><Edit2 size={14}/>Edit</button>
              <button onClick={logout} className="flex items-center gap-1.5 text-sm text-red-400 hover:text-red-300 px-3 py-2 rounded-xl hover:bg-red-400/10 transition-all"><LogOut size={14}/>Logout</button>
            </div>
          )}
        </div>
        <div className="flex gap-6 mt-5 pt-5 border-t border-surface-border">
          <div className="text-center"><p className="font-display font-bold text-xl">{posts.length}</p><p className="text-xs text-gray-500">Posts</p></div>
          <div className="text-center"><p className="font-display font-bold text-xl">{posts.reduce((s,p)=>s+(p.likes_count||0),0)}</p><p className="text-xs text-gray-500">Total Likes</p></div>
        </div>
      </div>
      <h2 className="font-display font-semibold mb-4">{isOwn?'Your Posts':`${pu?.name}'s Posts`}</h2>
      {loading?<div className="flex items-center justify-center py-10"><Loader2 size={24} className="animate-spin text-campus-400"/></div>
        :posts.length===0?<div className="text-center py-16 card"><p className="text-3xl mb-3">✍️</p><p className="text-gray-400 text-sm">{isOwn?"You haven't posted yet.":'No posts yet.'}</p></div>
        :<div className="space-y-4">{posts.map(p=><PostCard key={p.id} post={p} onDeleted={isOwn?id=>setPosts(prev=>prev.filter(x=>x.id!==id)):undefined}/>)}</div>
      }
    </Layout>
  )
}
EOF

echo ""
echo "✅ All frontend files created successfully!"
echo ""
echo "Now run: cd ~/Downloads/files/frontend && npm run dev"
