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
  const isAdmin = user.role === 'ADMIN'
  const [profit, setProfit] = useState(null)
  const [lowStock, setLowStock] = useState([])
  const [expiring, setExpiring] = useState([])
  const [allBatches, setAllBatches] = useState([])
  const [topMedicines, setTopMedicines] = useState([])
  const [dailySales, setDailySales] = useState([])
  const [loading, setLoading] = useState(true)

      useEffect(() => {
    async function loadDashboard() {
      try {
        const [lowStockRes, expiringRes, allBatchesRes] = await Promise.all([
          api.get('/batches/low-stock?threshold=10').catch(() => ({ data: [] })),
          api.get('/batches/expiring?days=30').catch(() => ({ data: [] })),
          api.get('/batches/low-stock?threshold=999999').catch(() => ({ data: [] })),
        ])
        setLowStock(lowStockRes.data)
        setExpiring(expiringRes.data)
        setAllBatches(allBatchesRes.data)

        if (isAdmin) {
          const [profitRes, topRes, dailyRes] = await Promise.all([
            api.get(`/reports/profit?month=${currentMonth()}`).catch(() => null),
            api.get(`/reports/top-medicines?month=${currentMonth()}&limit=5`).catch(() => ({ data: [] })),
            api.get('/reports/daily-sales?days=7').catch(() => ({ data: [] })),
          ])
          if (profitRes) setProfit(profitRes.data)
          setTopMedicines(topRes.data)
          setDailySales(dailyRes.data)
        }
      } finally {
        setLoading(false)
      }
    }
    loadDashboard()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const problemIds = new Set([...lowStock.map((b) => b.id), ...expiring.map((b) => b.id)])
  const healthyCount = allBatches.filter((b) => !problemIds.has(b.id)).length
  const healthyPct = allBatches.length > 0 ? Math.round((healthyCount / allBatches.length) * 100) : 100

  function buildLinePath(values, width, height, padding = 8) {
    if (values.length === 0) return { line: '', area: '' }
    const max = Math.max(1, ...values)
    const stepX = (width - padding * 2) / Math.max(1, values.length - 1)
    const points = values.map((v, i) => {
      const x = padding + i * stepX
      const y = height - padding - (v / max) * (height - padding * 2)
      return [x, y]
    })
    let line = `M ${points[0][0]},${points[0][1]}`
    for (let i = 1; i < points.length; i++) {
      const [x0, y0] = points[i - 1]
      const [x1, y1] = points[i]
      const cx = (x0 + x1) / 2
      line += ` C ${cx},${y0} ${cx},${y1} ${x1},${y1}`
    }
    const area = `${line} L ${points[points.length - 1][0]},${height - padding} L ${points[0][0]},${height - padding} Z`
    return { line, area, points }
  }

  const chartValues = dailySales.map((d) => Number(d.total))
  const { line, area, points } = buildLinePath(chartValues, 600, 160)

  if (loading) {
    return (
      <Layout title="Overview" subtitle="Loading your shop's numbers…">
        <div style={{ padding: 40, textAlign: 'center', color: 'var(--ink-soft)' }}>Loading…</div>
      </Layout>
    )
  }

  return (
    <Layout title="" subtitle="">
      <div
        className="dashboard-hero"
        style={{
          background: 'linear-gradient(135deg, var(--primary) 0%, #EF9750 100%)',
          borderRadius: 20,
          padding: '28px 30px',
          marginBottom: 20,
          color: '#fff',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          boxShadow: '0 10px 30px -8px rgba(244,162,97,0.45)',
        }}
      >
        <div>
          <h1 style={{ color: '#fff', margin: 0, fontSize: 26 }}>Welcome back, {user.name?.split(' ')[0] || ''}</h1>
          <p style={{ color: 'rgba(255,255,255,0.85)', margin: '6px 0 0' }}>{user.shopName || "Here's how your shop looks today."}</p>
        </div>
        <div
          style={{
            width: 54, height: 54, borderRadius: '50%',
            background: 'rgba(255,255,255,0.22)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontWeight: 800, fontSize: 20, color: '#fff', flexShrink: 0,
          }}
        >
          {(user.name || '?')[0]?.toUpperCase()}
        </div>
      </div>

      <div className="stat-grid">
        {isAdmin && (
          <>
            <StatCard icon="📈" label="Revenue" value={profit ? `Rs ${Number(profit.totalSales).toLocaleString()}` : '—'} sub="This month" accent="var(--stat-green, #22A06B)" />
            <StatCard icon="💰" label="Net profit" value={profit ? `Rs ${Number(profit.netProfit).toLocaleString()}` : '—'} sub={profit?.month || currentMonth()} accent={profit && Number(profit.netProfit) < 0 ? 'var(--bad-text, #E05252)' : '#E9A23D'} />
          </>
        )}
        <StatCard icon="📦" label="Low stock" value={lowStock.length} sub="Need restock" accent="var(--stat-blue, #6C8AE4)" />
        <StatCard icon="⏰" label="Expiring soon" value={expiring.length} sub="Within 30 days" accent="#8B7FD6" />
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
            <div className="quick-action-sub">New medicine + first batch</div>
          </div>
        </Link>
        <Link to="/dashboard/stock" className="quick-action">
          <span className="quick-action-icon icon-yellow">▤</span>
          <div>
            <div className="quick-action-title">Restock</div>
            <div className="quick-action-sub">Add a batch to existing stock</div>
          </div>
        </Link>
        {isAdmin && (
          <Link to="/dashboard/reports" className="quick-action">
            <span className="quick-action-icon icon-purple">▲</span>
            <div>
              <div className="quick-action-title">View reports</div>
              <div className="quick-action-sub">Track revenue</div>
            </div>
          </Link>
        )}
      </div>

      <div className="two-col-panels">
        {isAdmin && (
          <div className="panel-card" style={{ boxShadow: '0 8px 24px -12px rgba(0,0,0,0.12)', border: 'none' }}>
            <div className="panel-head">
              <h3>Revenue trend</h3>
              <span className="badge-pill">7 days</span>
            </div>
            {dailySales.length === 0 ? (
              <div className="empty-inline">No sales yet this week.</div>
            ) : (
              <svg viewBox="0 0 600 160" style={{ width: '100%', height: 160 }}>
                <defs>
                  <linearGradient id="revenueFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="var(--primary)" stopOpacity="0.32" />
                    <stop offset="100%" stopColor="var(--primary)" stopOpacity="0" />
                  </linearGradient>
                </defs>
                <path d={area} fill="url(#revenueFill)" />
                <path d={line} fill="none" stroke="var(--primary)" strokeWidth="3" strokeLinecap="round" />
                {points && points.map(([x, y], i) => (
                  <circle key={i} cx={x} cy={y} r="4" fill="#fff" stroke="var(--primary)" strokeWidth="2.5" />
                ))}
              </svg>
            )}
            {dailySales.length > 0 && (
              <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
                {dailySales.map((d) => (
                  <small key={d.date} style={{ color: 'var(--ink-soft)', fontSize: 11 }}>
                    {new Date(d.date).toLocaleDateString(undefined, { weekday: 'short' })}
                  </small>
                ))}
              </div>
            )}
          </div>
        )}

        <div className="panel-card compact-panel" style={{ boxShadow: '0 8px 24px -12px rgba(0,0,0,0.12)', border: 'none' }}>
          <div className="panel-head">
            <h3>Stock health</h3>
            <span className="badge-pill">{healthyPct}%</span>
          </div>
          <div className="donut-wrap">
            <div
              className="donut-chart"
              style={{ background: `conic-gradient(var(--stat-green, #22A06B) ${healthyPct * 3.6}deg, #EEF1F4 0deg)` }}
            >
              <div className="donut-inner">
                <strong>{healthyPct}%</strong>
                <span>Healthy</span>
              </div>
            </div>
            <ul className="legend-list">
              <li><span className="dot dot-green" /> Available ({healthyCount})</li>
              <li><span className="dot dot-gray" /> Needs attention ({allBatches.length - healthyCount})</li>
            </ul>
          </div>
        </div>
      </div>

      <div className="bottom-grid">
        {isAdmin && (
          <div className="panel-card" style={{ boxShadow: '0 8px 24px -12px rgba(0,0,0,0.12)', border: 'none' }}>
            <div className="panel-head"><h3>Top-selling medicines</h3></div>
            {topMedicines.length === 0 ? (
              <div className="empty-inline">No sales recorded yet this month.</div>
            ) : (
              <div className="progress-list">
                {topMedicines.map((m, i) => {
                  const max = topMedicines[0].quantitySold || 1
                  const pct = Math.round((m.quantitySold / max) * 100)
                  return (
                    <div className="progress-row" key={m.medicineName}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                        <span
                          style={{
                            width: 22, height: 22, borderRadius: '50%',
                            background: i === 0 ? 'var(--primary)' : '#EEF1F4',
                            color: i === 0 ? '#fff' : 'var(--ink-soft)',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            fontSize: 11, fontWeight: 800, flexShrink: 0,
                          }}
                        >
                          {i + 1}
                        </span>
                        <div style={{ flex: 1 }}>
                          <div className="progress-meta">
                            <span>{m.medicineName}</span>
                            <span>{m.quantitySold} sold</span>
                          </div>
                          <div className="progress-track">
                            <span style={{ width: `${pct}%`, background: 'var(--primary)' }} />
                          </div>
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        )}

        <div className="panel-card attention-panel" style={{ boxShadow: '0 8px 24px -12px rgba(0,0,0,0.12)', border: 'none' }}>
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

function StatCard({ icon, label, value, sub, accent }) {
  return (
    <div
      className="stat-card"
      style={{
        border: 'none',
        boxShadow: '0 8px 20px -10px rgba(0,0,0,0.14)',
        borderRadius: 16,
      }}
    >
      <div
        style={{
          width: 36, height: 36, borderRadius: 10,
          background: `${accent}20`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 17, marginBottom: 10,
        }}
      >
        {icon}
      </div>
      <div className="stat-label" style={{ textTransform: 'uppercase', fontSize: 11, fontWeight: 700 }}>{label}</div>
      <div className="stat-value" style={{ color: accent, fontSize: 21, fontWeight: 800 }}>{value}</div>
      <div className="stat-sub">{sub}</div>
    </div>
  )
}