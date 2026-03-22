import { useState, useRef, useEffect } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { GraduationCap, Loader2, RefreshCw } from 'lucide-react'
import { authAPI } from '../services/api'
import { useAuth } from '../context/AuthContext'
import toast from 'react-hot-toast'
export default function Verify() {
  const { login } = useAuth(); const navigate = useNavigate(); const location = useLocation()
  const email = location.state?.email || ''
  const [otp, setOtp] = useState(['','','','','',''])
  const [loading, setLoading] = useState(false); const [resending, setResending] = useState(false); const [cooldown, setCooldown] = useState(0)
  const refs = useRef([])
  useEffect(() => { if (cooldown<=0) return; const t = setTimeout(()=>setCooldown(c=>c-1),1000); return ()=>clearTimeout(t) }, [cooldown])
  const handleChange = (i,val) => { if (!/^\d?$/.test(val)) return; const n=[...otp]; n[i]=val; setOtp(n); if(val&&i<5) refs.current[i+1]?.focus() }
  const handleKeyDown = (i,e) => { if(e.key==='Backspace'&&!otp[i]&&i>0) refs.current[i-1]?.focus() }
  const handlePaste = e => { e.preventDefault(); const p=e.clipboardData.getData('text').replace(/\D/g,'').slice(0,6); const n=[...otp]; p.split('').forEach((c,i)=>{n[i]=c}); setOtp(n); refs.current[Math.min(p.length,5)]?.focus() }
  const handleSubmit = async e => {
    e.preventDefault(); const code=otp.join('')
    if(code.length<6) return toast.error('Enter the full 6-digit OTP')
    if(!email) return toast.error('Email not found. Please sign up again.')
    setLoading(true)
    try { const r=await authAPI.verifyOTP({email,otp:code}); login(r.data.access_token,r.data.user); toast.success('Email verified! Welcome 🎓'); navigate('/feed') }
    catch(err) { toast.error(err.response?.data?.detail||'Invalid OTP'); setOtp(['','','','','','']); refs.current[0]?.focus() }
    setLoading(false)
  }
  const handleResend = async () => {
    if(!email||cooldown>0) return; setResending(true)
    try { await authAPI.resendOTP(email); toast.success('New OTP sent!'); setCooldown(60) }
    catch(err) { toast.error(err.response?.data?.detail||'Failed') }
    setResending(false)
  }
  return (
    <div className="min-h-screen flex items-center justify-center p-6">
      <div className="w-full max-w-sm text-center">
        <div className="w-16 h-16 bg-campus-500/20 rounded-2xl flex items-center justify-center mx-auto mb-6"><GraduationCap size={32} className="text-campus-400"/></div>
        <h1 className="font-display font-bold text-2xl mb-2">Verify your email</h1>
        <p className="text-gray-500 text-sm mb-2">We sent a 6-digit OTP to</p>
        <p className="text-campus-400 font-medium text-sm mb-8 break-all">{email||'your email'}</p>
        <form onSubmit={handleSubmit}>
          <div className="flex gap-2.5 justify-center mb-6" onPaste={handlePaste}>
            {otp.map((digit,i)=>(
              <input key={i} ref={el=>refs.current[i]=el} type="text" inputMode="numeric" maxLength={1} value={digit} onChange={e=>handleChange(i,e.target.value)} onKeyDown={e=>handleKeyDown(i,e)} className={`w-12 h-14 text-center text-xl font-bold font-mono rounded-xl border bg-surface-hover text-white focus:outline-none focus:border-campus-500 focus:ring-1 focus:ring-campus-500 transition-all ${digit?'border-campus-500/60':'border-surface-border'}`}/>
            ))}
          </div>
          <button type="submit" disabled={loading||otp.join('').length<6} className="btn-primary w-full py-3 flex items-center justify-center gap-2 mb-4">{loading&&<Loader2 size={16} className="animate-spin"/>}{loading?'Verifying…':'Verify Email'}</button>
        </form>
        <button onClick={handleResend} disabled={resending||cooldown>0} className="flex items-center gap-2 text-sm text-gray-500 hover:text-campus-400 transition-colors mx-auto disabled:opacity-50">
          <RefreshCw size={14} className={resending?'animate-spin':''}/>{cooldown>0?`Resend in ${cooldown}s`:'Resend OTP'}
        </button>
        <p className="text-xs text-gray-600 mt-6">💡 In dev mode, OTP is printed in the backend terminal.</p>
      </div>
    </div>
  )
}
