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
