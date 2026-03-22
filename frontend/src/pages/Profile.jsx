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
