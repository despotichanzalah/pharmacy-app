import { useState } from 'react'
import { Link } from 'react-router-dom'
import api from '../api.js'

export default function ForgotPassword() {
  const [email, setEmail] = useState('')
  const [sent, setSent] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await api.post('/auth/forgot-password', { email })
      setSent(true)
    } catch (err) {
      setError(err.response?.data?.error || 'Something went wrong. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="auth-shell">
      <div className="auth-topbar">
        <div className="auth-logo">
          <span className="brand-cross" />
          Huny Pharmacy
        </div>
      </div>

      <div className="auth-card">
        <h1>Reset your password</h1>
        <p className="lede">Enter your account email and we'll send you a reset link.</p>

        {error && <div className="alert-error">{error}</div>}

        {sent ? (
          <div className="alert-success">
            If that email is registered, a reset link has been sent. Check your inbox (and spam folder).
          </div>
        ) : (
          <form onSubmit={handleSubmit}>
            <div className="field">
              <label htmlFor="email">Email</label>
              <input
                id="email"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@shop.com"
              />
            </div>
            <button className="btn-primary" type="submit" disabled={loading}>
              {loading ? 'Sending…' : 'Send reset link'}
            </button>
          </form>
        )}

        <div className="auth-switch">
          <Link to="/login">Back to sign in</Link>
        </div>
      </div>
    </div>
  )
}
