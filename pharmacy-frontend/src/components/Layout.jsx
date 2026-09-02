import { useState } from 'react'
import { NavLink, useNavigate } from 'react-router-dom'
import { useLanguage } from '../i18n/LanguageContext.jsx'
import LanguageToggle from './LanguageToggle.jsx'

export default function Layout({ children, title, subtitle, actions }) {
  const [menuOpen, setMenuOpen] = useState(false)
  const navigate = useNavigate()
  const { t } = useLanguage()
  const user = JSON.parse(localStorage.getItem('user') || '{}')

  const NAV_ITEMS = [
    { to: '/dashboard', label: t('overview'), icon: '◆' },
    { to: '/dashboard/medicines', label: t('medicines'), icon: '⊕' },
    { to: '/dashboard/stock', label: t('stock'), icon: '▤' },
    { to: '/dashboard/sales', label: t('sales'), icon: '$' },
    { to: '/dashboard/sales-history', label: 'Sales History', icon: '📋' },
    { to: '/dashboard/returns', label: t('returns'), icon: '↺' },
    { to: '/dashboard/suppliers', label: t('suppliers'), icon: '⌂' },
    { to: '/dashboard/purchases', label: t('purchases'), icon: '▣' },
    { to: '/dashboard/reports', label: t('reports'), icon: '▲' },
    ...(user.role === 'ADMIN' ? [{ to: '/dashboard/staff', label: 'Staff', icon: '◈' }] : []),
  ]

  function logout() {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    navigate('/login')
  }

  return (
    <div className="app-shell">
      <aside className={`app-sidebar ${menuOpen ? 'open' : ''}`}>
        <div className="sidebar-brand">
          <span className="brand-cross sidebar-cross" />
          <div>
            <div className="sidebar-shop">{user.shopName || 'Your Shop'}</div>
            <div className="sidebar-tag">{t('appName')}</div>
          </div>
        </div>

        <nav className="sidebar-nav">
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/dashboard'}
              className={({ isActive }) => `sidebar-link ${isActive ? 'active' : ''}`}
              onClick={() => setMenuOpen(false)}
            >
              <span className="sidebar-icon">{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="sidebar-user">
            <div className="sidebar-avatar">{(user.name || '?')[0]}</div>
            <div>
              <div className="sidebar-user-name">{user.name}</div>
              <div className="sidebar-user-role">{user.role}</div>
            </div>
          </div>
          <button className="sidebar-logout" onClick={logout}>{t('signOut')}</button>
          <LanguageToggle variant="dark" />
        </div>
      </aside>

      {menuOpen && <div className="sidebar-backdrop" onClick={() => setMenuOpen(false)} />}

      <main className="app-main">
        <div className="mobile-topbar">
          <button className="mobile-menu-btn" onClick={() => setMenuOpen(true)}>☰</button>
          <strong>{user.shopName || 'Your Shop'}</strong>
        </div>

        {actions && (
          <header className="app-header">
            <div className="header-actions">{actions}</div>
          </header>
        )}

        <div className="app-content">
          {title && (
            <div className="page-header">
              <h1>{title}</h1>
              {subtitle && <p className="subtitle">{subtitle}</p>}
            </div>
          )}
          {children}
        </div>
      </main>
    </div>
  )
}