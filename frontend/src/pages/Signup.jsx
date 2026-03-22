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
