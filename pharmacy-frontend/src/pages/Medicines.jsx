import { useEffect, useState } from 'react'
import api from '../api.js'
import Layout from '../components/Layout.jsx'
import EmptyState from '../components/EmptyState.jsx'

const EMPTY_FORM = { name: '', unit: '', reorderLevel: 10, packSize: 1 }
const EMPTY_BATCH = { batchNumber: '', quantity: '', expiryDate: '', purchasePrice: '', salePrice: '' }

export default function Medicines() {
  const [medicines, setMedicines] = useState([])
  const [genericsList, setGenericsList] = useState([])
  const [query, setQuery] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editingId, setEditingId] = useState(null)
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState(EMPTY_FORM)
  const [selectedGenerics, setSelectedGenerics] = useState([])
  const [genericInput, setGenericInput] = useState('')

  const [batch, setBatch] = useState(EMPTY_BATCH)
  const [entryMode, setEntryMode] = useState('units')
  const [packsCount, setPacksCount] = useState('')
  const [priceMode, setPriceMode] = useState('perUnit')
  const [packPurchasePrice, setPackPurchasePrice] = useState('')
  const [packSalePrice, setPackSalePrice] = useState('')

  const [historyMedicine, setHistoryMedicine] = useState(null)
  const [historyBatches, setHistoryBatches] = useState([])
  const [historyLoading, setHistoryLoading] = useState(false)

  const packSize = Number(form.packSize) || 1

  function load(q = '') {
    api.get(`/medicines${q ? `?query=${encodeURIComponent(q)}` : ''}`).then(({ data }) => setMedicines(data))
  }

  useEffect(() => {
    load()
    api.get('/generics').then(({ data }) => setGenericsList(data))
  }, [])

  function update(field, value) {
    setForm((f) => ({ ...f, [field]: value }))
  }

  function updateBatch(field, value) {
    setBatch((b) => ({ ...b, [field]: value }))
  }

  function addGenericChip() {
    const name = genericInput.trim()
    if (!name) return
    if (selectedGenerics.some((g) => g.name.toLowerCase() === name.toLowerCase())) {
      setGenericInput('')
      return
    }
    const existing = genericsList.find((g) => g.name.toLowerCase() === name.toLowerCase())
    setSelectedGenerics((list) => [...list, existing ? { id: existing.id, name: existing.name } : { name, isNew: true }])
    setGenericInput('')
  }

  function removeGenericChip(name) {
    setSelectedGenerics((list) => list.filter((g) => g.name !== name))
  }

  function resetBatchHelpers() {
    setBatch(EMPTY_BATCH)
    setEntryMode('units')
    setPacksCount('')
    setPriceMode('perUnit')
    setPackPurchasePrice('')
    setPackSalePrice('')
  }

  function startAdd() {
    setEditingId(null)
    setForm(EMPTY_FORM)
    setSelectedGenerics([])
    resetBatchHelpers()
    setError('')
    setShowForm(true)
  }

  function startEdit(m) {
    setEditingId(m.id)
    setForm({ name: m.name, unit: m.unit || '', reorderLevel: m.reorderLevel, packSize: m.packSize || 1 })
    setSelectedGenerics((m.generics || []).map((g) => ({ id: g.id, name: g.name })))
    resetBatchHelpers()
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

    const medicinePayload = {
      ...form,
      reorderLevel: Number(form.reorderLevel),
      packSize: Number(form.packSize) || 1,
      genericIds: selectedGenerics.filter((g) => g.id).map((g) => g.id),
      newGenerics: selectedGenerics.filter((g) => g.isNew).map((g) => g.name),
    }

    try {
      if (editingId) {
        await api.put(`/medicines/${editingId}`, medicinePayload)
      } else {
        const { data: newMedicine } = await api.post('/medicines', medicinePayload)

        const finalQuantity = entryMode === 'packs' ? Number(packsCount) * packSize : Number(batch.quantity)
        const finalPurchasePrice = priceMode === 'perPack' ? Number(packPurchasePrice) / packSize : Number(batch.purchasePrice)
        const finalSalePrice = priceMode === 'perPack' ? Number(packSalePrice) / packSize : Number(batch.salePrice)

        await api.post('/batches', {
          medicineId: newMedicine.id,
          batchNumber: batch.batchNumber,
          quantity: finalQuantity,
          expiryDate: batch.expiryDate,
          purchasePrice: finalPurchasePrice,
          salePrice: finalSalePrice,
        })
      }
      cancelForm()
      load(query)
      api.get('/generics').then(({ data }) => setGenericsList(data))
    } catch (err) {
      setError(err.response?.data?.error || 'Could not save the medicine.')
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete(m) {
    if (!window.confirm(`Delete "${m.name}"? This can't be undone.`)) return
    try {
      await api.delete(`/medicines/${m.id}`)
      load(query)
    } catch (err) {
      alert(err.response?.data?.error || 'Could not delete this medicine.')
    }
  }

  async function openHistory(m) {
    setHistoryMedicine(m)
    setHistoryLoading(true)
    try {
      const { data } = await api.get(`/batches?medicineId=${m.id}`)
      setHistoryBatches(data)
    } catch (err) {
      setHistoryBatches([])
    } finally {
      setHistoryLoading(false)
    }
  }

  return (
    <Layout
      title="Medicines"
      subtitle="Your shop's catalog — search, add, and keep names consistent for stock and sales."
      actions={<button className="btn-primary btn-compact" onClick={() => (showForm ? cancelForm() : startAdd())}>{showForm ? 'Cancel' : '+ Add medicine'}</button>}
    >
      {showForm && (
        <div className="panel">
          <div className="panel-head"><h3>{editingId ? 'Edit medicine' : 'New medicine'}</h3></div>
          {error && <div className="alert-error">{error}</div>}
          <form onSubmit={handleSubmit}>
            <div className="form-grid">
              <div className="field">
                <label>Company / brand name</label>
                <input required value={form.name} onChange={(e) => update('name', e.target.value)} placeholder="Panadol Extra" />
              </div>
              <div className="field">
                <label>Unit</label>
                <input value={form.unit} onChange={(e) => update('unit', e.target.value)} placeholder="tablet, syrup, box…" />
              </div>
              <div className="field">
                <label>Pack size</label>
                <input type="number" min="1" value={form.packSize} onChange={(e) => update('packSize', e.target.value)} placeholder="e.g. 10" />
                <div className="field-hint">Units per strip/box. Leave as 1 if sold only as single units.</div>
              </div>
              <div className="field">
                <label>Reorder level</label>
                <input type="number" min="0" value={form.reorderLevel} onChange={(e) => update('reorderLevel', e.target.value)} />
              </div>
            </div>

            <div className="field" style={{ marginTop: 6 }}>
              <label>Generic / formula (add one or more)</label>
              <div className="chip-input-row">
                <input
                  list="generics-datalist"
                  value={genericInput}
                  onChange={(e) => setGenericInput(e.target.value)}
                  onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addGenericChip() } }}
                  placeholder="Type or pick a generic — e.g. Paracetamol"
                />
                <datalist id="generics-datalist">
                  {genericsList.map((g) => <option key={g.id} value={g.name} />)}
                </datalist>
                <button type="button" className="btn-secondary btn-compact" onClick={addGenericChip}>Add</button>
              </div>
              <div className="field-hint">Not in the list? Just type the name and press Add — it'll be saved for next time.</div>

              {selectedGenerics.length > 0 && (
                <div className="chip-row">
                  {selectedGenerics.map((g) => (
                    <span key={g.name} className="chip">
                      {g.name}
                      <button type="button" onClick={() => removeGenericChip(g.name)}>×</button>
                    </span>
                  ))}
                </div>
              )}
            </div>

            {!editingId && (
              <>
                <div className="panel-head" style={{ marginTop: 22, marginBottom: 8 }}>
                  <h3 style={{ fontSize: 15 }}>Initial stock</h3>
                  <span style={{ color: 'var(--ink-soft)', fontSize: 13 }}>Every new medicine needs its first batch — add it here.</span>
                </div>

                <div className="form-grid">
                  <div className="field">
                    <label>Batch number</label>
                    <input required value={batch.batchNumber} onChange={(e) => updateBatch('batchNumber', e.target.value)} placeholder="BATCH001" />
                  </div>

                  {packSize > 1 && (
                    <div className="tab-row" style={{ marginBottom: 0, gridColumn: '1 / -1' }}>
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
                      <input required type="number" min="0" value={batch.quantity} onChange={(e) => updateBatch('quantity', e.target.value)} />
                    </div>
                  )}

                  <div className="field">
                    <label>Expiry date</label>
                    <input required type="date" value={batch.expiryDate} onChange={(e) => updateBatch('expiryDate', e.target.value)} />
                  </div>

                  {packSize > 1 && (
                    <div className="tab-row" style={{ marginBottom: 0, gridColumn: '1 / -1' }}>
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
                        <input required type="number" step="0.01" min="0" value={batch.purchasePrice} onChange={(e) => updateBatch('purchasePrice', e.target.value)} />
                      </div>
                      <div className="field">
                        <label>Sale price (per unit)</label>
                        <input required type="number" step="0.01" min="0" value={batch.salePrice} onChange={(e) => updateBatch('salePrice', e.target.value)} />
                      </div>
                    </>
                  )}
                </div>
              </>
            )}

            <div className="form-actions" style={{ marginTop: 18, gap: 10 }}>
              <button className="btn-primary" type="submit" disabled={saving}>{saving ? 'Saving…' : editingId ? 'Save changes' : 'Save medicine'}</button>
              <button className="btn-secondary" type="button" onClick={cancelForm}>Cancel</button>
            </div>
          </form>
        </div>
      )}

      <div className="panel">
        <div className="panel-head">
          <h3>Catalog</h3>
          <input
            className="search-input"
            placeholder="Search medicines or generics…"
            value={query}
            onChange={(e) => { setQuery(e.target.value); load(e.target.value) }}
          />
        </div>

        {medicines.length === 0 ? (
          <EmptyState text="No medicines yet — add your first one above." />
        ) : (
          <table className="data-table">
            <thead>
              <tr><th>Name</th><th>Generic(s)</th><th>Unit</th><th>Pack size</th><th>Reorder level</th><th></th></tr>
            </thead>
            <tbody>
              {medicines.map((m) => (
                <tr key={m.id}>
                  <td className="cell-strong">
                    <button type="button" onClick={() => openHistory(m)} style={{ background: 'none', border: 'none', padding: 0, font: 'inherit', color: 'inherit', cursor: 'pointer', textDecoration: 'underline dotted' }}>
                      {m.name}
                    </button>
                  </td>
                  <td>
                    {m.generics && m.generics.length > 0
                      ? m.generics.map((g) => <span key={g.id} className="chip chip-static">{g.name}</span>)
                      : '—'}
                  </td>
                  <td>{m.unit || '—'}</td>
                  <td>{m.packSize > 1 ? `${m.packSize} per pack` : 'Single unit'}</td>
                  <td>{m.reorderLevel}</td>
                  <td style={{ whiteSpace: 'nowrap' }}>
                    <button className="link-danger" style={{ color: 'var(--primary-dark)', marginRight: 14 }} onClick={() => startEdit(m)}>Edit</button>
                    <button className="link-danger" onClick={() => handleDelete(m)}>Delete</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {historyMedicine && (
        <div className="modal-overlay" onClick={() => setHistoryMedicine(null)}>
          <div className="panel" style={{ maxWidth: 640, width: '90%' }} onClick={(e) => e.stopPropagation()}>
            <div className="panel-head">
              <h3>{historyMedicine.name} — batch history</h3>
              <button className="btn-secondary btn-compact" onClick={() => setHistoryMedicine(null)}>Close</button>
            </div>
            {historyLoading ? (
              <EmptyState text="Loading…" />
            ) : historyBatches.length === 0 ? (
              <EmptyState text="No batches recorded for this medicine yet." />
            ) : (
              <table className="data-table">
                <thead><tr><th>Batch #</th><th>Qty left</th><th>Expiry</th><th>Purchase</th><th>Sale</th><th>Status</th></tr></thead>
                <tbody>
                  {historyBatches.map((b) => (
                    <tr key={b.id}>
                      <td>{b.batchNumber}</td>
                      <td>{b.quantity}</td>
                      <td>{b.expiryDate}</td>
                      <td>Rs {b.purchasePrice}</td>
                      <td>Rs {b.salePrice}</td>
                      <td>{b.quantity > 0 ? <span style={{ color: 'var(--good-text)' }}>Active</span> : <span className="badge">Depleted</span>}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      )}
    </Layout>
  )
}