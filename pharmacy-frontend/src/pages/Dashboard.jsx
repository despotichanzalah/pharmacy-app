import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import api from '../api.js'
import Layout from '../components/Layout.jsx'

function currentMonth() {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
}

export default function Dashboard() {
  const user = JSON.parse(localStorage.getItem('user') || '{}')
  const [profit, setProfit] = useState(null)
  const [lowStock, setLowStock] = useState([])
  const [expiring, setExpiring] = useState([])
  const [allBatches, setAllBatches] = useState([])
  const [topMedicines, setTopMedicines] = useState([])
  const [dailySales, setDailySales] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.get(`/reports/profit?month=${currentMonth()}`).catch(() => null),
      api.get('/batches/low-stock?threshold=10'),
      api.get('/batches/expiring?days=30'),
      api.get('/batches/low-stock?threshold=999999'), // pragmatic "all batches"
      api.get(`/reports/top-medicines?month=${currentMonth()}&limit=5`).catch(() => ({ data: [] })),
      api.get('/reports/daily-sales?days=7').catch(() => ({ data: [] })),
    ]).then(([profitRes, lowRes, expRes, allRes, topRes, dailyRes]) => {
      if (profitRes) setProfit(profitRes.data)
      setLowStock(lowRes.data)
      setExpiring(expRes.data)
      setAllBatches(allRes.data)
      setTopMedicines(topRes.data)
      setDailySales(dailyRes.data)
      setLoading(false)
    })
  }, [])

  // Stock health: share of batches that are neither low on stock nor expiring soon.
  const problemIds = new Set([...lowStock.map((b) => b.id), ...expiring.map((b) => b.id)])
  const healthyCount = allBatches.filter((b) => !problemIds.has(b.id)).length
  const healthyPct = allBatches.length > 0 ? Math.round((healthyCount / allBatches.length) * 100) : 100

  const maxDaily = Math.max(1, ...dailySales.map((d) => Number(d.total)))

  return (
    <Layout>
      <div className="page-header" style={{ background: '#F4EFEA' }}>
        <h1>Welcome back, {user.name?.split(' ')[0] || ''}</h1>
        <p className="subtitle">Here's how your shop looks today.</p>
      </div>

      <div className="stat-grid">
        <div className="stat-card">
          <div className="stat-label">Revenue</div>
          <div className="stat-value">{profit ? `Rs ${Number(profit.totalSales).toLocaleString()}` : '—'}</div>
          <div className="stat-sub">This month</div>
        </div>
        <div className="stat-card blue-bar">
          <div className="stat-label">Low stock</div>
          <div className="stat-value" style={{ color: 'var(--stat-blue)' }}>{loading ? '—' : lowStock.length}</div>
          <div className="stat-sub">Need restock</div>
        </div>
        <div className="stat-card yellow-bar">
          <div className="stat-label">Net profit</div>
          <div className={`stat-value ${profit && Number(profit.netProfit) < 0 ? 'danger' : ''}`} style={profit && Number(profit.netProfit) >= 0 ? { color: 'var(--stat-yellow)' } : {}}>
            {profit ? `Rs ${Number(profit.netProfit).toLocaleString()}` : '—'}
          </div>
          <div className="stat-sub">{profit?.month || currentMonth()}</div>
        </div>
        <div className="stat-card purple-bar">
          <div className="stat-label">Expiring soon</div>
          <div className="stat-value" style={{ color: 'var(--stat-purple)' }}>{loading ? '—' : expiring.length}</div>
          <div className="stat-sub">Within 30 days</div>
        </div>
      </div>

      <div className="quick-actions">
        <Link to="/dashboard/sales" className="quick-action">
          <span className="quick-action-icon icon-green">$</span>
          <div>
            <div className="quick-action-title">New sale</div>
            <div className="quick-action-sub">Process customer order</div>
          </div>
        </Link>
        <Link to="/dashboard/medicines" className="quick-action">
          <span className="quick-action-icon icon-blue">⊕</span>
          <div>
            <div className="quick-action-title">Add medicine</div>
            <div className="quick-action-sub">Update inventory</div>
          </div>
        </Link>
        <Link to="/dashboard/stock" className="quick-action">
          <span className="quick-action-icon icon-yellow">▤</span>
          <div>
            <div className="quick-action-title">Stock check</div>
            <div className="quick-action-sub">Review batches</div>
          </div>
        </Link>
        <Link to="/dashboard/reports" className="quick-action">
          <span className="quick-action-icon icon-purple">▲</span>
          <div>
            <div className="quick-action-title">View reports</div>
            <div className="quick-action-sub">Track revenue</div>
          </div>
        </Link>
      </div>

      <div className="two-col-panels">
        <div className="panel-card">
          <div className="panel-head">
            <h3>Revenue trend</h3>
            <span className="badge-pill">7 days</span>
          </div>
          {dailySales.length === 0 ? (
            <div className="empty-inline">No sales yet this week.</div>
          ) : (
            <div className="bar-chart" style={{ gridTemplateColumns: `repeat(${dailySales.length}, minmax(38px, 1fr))` }}>
              {dailySales.map((d) => (
                <div className="bar-column" key={d.date}>
                  <span className="bar-value" style={{ height: `${Math.max(6, (Number(d.total) / maxDaily) * 100)}%` }} />
                  <small>{new Date(d.date).toLocaleDateString(undefined, { weekday: 'short' })}</small>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="panel-card compact-panel">
          <div className="panel-head">
            <h3>Stock health</h3>
            <span className="badge-pill">{healthyPct}%</span>
          </div>
          <div className="donut-wrap">
            <div
              className="donut-chart"
              style={{ background: `conic-gradient(var(--stat-green) ${healthyPct * 3.6}deg, #DFE9F2 0deg)` }}
            >
              <div className="donut-inner">
                <strong>{healthyPct}%</strong>
                <span>Healthy</span>
              </div>
            </div>
            <ul className="legend-list">
              <li><span className="dot dot-green" /> Available ({healthyCount})</li>
              <li><span className="dot dot-gray" /> Monitor ({allBatches.length - healthyCount})</li>
            </ul>
          </div>
        </div>
      </div>

      <div className="bottom-grid">
        <div className="panel-card">
          <div className="panel-head"><h3>Top-selling medicines</h3></div>
          {topMedicines.length === 0 ? (
            <div className="empty-inline">No sales recorded yet this month.</div>
          ) : (
            <div className="progress-list">
              {topMedicines.map((m, i) => {
                const max = topMedicines[0].quantitySold || 1
                const pct = Math.round((m.quantitySold / max) * 100)
                const colors = ['var(--stat-green)', 'var(--stat-blue)', 'var(--stat-yellow)', 'var(--stat-purple)', 'var(--stat-green)']
                return (
                  <div className="progress-row" key={m.medicineName}>
                    <div className="progress-meta">
                      <span>{m.medicineName}</span>
                      <span>{m.quantitySold} sold</span>
                    </div>
                    <div className="progress-track">
                      <span style={{ width: `${pct}%`, background: colors[i % colors.length] }} />
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>

        <div className="panel-card attention-panel">
          <div className="panel-head"><h3>Expiring soon</h3></div>
          {expiring.length === 0 ? (
            <div className="empty-inline">Nothing expiring in the next 30 days.</div>
          ) : (
            <ul className="alert-list">
              {expiring.map((b) => (
                <li key={b.id}>
                  <span className="badge badge-bad">Expiring</span>
                  Batch {b.batchNumber} — {b.expiryDate}
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
    </Layout>
  )
}
