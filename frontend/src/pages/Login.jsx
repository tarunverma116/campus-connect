import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { GraduationCap, Eye, EyeOff, Loader2 } from 'lucide-react'
import { authAPI } from '../services/api'
import { useAuth } from '../context/AuthContext'
import toast from 'react-hot-toast'
export default function Login() {
  const { login } = useAuth(); const navigate = useNavigate()
  const [form, setForm] = useState({ email:'', password:'' })
  const [show, setShow] = useState(false); const [loading, setLoading] = useState(false)
  const set = k => e => setForm(f=>({...f,[k]:e.target.value}))
  const handleSubmit = async e => {
    e.preventDefault(); setLoading(true)
    try { const r = await authAPI.login(form); login(r.data.access_token,r.data.user); toast.success(`Welcome back, ${r.data.user.name}! 👋`); navigate('/feed') }
    catch(err) { toast.error(err.response?.data?.detail||'Login failed') }
    setLoading(false)
  }
  return (
    <div className="min-h-screen flex items-center justify-center p-6">
      <div className="w-full max-w-sm">
        <div className="flex items-center gap-2.5 mb-8"><div className="w-10 h-10 bg-campus-500 rounded-xl flex items-center justify-center"><GraduationCap size={22} className="text-white"/></div><span className="font-display font-bold text-xl">Campus<span className="text-campus-400">Connect</span></span></div>
        <h1 className="font-display font-bold text-2xl mb-1">Welcome back</h1>
        <p className="text-gray-500 text-sm mb-8">Sign in to your campus account</p>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div><label className="label">University Email</label><input className="input" type="email" placeholder="you@gla.ac.in" value={form.email} onChange={set('email')} required/></div>
          <div><label className="label">Password</label>
            <div className="relative"><input className="input pr-11" type={show?'text':'password'} placeholder="Your password" value={form.password} onChange={set('password')} required/>
              <button type="button" onClick={()=>setShow(v=>!v)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-300">{show?<EyeOff size={16}/>:<Eye size={16}/>}</button>
            </div>
          </div>
          <button type="submit" disabled={loading} className="btn-primary w-full py-3 flex items-center justify-center gap-2">{loading&&<Loader2 size={16} className="animate-spin"/>}{loading?'Signing in…':'Sign In'}</button>
        </form>
        <p className="text-center text-sm text-gray-500 mt-6">New here? <Link to="/signup" className="text-campus-400 hover:text-campus-300 font-medium">Create account</Link></p>
      </div>
    </div>
  )
}
