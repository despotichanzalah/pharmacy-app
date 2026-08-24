import { GoogleLogin } from '@react-oauth/google'
import { useNavigate } from 'react-router-dom'
import api from '../api.js'

// Drop this into Login.jsx or Register.jsx. On success it either logs the person straight in
// (existing account) or sends them to /register to finish creating their account (new Google user).
export default function GoogleAuthButton({ onError }) {
  const navigate = useNavigate()

  async function handleGoogleSuccess(credentialResponse) {
    const idToken = credentialResponse.credential
    try {
      const { data } = await api.post('/auth/google', { idToken })
      localStorage.setItem('token', data.token)
      localStorage.setItem('user', JSON.stringify(data))
      navigate('/dashboard')
    } catch (err) {
      if (err.response?.status === 404 && err.response.data?.needsRegistration) {
        navigate('/register', {
          state: {
            googleIdToken: idToken,
            googleEmail: err.response.data.email,
            googleName: err.response.data.name,
          },
        })
      } else {
        onError?.(err.response?.data?.error || 'Could not sign in with Google.')
      }
    }
  }

  return (
    <div style={{ margin: '18px 0', display: 'flex', justifyContent: 'center' }}>
      <GoogleLogin
        onSuccess={handleGoogleSuccess}
        onError={() => onError?.('Google sign-in failed. Please try again.')}
        text="continue_with"
        width="100%"
      />
    </div>
  )
}
