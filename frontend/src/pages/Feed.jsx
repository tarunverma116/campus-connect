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
