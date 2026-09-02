import { useEffect, useState } from 'react'
import api from '../api.js'
import Layout from '../components/Layout.jsx'
import EmptyState from '../components/EmptyState.jsx'

const EMPTY_FORM = { medicineId: '', batchNumber: '', quantity: '', purchasePrice: '', salePrice: '', expiryDate: '' }

export default function Stock() {
  const [tab, setTab] = useState('all')
  const [batches, setBatches] = useState([])
  const [medicines, setMedicines] = useState([])
  const [showForm, setShowForm] = useState(false)
  const [editingId, setEditingId] = useState(null)
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState(EMPTY_FORM)
  const [entryMode, setEntryMode] = useState('units')
  const [packsCount, setPacksCount] = useState('')
  const [priceMode, setPriceMode] = useState('perUnit')
  const [packPurchasePrice, setPackPurchasePrice] = useState('')
  const [packSalePrice, setPackSalePrice] = useState('')

  const selectedMedicine = medicines.find((m) => m.id === Number(form.medicineId))
  const packSize = selectedMedicine?.packSize || 1

  const medicineName = (id) => medicines.find((m) => m.id === id)?.name || `#${id}`

  function loadBatches(which) {
    const url =
      which === 'low' ? '/batches/low-stock?threshold=10' :
      which === 'expiring' ? '/batches/expiring?days=30' :
      '/batches/low-stock?threshold=999999'
    api.get(url).then(({ data }) => {
      const filtered = which === 'all' ? data.filter((b) => b.quantity > 0) : data
      setBatches(filtered)
    })
  }

  useEffect(() => {
    api.get('/medicines').then(({ data }) => setMedicines(data))
    loadBatches(tab)
  }, [tab])

  function update(field, value) {
    setForm((f) => ({ ...f, [field]: value }))
  }

  function resetPackHelpers() {
    setEntryMode('units')
    setPacksCount('')
    setPriceMode('perUnit')
    setPackPurchasePrice('')
    setPackSalePrice('')
  }

  function startAdd() {
    setEditingId(null)
    setForm(EMPTY_FORM)
    resetPackHelpers()
    setError('')
    setShowForm(true)
  }

  function startEdit(b) {
    setEditingId(b.id)
    setForm({
      medicineId: b.medicine?.id || '',
      batchNumber: b.batchNumber,
      quantity: b.quantity,
      purchasePrice: b.purchasePrice,
      salePrice: b.salePrice,
      expiryDate: b.expiryDate,
    })
    resetPackHelpers()
    setError('')
    setShowForm(true)
  }

  function cancelForm() {
    setShowForm(false)
    setEditingId(null)
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setSaving(true)
    const finalQuantity = entryMode === 'packs' ? Number(packsCount) * packSize : Number(form.quantity)
    const finalPurchasePrice = priceMode === 'perPack' ? Number(packPurchasePrice) / packSize : Number(form.purchasePrice)
    const finalSalePrice = priceMode === 'perPack' ? Number(packSalePrice) / packSize : Number(form.salePrice)
    try {
      const payload = {
        ...form,
        medicineId: Number(form.medicineId),
        quantity: finalQuantity,
        purchasePrice: finalPurchasePrice,
        salePrice: finalSalePrice,
      }
      if (editingId) {
        await api.put(`/batches/${editingId}`, payload)
      } else {
        await api.post('/batches', payload)
      }
      cancelForm()
      loadBatches(tab)
    } catch (err) {
      setError(err.response?.data?.error || 'Could not save the batch.')
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete(b) {
    if (!window.confirm(`Delete batch ${b.batchNumber}? This can't be undone.`)) return
    try {
      await api.delete(`/batches/${b.id}`)
      loadBatches(tab)
    } catch (err) {
      alert(err.response?.data?.error || 'Could not delete this batch.')
    }
  }

  return (
    <Layout
      title="Stock"
      subtitle="Restock an existing medicine here — new medicines get their first batch from the Medicines page."
      actions={<button className="btn-primary btn-compact" onClick={() => (showForm ? cancelForm() : startAdd())}>{showForm ? 'Cancel' : '+ Restock'}</button>}
    >
      {showForm && (
        <div className="panel">
          <div className="panel-head"><h3>{editingId ? 'Edit batch' : 'Restock a medicine'}</h3></div>
          {error && <div className="alert-error">{error}</div>}
          <form className="form-grid" onSubmit={handleSubmit}>
            <div className="field">
              <label>Medicine</label>
              <select required value={form.medicineId} onChange={(e) => update('medicineId', e.target.value)} disabled={!!editingId}>
                <option value="" disabled>Select medicine…</option>
                {medicines.map((m) => <option key={m.id} value={m.id}>{m.name}</option>)}
              </select>
            </div>
            <div className="field">
              <label>Batch number</label>
              <input required value={form.batchNumber} onChange={(e) => update('batchNumber', e.target.value)} placeholder="BATCH001" />
            </div>

            {!editingId && packSize > 1 && (
              <div className="tab-row" style={{ marginBottom: 0 }}>
                <button type="button" className={`tab-pill ${entryMode === 'units' ? 'active' : ''}`} onClick={() => setEntryMode('units')}>Enter loose units</button>
                <button type="button" className={`tab-pill ${entryMode === 'packs' ? 'active' : ''}`} onClick={() => setEntryMode('packs')}>Enter packs (×{packSize})</button>
              </div>
            )}

            {!editingId && entryMode === 'packs' && packSize > 1 ? (
              <div className="field">
                <label>Number of packs</label>
                <input required type="number" min="1" value={packsCount} onChange={(e) => setPacksCount(e.target.value)} placeholder={`e.g. 5 strips of ${packSize}`} />
                <div className="field-hint">= {Number(packsCount || 0) * packSize} total units in stock</div>
              </div>
            ) : (
              <div className="field">
                <label>Quantity (units)</label>
                <input required type="number" min="0" value={form.quantity} onChange={(e) => update('quantity', e.target.value)} />
              </div>
            )}

            <div className="field">
              <label>Expiry date</label>
              <input required type="date" value={form.expiryDate} onChange={(e) => update('expiryDate', e.target.value)} />
            </div>

            {!editingId && packSize > 1 && (
              <div className="tab-row" style={{ marginBottom: 0 }}>
                <button type="button" className={`tab-pill ${priceMode === 'perUnit' ? 'active' : ''}`} onClick={() => setPriceMode('perUnit')}>Price per unit</button>
                <button type="button" className={`tab-pill ${priceMode === 'perPack' ? 'active' : ''}`} onClick={() => setPriceMode('perPack')}>Price per pack</button>
              </div>
            )}

            {!editingId && priceMode === 'perPack' && packSize > 1 ? (
              <>
                <div className="field">
                  <label>Purchase price (per pack)</label>
                  <input required type="number" step="0.01" min="0" value={packPurchasePrice} onChange={(e) => setPackPurchasePrice(e.target.value)} />
                  <div className="field-hint">= Rs {(Number(packPurchasePrice || 0) / packSize).toFixed(2)} per unit</div>
                </div>
                <div className="field">
                  <label>Sale price (per pack)</label>
                  <input required type="number" step="0.01" min="0" value={packSalePrice} onChange={(e) => setPackSalePrice(e.target.value)} />
                  <div className="field-hint">= Rs {(Number(packSalePrice || 0) / packSize).toFixed(2)} per unit</div>
                </div>
              </>
            ) : (
              <>
                <div className="field">
                  <label>Purchase price (per unit)</label>
                  <input required type="number" step="0.01" min="0" value={form.purchasePrice} onChange={(e) => update('purchasePrice', e.target.value)} />
                </div>
                <div className="field">
                  <label>Sale price (per unit)</label>
                  <input required type="number" step="0.01" min="0" value={form.salePrice} onChange={(e) => update('salePrice', e.target.value)} />
                </div>
              </>
            )}
            <div className="form-actions" style={{ gap: 10 }}>
              <button className="btn-primary" type="submit" disabled={saving}>{saving ? 'Saving…' : editingId ? 'Save changes' : 'Save batch'}</button>
              <button className="btn-secondary" type="button" onClick={cancelForm}>Cancel</button>
            </div>
          </form>
        </div>
      )}

      <div className="panel">
        <div className="tab-row">
          <button className={`tab-pill ${tab === 'all' ? 'active' : ''}`} onClick={() => setTab('all')}>Active stock</button>
          <button className={`tab-pill ${tab === 'low' ? 'active' : ''}`} onClick={() => setTab('low')}>Low stock</button>
          <button className={`tab-pill ${tab === 'expiring' ? 'active' : ''}`} onClick={() => setTab('expiring')}>Expiring soon</button>
        </div>

        {batches.length === 0 ? (
          <EmptyState text={tab === 'all' ? 'No active stock. Depleted batches show under each medicine on the Medicines page.' : 'No batches here.'} />
        ) : (
          <table className="data-table">
            <thead>
              <tr><th>Medicine</th><th>Batch #</th><th>Qty</th><th>Expiry</th><th>Purchase</th><th>Sale</th><th></th></tr>
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
                  <td style={{ whiteSpace: 'nowrap' }}>
                    <button className="link-danger" style={{ color: 'var(--primary-dark)', marginRight: 14 }} onClick={() => startEdit(b)}>Edit</button>
                    <button className="link-danger" onClick={() => handleDelete(b)}>Delete</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </Layout>
  )
}