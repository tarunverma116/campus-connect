import { createContext, useContext, useState, useEffect, useCallback } from 'react'
import { authAPI } from '../services/api'
const AuthContext = createContext(null)
export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => { try { return JSON.parse(localStorage.getItem('cc_user')) } catch { return null } })
  const [token, setToken] = useState(() => localStorage.getItem('cc_token'))
  const [loading, setLoading] = useState(true)
  useEffect(() => {
    if (token) { authAPI.me().then(r => { setUser(r.data); localStorage.setItem('cc_user', JSON.stringify(r.data)) }).catch(() => logout()).finally(() => setLoading(false)) }
    else setLoading(false)
  }, [])
  const login = useCallback((t, u) => { localStorage.setItem('cc_token',t); localStorage.setItem('cc_user',JSON.stringify(u)); setToken(t); setUser(u) }, [])
  const logout = useCallback(() => { localStorage.removeItem('cc_token'); localStorage.removeItem('cc_user'); setToken(null); setUser(null) }, [])
  const refreshUser = useCallback(async () => { try { const r = await authAPI.me(); setUser(r.data); localStorage.setItem('cc_user', JSON.stringify(r.data)) } catch {} }, [])
  return <AuthContext.Provider value={{ user, token, loading, login, logout, refreshUser }}>{children}</AuthContext.Provider>
}
export const useAuth = () => { const c = useContext(AuthContext); if (!c) throw new Error('useAuth outside provider'); return c }
