import { NavLink, Outlet, useNavigate } from 'react-router-dom'

const NAV = [
  { to: '/app', label: 'Overview', end: true, icon: '◈' },
  { to: '/app/medicines', label: 'Medicines', icon: '⊞' },
  { to: '/app/stock', label: 'Stock', icon: '▤' },
  { to: '/app/sales', label: 'Sales', icon: '⟡' },
  { to: '/app/returns', label: 'Returns', icon: '↺' },
  { to: '/app/suppliers', label: 'Suppliers', icon: '◫' },
  { to: '/app/purchases', label: 'Purchases', icon: '▥' },
  { to: '/app/reports', label: 'Reports', icon: '◔' },
]

export default function DashboardLayout() {
  const navigate = useNavigate()
  const user = JSON.parse(localStorage.getItem('user') || '{}')

  function logout() {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    navigate('/login')
  }

  return (
    <div className="app-shell">
      <aside className="app-sidebar">
        <div className="sidebar-brand">
          <span className="brand-cross" />
          <div>
            <div className="sidebar-shop">{user.shopName || 'Your Shop'}</div>
            <div className="sidebar-tag">Pharmacy Systems</div>
          </div>
        </div>

        <nav className="sidebar-nav">
          {NAV.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) => `sidebar-link ${isActive ? 'active' : ''}`}
            >
              <span className="sidebar-icon">{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="sidebar-user">
            <div className="sidebar-avatar">{(user.name || '?').charAt(0).toUpperCase()}</div>
            <div>
              <div className="sidebar-user-name">{user.name}</div>
              <div className="sidebar-user-role">{user.role}</div>
            </div>
          </div>
          <button className="sidebar-logout" onClick={logout}>Sign out</button>
        </div>
      </aside>

      <main className="app-content">
        <Outlet />
      </main>
    </div>
  )
}
