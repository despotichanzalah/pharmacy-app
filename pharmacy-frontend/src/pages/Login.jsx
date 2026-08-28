import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import api from '../api.js'
import { useLanguage } from '../i18n/LanguageContext.jsx'
import LanguageToggle from '../components/LanguageToggle.jsx'
import GoogleAuthButton from '../components/GoogleAuthButton.jsx'
import PasswordField from '../components/PasswordField.jsx'

export default function Login() {
  const navigate = useNavigate()
  const { t } = useLanguage()
  const [form, setForm] = useState({ email: '', password: '', rememberMe: false })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  function update(field, value) {
    setForm((f) => ({ ...f, [field]: value }))
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const { data } = await api.post('/auth/login', form)
      localStorage.setItem('token', data.token)
      localStorage.setItem('user', JSON.stringify(data))
      navigate('/dashboard')
    } catch (err) {
      setError(err.response?.data?.error || t('couldNotSignIn'))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="auth-shell">
      <div className="auth-topbar">
        <div className="auth-logo">
          <span className="brand-cross" />
          {t('appName')}
        </div>
        <LanguageToggle />
      </div>

      <div className="auth-card">
        <h1>{t('welcomeBack')}</h1>
        <p className="lede">{t('signInSub')}</p>

        {error && <div className="alert-error">{error}</div>}

        <form onSubmit={handleSubmit}>
          <div className="field">
            <label htmlFor="email">{t('email')}</label>
            <input
              id="email"
              type="email"
              required
              value={form.email}
              onChange={(e) => update('email', e.target.value)}
              placeholder="you@shop.com"
            />
          </div>

          <div className="field">
            <label htmlFor="password">{t('password')}</label>
            <PasswordField
              id="password"
              value={form.password}
              onChange={(e) => update('password', e.target.value)}
              placeholder="••••••••"
            />
          </div>

          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontWeight: 600, fontSize: 15 }}>
              <input
                type="checkbox"
                checked={form.rememberMe}
                onChange={(e) => update('rememberMe', e.target.checked)}
              />
              Remember me
            </label>
            <Link to="/forgot-password" style={{ fontSize: 15, fontWeight: 600 }}>Forgot password?</Link>
          </div>

          <button className="btn-primary" type="submit" disabled={loading}>
            {loading ? t('signingIn') : t('signIn')}
          </button>
        </form>

        <GoogleAuthButton onError={setError} />

        <div className="auth-switch">
          {t('newShopQuestion')} <Link to="/register">{t('createAccount')}</Link>
        </div>
      </div>
    </div>
  )
}
