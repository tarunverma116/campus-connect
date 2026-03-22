import { useState, useEffect } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { Home, TrendingUp, BarChart2, Bell, User, LogOut, GraduationCap } from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import { notificationsAPI } from '../services/api'
const BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000'
function Navbar() {
  const { user, logout } = useAuth()
  const location = useLocation(); const navigate = useNavigate()
  const [unread, setUnread] = useState(0)
  useEffect(() => {
    notificationsAPI.getUnreadCount().then(r => setUnread(r.data.unread_count)).catch(()=>{})
    const t = setInterval(() => notificationsAPI.getUnreadCount().then(r => setUnread(r.data.unread_count)).catch(()=>{}), 30000)
    return () => clearInterval(t)
  }, [])
  const links = [
    { to:'/feed', icon:Home, label:'Feed' },
    { to:'/trending', icon:TrendingUp, label:'Trending' },
    { to:'/polls', icon:BarChart2, label:'Polls' },
    { to:'/notifications', icon:Bell, label:'Alerts', badge:unread },
    { to:'/profile', icon:User, label:'Profile' },
  ]
  const src = user?.profile_picture ? (user.profile_picture.startsWith('http') ? user.profile_picture : `${BASE}${user.profile_picture}`) : null
  return (
    <>
      <aside className="hidden md:flex flex-col fixed left-0 top-0 h-screen w-60 bg-surface-card border-r border-surface-border z-40 p-6">
        <Link to="/feed" className="flex items-center gap-2.5 mb-10">
          <div className="w-9 h-9 bg-campus-500 rounded-xl flex items-center justify-center"><GraduationCap size={20} className="text-white"/></div>
          <span className="font-display font-bold text-lg">Campus<span className="text-campus-400">Connect</span></span>
        </Link>
        <nav className="flex-1 flex flex-col gap-1">
          {links.map(({ to, icon:Icon, label, badge }) => {
            const active = location.pathname === to
            return (
              <Link key={to} to={to} className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all relative ${active ? 'bg-campus-500/15 text-campus-400' : 'text-gray-400 hover:bg-surface-hover hover:text-white'}`}>
                <Icon size={18}/>{label}
                {badge > 0 && <span className="ml-auto bg-campus-500 text-white text-xs font-bold px-1.5 py-0.5 rounded-full min-w-[20px] text-center">{badge > 99 ? '99+' : badge}</span>}
              </Link>
            )
          })}
        </nav>
        <div className="flex items-center gap-3 pt-4 border-t border-surface-border">
          {src ? <img src={src} alt="" className="w-9 h-9 rounded-full object-cover ring-2 ring-surface-border"/> : <div className="w-9 h-9 rounded-full bg-campus-500/20 flex items-center justify-center text-campus-400 font-bold text-sm">{user?.name?.[0]?.toUpperCase()}</div>}
          <div className="flex-1 min-w-0"><p className="text-sm font-semibold truncate">{user?.name}</p><p className="text-xs text-gray-500 truncate">{user?.email?.split('@')[0]}</p></div>
          <button onClick={() => { logout(); navigate('/login') }} className="p-1.5 text-gray-500 hover:text-red-400 hover:bg-red-400/10 rounded-lg transition-all"><LogOut size={16}/></button>
        </div>
      </aside>
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-surface-card border-t border-surface-border z-40 flex">
        {links.map(({ to, icon:Icon, badge }) => (
          <Link key={to} to={to} className={`flex-1 flex flex-col items-center py-3 relative transition-colors ${location.pathname===to ? 'text-campus-400' : 'text-gray-500'}`}>
            <div className="relative"><Icon size={20}/>{badge > 0 && <span className="absolute -top-1 -right-1 bg-campus-500 text-white text-[9px] font-bold px-1 rounded-full">{badge > 9 ? '9+' : badge}</span>}</div>
          </Link>
        ))}
      </nav>
    </>
  )
}
export default function Layout({ children }) {
  return (
    <div className="min-h-screen bg-surface">
      <Navbar/>
      <div className="md:pl-60">
        <div className="max-w-xl mx-auto px-4 py-6 pb-24 md:pb-8">{children}</div>
      </div>
    </div>
  )
}
