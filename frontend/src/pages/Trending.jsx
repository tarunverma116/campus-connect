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
