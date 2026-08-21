import { useEffect, useState } from 'react'
import api from '../api.js'
import Layout from '../components/Layout.jsx'
import EmptyState from '../components/EmptyState.jsx'

export default function Stock() {
  const [tab, setTab] = useState('all')
  const [batches, setBatches] = useState([])
  const [medicines, setMedicines] = useState([])
  const [showForm, setShowForm] = useState(false)
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState({
    medicineId: '', batchNumber: '', quantity: '', purchasePrice: '', salePrice: '', expiryDate: '',
  })

  const medicineName = (id) => medicines.find((m) => m.id === id)?.name || `#${id}`

  function loadBatches(which) {
    const url =
      which === 'low' ? '/batches/low-stock?threshold=10' :
      which === 'expiring' ? '/batches/expiring?days=30' :
      '/batches/low-stock?threshold=999999' // pragmatic "list all"
    api.get(url).then(({ data }) => setBatches(data))
  }

  useEffect(() => {
    api.get('/medicines').then(({ data }) => setMedicines(data))
    loadBatches(tab)
  }, [tab])

  function update(field, value) {
    setForm((f) => ({ ...f, [field]: value }))
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setSaving(true)
    try {
      await api.post('/batches', {
        ...form,
        medicineId: Number(form.medicineId),
        quantity: Number(form.quantity),
        purchasePrice: Number(form.purchasePrice),
        salePrice: Number(form.salePrice),
      })
      setForm({ medicineId: '', batchNumber: '', quantity: '', purchasePrice: '', salePrice: '', expiryDate: '' })
      setShowForm(false)
      loadBatches(tab)
    } catch (err) {
      setError(err.response?.data?.error || 'Could not add the batch.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Layout
      title="Stock"
      subtitle="Batches carry expiry, cost, and sale price for every strip of stock."
      actions={<button className="btn-primary btn-compact" onClick={() => setShowForm((v) => !v)}>{showForm ? 'Cancel' : '+ Add batch'}</button>}
    >
      {showForm && (
        <div className="panel">
          <div className="panel-head"><h3>New batch</h3></div>
          {error && <div className="alert-error">{error}</div>}
          <form className="form-grid" onSubmit={handleSubmit}>
            <div className="field">
              <label>Medicine</label>
              <select required value={form.medicineId} onChange={(e) => update('medicineId', e.target.value)}>
                <option value="" disabled>Select medicine…</option>
                {medicines.map((m) => <option key={m.id} value={m.id}>{m.name}</option>)}
              </select>
            </div>
            <div className="field">
              <label>Batch number</label>
              <input required value={form.batchNumber} onChange={(e) => update('batchNumber', e.target.value)} placeholder="BATCH001" />
            </div>
            <div className="field">
              <label>Quantity</label>
              <input required type="number" min="0" value={form.quantity} onChange={(e) => update('quantity', e.target.value)} />
            </div>
            <div className="field">
              <label>Expiry date</label>
              <input required type="date" value={form.expiryDate} onChange={(e) => update('expiryDate', e.target.value)} />
            </div>
            <div className="field">
              <label>Purchase price</label>
              <input required type="number" step="0.01" min="0" value={form.purchasePrice} onChange={(e) => update('purchasePrice', e.target.value)} />
            </div>
            <div className="field">
              <label>Sale price</label>
              <input required type="number" step="0.01" min="0" value={form.salePrice} onChange={(e) => update('salePrice', e.target.value)} />
            </div>
            <div className="form-actions">
              <button className="btn-primary" type="submit" disabled={saving}>{saving ? 'Saving…' : 'Save batch'}</button>
            </div>
          </form>
        </div>
      )}

      <div className="panel">
        <div className="tab-row">
          <button className={`tab-pill ${tab === 'all' ? 'active' : ''}`} onClick={() => setTab('all')}>All stock</button>
          <button className={`tab-pill ${tab === 'low' ? 'active' : ''}`} onClick={() => setTab('low')}>Low stock</button>
          <button className={`tab-pill ${tab === 'expiring' ? 'active' : ''}`} onClick={() => setTab('expiring')}>Expiring soon</button>
        </div>

        {batches.length === 0 ? (
          <EmptyState text="No batches here." />
        ) : (
          <table className="data-table">
            <thead>
              <tr><th>Medicine</th><th>Batch #</th><th>Qty</th><th>Expiry</th><th>Purchase</th><th>Sale</th></tr>
            </thead>
            <tbody>
              {batches.map((b) => (
                <tr key={b.id}>
                  <td className="cell-strong">{medicineName(b.medicine?.id)}</td>
                  <td>{b.batchNumber}</td>
                  <td>{b.quantity <= 10 ? <span className="badge badge-warn">{b.quantity}</span> : b.quantity}</td>
                  <td>{b.expiryDate}</td>
                  <td>Rs {b.purchasePrice}</td>
                  <td>Rs {b.salePrice}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </Layout>
  )
}
