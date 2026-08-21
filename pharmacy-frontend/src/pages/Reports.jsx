import { useEffect, useState } from 'react'
import api from '../api.js'
import Layout from '../components/Layout.jsx'
import StatCard from '../components/StatCard.jsx'

function currentMonth() {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
}

export default function Reports() {
  const [month, setMonth] = useState(currentMonth())
  const [report, setReport] = useState(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  function load(m) {
    setLoading(true)
    setError('')
    api.get(`/reports/profit?month=${m}`)
      .then(({ data }) => setReport(data))
      .catch(() => setError('Could not load the report for this month.'))
      .finally(() => setLoading(false))
  }

  useEffect(() => { load(month) }, [])

  return (
    <Layout title="Reports" subtitle="Monthly profit — sales minus stock cost minus refunds.">
      <div className="panel">
        <div className="panel-head">
          <h3>Select month</h3>
          <input
            type="month"
            value={month}
            onChange={(e) => { setMonth(e.target.value); load(e.target.value) }}
          />
        </div>

        {error && <div className="alert-error">{error}</div>}

        {loading ? (
          <div className="empty-state">Loading…</div>
        ) : report && (
          <>
            <div className="stat-grid" style={{ marginTop: 8 }}>
              <StatCard label="Total sales" value={`Rs ${Number(report.totalSales).toLocaleString()}`} />
              <StatCard label="Stock cost" value={`Rs ${Number(report.totalCost).toLocaleString()}`} />
              <StatCard label="Refunds" value={`Rs ${Number(report.totalRefunds).toLocaleString()}`} tone={Number(report.totalRefunds) > 0 ? 'warn' : 'neutral'} />
              <StatCard
                label="Net profit"
                value={`Rs ${Number(report.netProfit).toLocaleString()}`}
                tone={Number(report.netProfit) >= 0 ? 'good' : 'bad'}
                hint={report.month}
              />
            </div>
          </>
        )}
      </div>
    </Layout>
  )
}
