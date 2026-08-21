import { useEffect, useState } from 'react'
import api from '../api.js'
import Layout from '../components/Layout.jsx'
import EmptyState from '../components/EmptyState.jsx'

export default function Returns() {
  const [sales, setSales] = useState([])
  const [medicines, setMedicines] = useState([])
  const [batches, setBatches] = useState([])
  const [saleId, setSaleId] = useState('')
  const [saleItems, setSaleItems] = useState([])
  const [reason, setReason] = useState('')
  const [qtyByItem, setQtyByItem] = useState({})
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [saving, setSaving] = useState(false)

  const medicineName = (id) => medicines.find((m) => m.id === id)?.name || `#${id}`
  const batchFor = (id) => batches.find((b) => b.id === id)

  useEffect(() => {
    api.get('/sales').then(({ data }) => setSales(data))
    api.get('/medicines').then(({ data }) => setMedicines(data))
    api.get('/batches/low-stock?threshold=999999').then(({ data }) => setBatches(data))
  }, [])

  useEffect(() => {
    if (!saleId) { setSaleItems([]); return }
    api.get(`/sales/${saleId}/items`).then(({ data }) => {
      setSaleItems(data)
      setQtyByItem({})
    })
  }, [saleId])

  async function submitReturn() {
    setError('')
    setSuccess('')
    const items = Object.entries(qtyByItem)
      .filter(([, qty]) => Number(qty) > 0)
      .map(([saleItemId, quantity]) => ({ saleItemId: Number(saleItemId), quantity: Number(quantity) }))

    if (items.length === 0) { setError('Enter a quantity to return for at least one item.'); return }

    setSaving(true)
    try {
      const { data } = await api.post('/returns', { saleId: Number(saleId), reason, items })
      setSuccess(`Return recorded — refund Rs ${data.refundAmount}`)
      setQtyByItem({})
      setReason('')
    } catch (err) {
      setError(err.response?.data?.error || 'Could not process the return.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Layout title="Returns" subtitle="Return part or all of a previous sale — stock goes back automatically.">
      <div className="panel">
        <div className="panel-head"><h3>Find the sale</h3></div>

        {sales.length === 0 ? (
          <EmptyState text="No sales recorded yet." />
        ) : (
          <div className="field">
            <label>Sale</label>
            <select value={saleId} onChange={(e) => setSaleId(e.target.value)}>
              <option value="" disabled>Select a sale…</option>
              {sales.map((s) => (
                <option key={s.id} value={s.id}>
                  Sale #{s.id} — {s.customerName || 'Walk-in'} — Rs {s.totalAmount} — {new Date(s.saleDate).toLocaleDateString()}
                </option>
              ))}
            </select>
            <div className="field-hint">Pick a sale above — its items and the return button will appear below.</div>
          </div>
        )}
      </div>

      {saleItems.length > 0 && (
        <div className="panel">
          <div className="panel-head"><h3>Items sold</h3></div>

          {error && <div className="alert-error">{error}</div>}
          {success && <div className="alert-success">{success}</div>}

          <table className="data-table">
            <thead><tr><th>Medicine</th><th>Batch</th><th>Sold qty</th><th>Return qty</th></tr></thead>
            <tbody>
              {saleItems.map((item) => {
                const batch = batchFor(item.batch?.id)
                return (
                  <tr key={item.id}>
                    <td className="cell-strong">{batch ? medicineName(batch.medicine?.id) : `Batch #${item.batch?.id}`}</td>
                    <td>{batch?.batchNumber || '—'}</td>
                    <td>{item.quantity}</td>
                    <td>
                      <input
                        type="number" min="0" max={item.quantity}
                        style={{ width: 80 }}
                        value={qtyByItem[item.id] || ''}
                        onChange={(e) => setQtyByItem((q) => ({ ...q, [item.id]: e.target.value }))}
                      />
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>

          <div className="field" style={{ marginTop: 18 }}>
            <label>Reason (optional)</label>
            <input value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Customer changed mind, damaged, etc." />
          </div>

          <button className="btn-primary" onClick={submitReturn} disabled={saving}>
            {saving ? 'Processing…' : 'Process return'}
          </button>
        </div>
      )}
    </Layout>
  )
}
