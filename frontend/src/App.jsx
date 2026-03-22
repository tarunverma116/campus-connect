import { Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Login from './pages/Login'
import Signup from './pages/Signup'
import Verify from './pages/Verify'
import Feed from './pages/Feed'
import Trending from './pages/Trending'
import Polls from './pages/Polls'
import Notifications from './pages/Notifications'
import Profile from './pages/Profile'

function Protected({ children }) {
  const { user, loading } = useAuth()
  if (loading) return <div className="min-h-screen flex items-center justify-center"><div className="w-10 h-10 border-2 border-campus-500 border-t-transparent rounded-full animate-spin"/></div>
  return user ? children : <Navigate to="/login" replace />
}
function Guest({ children }) {
  const { user, loading } = useAuth()
  if (loading) return null
  return !user ? children : <Navigate to="/feed" replace />
}
function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/feed" replace />} />
      <Route path="/login" element={<Guest><Login /></Guest>} />
      <Route path="/signup" element={<Guest><Signup /></Guest>} />
      <Route path="/verify" element={<Guest><Verify /></Guest>} />
      <Route path="/feed" element={<Protected><Feed /></Protected>} />
      <Route path="/trending" element={<Protected><Trending /></Protected>} />
      <Route path="/polls" element={<Protected><Polls /></Protected>} />
      <Route path="/notifications" element={<Protected><Notifications /></Protected>} />
      <Route path="/profile" element={<Protected><Profile /></Protected>} />
      <Route path="/profile/:id" element={<Protected><Profile /></Protected>} />
      <Route path="*" element={<Navigate to="/feed" replace />} />
    </Routes>
  )
}
export default function App() {
  return <AuthProvider><AppRoutes /></AuthProvider>
}
