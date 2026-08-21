import { useEffect, useState } from 'react'
import api from '../api.js'
import Layout from '../components/Layout.jsx'
import EmptyState from '../components/EmptyState.jsx'

export default function Purchases() {
  const [purchases, setPurchases] = useState([])
  const [suppliers, setSuppliers] = useState([])
  const [medicines, setMedicines] = useState([])
  const [showForm, setShowForm] = useState(false)
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)

  const [supplierId, setSupplierId] = useState('')
  const [items, setItems] = useState([])
  const [draft, setDraft] = useState({ medicineId: '', batchNumber: '', quantity: '', unitPrice: '', expiryDate: '' })

  const supplierName = (id) => suppliers.find((s) => s.id === id)?.name || `#${id}`
  const medicineName = (id) => medicines.find((m) => m.id === id)?.name || `#${id}`

  function load() {
    api.get('/purchases').then(({ data }) => setPurchases(data))
  }

  useEffect(() => {
    load()
    api.get('/suppliers').then(({ data }) => setSuppliers(data))
    api.get('/medicines').then(({ data }) => setMedicines(data))
  }, [])

  function addItem() {
    if (!draft.medicineId || !draft.batchNumber || !draft.quantity || !draft.unitPrice || !draft.expiryDate) return
    setItems([...items, { ...draft, medicineId: Number(draft.medicineId), quantity: Number(draft.quantity), unitPrice: Number(draft.unitPrice) }])
    setDraft({ medicineId: '', batchNumber: '', quantity: '', unitPrice: '', expiryDate: '' })
  }

  function removeItem(idx) {
    setItems(items.filter((_, i) => i !== idx))
  }

  const total = items.reduce((sum, i) => sum + i.quantity * i.unitPrice, 0)

  async function submitPurchase() {
    setError('')
    if (!supplierId || items.length === 0) { setError('Pick a supplier and add at least one item.'); return }
    setSaving(true)
    try {
      await api.post('/purchases', { supplierId: Number(supplierId), items })
      setSupplierId('')
      setItems([])
      setShowForm(false)
      load()
    } catch (err) {
      setError(err.response?.data?.error || 'Could not record the purchase.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Layout
      title="Purchases"
      subtitle="Record stock bought from a supplier."
      actions={<button className="btn-primary btn-compact" onClick={() => setShowForm((v) => !v)}>{showForm ? 'Cancel' : '+ New purchase'}</button>}
    >
      {showForm && (
        <div className="panel">
          <div className="panel-head"><h3>New purchase</h3></div>
          {error && <div className="alert-error">{error}</div>}

          <div className="field">
            <label>Supplier</label>
            <select value={supplierId} onChange={(e) => setSupplierId(e.target.value)}>
              <option value="" disabled>Select supplier…</option>
              {suppliers.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
            </select>
          </div>

          <div className="form-grid" style={{ marginTop: 14 }}>
            <div className="field">
              <label>Medicine</label>
              <select value={draft.medicineId} onChange={(e) => setDraft({ ...draft, medicineId: e.target.value })}>
                <option value="" disabled>Select…</option>
                {medicines.map((m) => <option key={m.id} value={m.id}>{m.name}</option>)}
              </select>
            </div>
            <div className="field">
              <label>Batch number</label>
              <input value={draft.batchNumber} onChange={(e) => setDraft({ ...draft, batchNumber: e.target.value })} placeholder="PB001" />
            </div>
            <div className="field">
              <label>Quantity</label>
              <input type="number" min="1" value={draft.quantity} onChange={(e) => setDraft({ ...draft, quantity: e.target.value })} />
            </div>
            <div className="field">
              <label>Unit price</label>
              <input type="number" step="0.01" min="0" value={draft.unitPrice} onChange={(e) => setDraft({ ...draft, unitPrice: e.target.value })} />
            </div>
            <div className="field">
              <label>Expiry date</label>
              <input type="date" value={draft.expiryDate} onChange={(e) => setDraft({ ...draft, expiryDate: e.target.value })} />
            </div>
            <div className="form-actions">
              <button type="button" className="btn-secondary" onClick={addItem}>Add item</button>
            </div>
          </div>

          {items.length > 0 && (
            <table className="data-table" style={{ marginTop: 18 }}>
              <thead><tr><th>Medicine</th><th>Batch</th><th>Qty</th><th>Unit price</th><th>Line total</th><th></th></tr></thead>
              <tbody>
                {items.map((it, idx) => (
                  <tr key={idx}>
                    <td className="cell-strong">{medicineName(it.medicineId)}</td>
                    <td>{it.batchNumber}</td>
                    <td>{it.quantity}</td>
                    <td>Rs {it.unitPrice}</td>
                    <td>Rs {(it.quantity * it.unitPrice).toFixed(2)}</td>
                    <td><button className="link-danger" onClick={() => removeItem(idx)}>Remove</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}

          {items.length > 0 && (
            <div className="cart-total"><span>Total</span><span>Rs {total.toFixed(2)}</span></div>
          )}

          <button className="btn-primary" onClick={submitPurchase} disabled={saving} style={{ marginTop: 16 }}>
            {saving ? 'Saving…' : 'Record purchase'}
          </button>
        </div>
      )}

      <div className="panel">
        <div className="panel-head"><h3>Purchase history</h3></div>
        {purchases.length === 0 ? (
          <EmptyState text="No purchases recorded yet." />
        ) : (
          <table className="data-table">
            <thead><tr><th>Date</th><th>Supplier</th><th>Total</th></tr></thead>
            <tbody>
              {purchases.map((p) => (
                <tr key={p.id}>
                  <td>{new Date(p.purchaseDate).toLocaleDateString()}</td>
                  <td className="cell-strong">{supplierName(p.supplier?.id)}</td>
                  <td>Rs {p.totalAmount}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </Layout>
  )
}
