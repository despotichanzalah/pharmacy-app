import { useEffect, useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import api from '../api.js'
import { useLanguage } from '../i18n/LanguageContext.jsx'
import LanguageToggle from '../components/LanguageToggle.jsx'

export default function Register() {
  const navigate = useNavigate()
  const { t } = useLanguage()
  const [mode, setMode] = useState('create')
  const [shops, setShops] = useState([])
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const [form, setForm] = useState({
    name: '', email: '', password: '', roleName: 'ADMIN', shopName: '', shopId: '',
  })

  useEffect(() => {
    if (mode === 'join') {
      api.get('/shops').then(({ data }) => setShops(data)).catch(() => setShops([]))
    }
  }, [mode])

  function update(field, value) {
    setForm((f) => ({ ...f, [field]: value }))
  }

  function switchMode(next) {
    setMode(next)
    setForm((f) => ({ ...f, roleName: next === 'create' ? 'ADMIN' : 'CASHIER' }))
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setLoading(true)

    const payload = {
      name: form.name,
      email: form.email,
      password: form.password,
      roleName: form.roleName,
      ...(mode === 'create' ? { shopName: form.shopName } : { shopId: Number(form.shopId) }),
    }

    try {
      const { data } = await api.post('/auth/register', payload)
      localStorage.setItem('token', data.token)
      localStorage.setItem('user', JSON.stringify(data))
      navigate('/dashboard')
    } catch (err) {
      setError(err.response?.data?.error || t('couldNotCreateAccount'))
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
        <h1>{t('createYourAccount')}</h1>
        <p className="lede">{t('createAccountSub')}</p>

        {error && <div className="alert-error">{error}</div>}

        <div className="radio-row">
          <button type="button" className={`radio-pill ${mode === 'create' ? 'active' : ''}`} onClick={() => switchMode('create')}>
            {t('startNewShop')}
          </button>
          <button type="button" className={`radio-pill ${mode === 'join' ? 'active' : ''}`} onClick={() => switchMode('join')}>
            {t('joinMyShop')}
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="field">
            <label htmlFor="name">{t('yourName')}</label>
            <input id="name" required value={form.name} onChange={(e) => update('name', e.target.value)} placeholder="Huny" />
          </div>

          <div className="field">
            <label htmlFor="email">{t('email')}</label>
            <input id="email" type="email" required value={form.email} onChange={(e) => update('email', e.target.value)} placeholder="you@shop.com" />
          </div>

          <div className="field">
            <label htmlFor="password">{t('password')}</label>
            <input id="password" type="password" required minLength={6} value={form.password} onChange={(e) => update('password', e.target.value)} placeholder="••••••••" />
          </div>

          {mode === 'create' ? (
            <div className="field">
              <label htmlFor="shopName">{t('shopName')}</label>
              <input id="shopName" required value={form.shopName} onChange={(e) => update('shopName', e.target.value)} placeholder="Huny Pharmacy" />
              <div className="field-hint">{t('youWillBeAdmin')}</div>
            </div>
          ) : (
            <>
              <div className="field">
                <label htmlFor="shopId">{t('yourShop')}</label>
                <select id="shopId" required value={form.shopId} onChange={(e) => update('shopId', e.target.value)}>
                  <option value="" disabled>{t('selectShop')}</option>
                  {shops.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
                </select>
              </div>

              <div className="field">
                <label htmlFor="roleName">{t('yourRole')}</label>
                <select id="roleName" value={form.roleName} onChange={(e) => update('roleName', e.target.value)}>
                  <option value="PHARMACIST">{t('pharmacist')}</option>
                  <option value="CASHIER">{t('cashier')}</option>
                  <option value="ADMIN">{t('admin')}</option>
                </select>
              </div>
            </>
          )}

          <button className="btn-primary" type="submit" disabled={loading}>
            {loading ? t('creatingAccount') : t('createAccount')}
          </button>
        </form>

        <div className="auth-switch">
          {t('alreadyHaveAccount')} <Link to="/login">{t('signIn')}</Link>
        </div>
      </div>
    </div>
  )
}
