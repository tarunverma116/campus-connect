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
