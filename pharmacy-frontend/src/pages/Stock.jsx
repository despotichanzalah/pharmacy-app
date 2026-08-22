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
  const [entryMode, setEntryMode] = useState('units') // 'units' | 'packs'
  const [packsCount, setPacksCount] = useState('')
  const [priceMode, setPriceMode] = useState('perUnit') // 'perUnit' | 'perPack'
  const [packPurchasePrice, setPackPurchasePrice] = useState('')
  const [packSalePrice, setPackSalePrice] = useState('')

  const selectedMedicine = medicines.find((m) => m.id === Number(form.medicineId))
  const packSize = selectedMedicine?.packSize || 1

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
    const finalQuantity = entryMode === 'packs' ? Number(packsCount) * packSize : Number(form.quantity)
    const finalPurchasePrice = priceMode === 'perPack' ? Number(packPurchasePrice) / packSize : Number(form.purchasePrice)
    const finalSalePrice = priceMode === 'perPack' ? Number(packSalePrice) / packSize : Number(form.salePrice)
    try {
      await api.post('/batches', {
        ...form,
        medicineId: Number(form.medicineId),
        quantity: finalQuantity,
        purchasePrice: finalPurchasePrice,
        salePrice: finalSalePrice,
      })
      setForm({ medicineId: '', batchNumber: '', quantity: '', purchasePrice: '', salePrice: '', expiryDate: '' })
      setPacksCount('')
      setPackPurchasePrice('')
      setPackSalePrice('')
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

            {packSize > 1 && (
              <div className="tab-row" style={{ marginBottom: 0 }}>
                <button type="button" className={`tab-pill ${entryMode === 'units' ? 'active' : ''}`} onClick={() => setEntryMode('units')}>Enter loose units</button>
                <button type="button" className={`tab-pill ${entryMode === 'packs' ? 'active' : ''}`} onClick={() => setEntryMode('packs')}>Enter packs (×{packSize})</button>
              </div>
            )}

            {entryMode === 'packs' && packSize > 1 ? (
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

            {packSize > 1 && (
              <div className="tab-row" style={{ marginBottom: 0 }}>
                <button type="button" className={`tab-pill ${priceMode === 'perUnit' ? 'active' : ''}`} onClick={() => setPriceMode('perUnit')}>Price per unit</button>
                <button type="button" className={`tab-pill ${priceMode === 'perPack' ? 'active' : ''}`} onClick={() => setPriceMode('perPack')}>Price per pack</button>
              </div>
            )}

            {priceMode === 'perPack' && packSize > 1 ? (
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
