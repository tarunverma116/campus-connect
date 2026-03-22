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
