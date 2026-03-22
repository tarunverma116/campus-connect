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
