import { Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Login     from './pages/Login'
import Signup    from './pages/Signup'
import Verify    from './pages/Verify'
import Feed      from './pages/Feed'
import Profile   from './pages/Profile'
import Trending  from './pages/Trending'
import Polls     from './pages/Polls'
import Notifications from './pages/Notifications'

function ProtectedRoute({ children }) {
  const { user, loading } = useAuth()
  if (loading) return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="flex flex-col items-center gap-3">
        <div className="w-10 h-10 border-2 border-campus-500 border-t-transparent rounded-full animate-spin" />
        <p className="text-gray-500 text-sm">Loading CampusConnect…</p>
      </div>
    </div>
  )
  return user ? children : <Navigate to="/login" replace />
}

function GuestRoute({ children }) {
  const { user, loading } = useAuth()
  if (loading) return null
  return !user ? children : <Navigate to="/feed" replace />
}

function AppRoutes() {
  return (
    <Routes>
      <Route path="/"              element={<Navigate to="/feed" replace />} />
      <Route path="/login"         element={<GuestRoute><Login /></GuestRoute>} />
      <Route path="/signup"        element={<GuestRoute><Signup /></GuestRoute>} />
      <Route path="/verify"        element={<GuestRoute><Verify /></GuestRoute>} />
      <Route path="/feed"          element={<ProtectedRoute><Feed /></ProtectedRoute>} />
      <Route path="/trending"      element={<ProtectedRoute><Trending /></ProtectedRoute>} />
      <Route path="/polls"         element={<ProtectedRoute><Polls /></ProtectedRoute>} />
      <Route path="/notifications" element={<ProtectedRoute><Notifications /></ProtectedRoute>} />
      <Route path="/profile"       element={<ProtectedRoute><Profile /></ProtectedRoute>} />
      <Route path="/profile/:id"   element={<ProtectedRoute><Profile /></ProtectedRoute>} />
      <Route path="*"              element={<Navigate to="/feed" replace />} />
    </Routes>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <AppRoutes />
    </AuthProvider>
  )
}
