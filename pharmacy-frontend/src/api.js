import axios from 'axios'

// In production (Vercel), set VITE_API_URL in the project's environment variables
// to your deployed backend's URL, e.g. https://huny-pharmacy-backend.onrender.com/api
const baseURL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api'

const api = axios.create({ baseURL })

// Attach the saved token to every request automatically.
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

export default api
