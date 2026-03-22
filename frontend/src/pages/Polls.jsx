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
