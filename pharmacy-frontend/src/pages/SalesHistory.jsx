import { useEffect, useState } from 'react'
import api from '../api.js'
import Layout from '../components/Layout.jsx'
import EmptyState from '../components/EmptyState.jsx'

export default function SalesHistory() {
  const [sales, setSales] = useState([])
  const [medicines, setMedicines] = useState([])
  const [batches, setBatches] = useState([])
  const [loading, setLoading] = useState(true)
  const [expandedId, setExpandedId] = useState(null)
  const [itemsBySale, setItemsBySale] = useState({})

  const medicineName = (id) => medicines.find((m) => m.id === id)?.name || `#${id}`
  const batchById = (id) => batches.find((b) => b.id === id)

  useEffect(() => {
    Promise.all([
      api.get('/sales'),
      api.get('/medicines'),
      api.get('/batches/low-stock?threshold=999999'),
    ]).then(([salesRes, medRes, batchRes]) => {
      setSales(salesRes.data)
      setMedicines(medRes.data)
      setBatches(batchRes.data)
      setLoading(false)
    })
  }, [])

  async function toggleExpand(saleId) {
    if (expandedId === saleId) {
      setExpandedId(null)
      return
    }
    setExpandedId(saleId)
    if (!itemsBySale[saleId]) {
      const { data } = await api.get(`/sales/${saleId}/items`)
      setItemsBySale((prev) => ({ ...prev, [saleId]: data }))
    }
  }

  return (
    <Layout title="Sales History" subtitle="Every sale ever recorded at this shop, newest first.">
      <div className="panel">
        {loading ? (
          <EmptyState text="Loading…" />
        ) : sales.length === 0 ? (
          <EmptyState text="No sales recorded yet." />
        ) : (
          <table className="data-table">
            <thead>
              <tr><th>Sale #</th><th>Date</th><th>Customer</th><th>Discount</th><th>Total</th><th></th></tr>
            </thead>
            <tbody>
              {sales.map((s) => (
                <>
                  <tr key={s.id}>
                    <td className="cell-strong">#{s.id}</td>
                    <td>{new Date(s.saleDate).toLocaleString()}</td>
                    <td>{s.customerName || 'Walk-in'}</td>
                    <td>{s.discountPercent > 0 ? `${s.discountPercent}%` : '—'}</td>
                    <td>Rs {s.totalAmount}</td>
                    <td>
                      <button className="link-danger" style={{ color: 'var(--primary-dark)' }} onClick={() => toggleExpand(s.id)}>
                        {expandedId === s.id ? 'Hide items' : 'View items'}
                      </button>
                    </td>
                  </tr>
                  {expandedId === s.id && (
                    <tr>
                      <td colSpan={6} style={{ background: 'var(--surface)', padding: 0 }}>
                        <div style={{ padding: '14px 20px' }}>
                          {!itemsBySale[s.id] ? (
                            <span style={{ color: 'var(--ink-soft)' }}>Loading items…</span>
                          ) : (
                            <table className="data-table" style={{ margin: 0 }}>
                              <thead><tr><th>Medicine</th><th>Batch</th><th>Qty</th><th>Price</th><th>Line total</th></tr></thead>
                              <tbody>
                                {itemsBySale[s.id].map((it) => {
                                  const batch = batchById(it.batch?.id)
                                  return (
                                    <tr key={it.id}>
                                      <td>{medicineName(batch?.medicine?.id)}</td>
                                      <td>{batch?.batchNumber || '—'}</td>
                                      <td>{it.quantity}</td>
                                      <td>Rs {it.price}</td>
                                      <td>Rs {(it.quantity * it.price).toFixed(2)}</td>
                                    </tr>
                                  )
                                })}
                              </tbody>
                            </table>
                          )}
                        </div>
                      </td>
                    </tr>
                  )}
                </>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </Layout>
  )
}
