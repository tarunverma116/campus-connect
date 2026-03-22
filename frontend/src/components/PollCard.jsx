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
