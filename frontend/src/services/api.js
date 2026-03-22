import axios from 'axios'
import toast from 'react-hot-toast'
const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'
const api = axios.create({ baseURL: BASE_URL, headers: { 'Content-Type': 'application/json' } })
api.interceptors.request.use(c => { const t = localStorage.getItem('cc_token'); if(t) c.headers.Authorization=`Bearer ${t}`; return c })
api.interceptors.response.use(r => r, e => { if(e.response?.status===401){ localStorage.removeItem('cc_token'); localStorage.removeItem('cc_user'); window.location.href='/login' } return Promise.reject(e) })
export const authAPI = {
  signup: d => api.post('/auth/signup', d),
  verifyOTP: d => api.post('/auth/verify-otp', d),
  resendOTP: e => api.post(`/auth/resend-otp?email=${encodeURIComponent(e)}`),
  login: d => api.post('/auth/login', d),
  me: () => api.get('/auth/me'),
  updateProfile: d => api.put('/auth/profile', d),
  uploadAvatar: fd => api.post('/auth/upload-avatar', fd, { headers:{'Content-Type':'multipart/form-data'} }),
}
export const postsAPI = {
  getFeed: (p=1) => api.get(`/posts/feed?page=${p}&limit=10`),
  getTrending: () => api.get('/posts/trending'),
  getUserPosts: (uid,p=1) => api.get(`/posts/user/${uid}?page=${p}`),
  create: fd => api.post('/posts/create', fd, { headers:{'Content-Type':'multipart/form-data'} }),
  like: id => api.post('/posts/like', { post_id:id }),
  unlike: id => api.delete('/posts/unlike', { data:{ post_id:id } }),
  report: (id,reason) => api.post('/posts/report', { post_id:id, reason }),
  delete: id => api.delete(`/posts/${id}`),
}
export const commentsAPI = {
  add: (pid,content) => api.post('/comments/add', { post_id:pid, content }),
  get: pid => api.get(`/comments/${pid}`),
  delete: id => api.delete(`/comments/${id}`),
}
export const pollsAPI = {
  getAll: () => api.get('/poll/all'),
  get: id => api.get(`/poll/${id}`),
  create: d => api.post('/poll/create', d),
  vote: (pid,oid) => api.post('/poll/vote', { poll_id:pid, option_id:oid }),
}
export const notificationsAPI = {
  getAll: () => api.get('/notifications/'),
  getUnreadCount: () => api.get('/notifications/unread-count'),
  markAllRead: () => api.put('/notifications/read-all'),
  markRead: id => api.put(`/notifications/${id}/read`),
}
export default api
