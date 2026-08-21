import { useEffect, useState } from 'react'
import api from '../api.js'
import PageHeader from '../components/PageHeader.jsx'

function monthNow() {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
}

export default function Overview() {
  const user = JSON.parse(localStorage.getItem('user') || '{}')
  const [profit, setProfit] = useState(null)
  const [lowStock, setLowStock] = useState([])
  const [expiring, setExpiring] = useState([])
  const [medicineCount, setMedicineCount] = useState(0)

  useEffect(() => {
    api.get(`/reports/profit?month=${monthNow()}`).then(({ data }) => setProfit(data)).catch(() => {})
    api.get('/batches/low-stock?threshold=15').then(({ data }) => setLowStock(data)).catch(() => {})
    api.get('/batches/expiring?days=30').then(({ data }) => setExpiring(data)).catch(() => {})
    api.get('/medicines').then(({ data }) => setMedicineCount(data.length)).catch(() => {})
  }, [])

  return (
    <div>
      <PageHeader eyebrow="Overview" title={`Welcome back, ${user.name?.split(' ')[0] || ''}`} />

      <div className="stat-grid">
        <div className="stat-tile">
          <div className="stat-tile-label">This month's sales</div>
          <div className="stat-tile-value">Rs {profit?.totalSales ?? '—'}</div>
        </div>
        <div className="stat-tile accent">
          <div className="stat-tile-label">Net profit</div>
          <div className="stat-tile-value">Rs {profit?.netProfit ?? '—'}</div>
        </div>
        <div className="stat-tile">
          <div className="stat-tile-label">Medicines tracked</div>
          <div className="stat-tile-value">{medicineCount}</div>
        </div>
        <div className="stat-tile warn">
          <div className="stat-tile-label">Low stock batches</div>
          <div className="stat-tile-value">{lowStock.length}</div>
        </div>
      </div>

      <div className="panel-grid">
        <div className="panel">
          <div className="panel-title">Low stock — act soon</div>
          {lowStock.length === 0 ? (
            <div className="empty-hint">Nothing running low right now.</div>
          ) : (
            <ul className="mini-list">
              {lowStock.slice(0, 6).map((b) => (
                <li key={b.id}>
                  <span>{b.medicine?.name || 'Medicine'} · {b.batchNumber}</span>
                  <span className="mini-badge warn">{b.quantity} left</span>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="panel">
          <div className="panel-title">Expiring within 30 days</div>
          {expiring.length === 0 ? (
            <div className="empty-hint">Nothing expiring soon.</div>
          ) : (
            <ul className="mini-list">
              {expiring.slice(0, 6).map((b) => (
                <li key={b.id}>
                  <span>{b.medicine?.name || 'Medicine'} · {b.batchNumber}</span>
                  <span className="mini-badge rust">{b.expiryDate}</span>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
    </div>
  )
}
