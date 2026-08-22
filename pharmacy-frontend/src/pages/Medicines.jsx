import { useEffect, useState } from 'react'
import api from '../api.js'
import Layout from '../components/Layout.jsx'
import EmptyState from '../components/EmptyState.jsx'

export default function Medicines() {
  const [medicines, setMedicines] = useState([])
  const [genericsList, setGenericsList] = useState([])
  const [query, setQuery] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState({ name: '', unit: '', reorderLevel: 10, packSize: 1 })
  const [selectedGenerics, setSelectedGenerics] = useState([]) // [{ id, name }] or [{ name, isNew: true }]
  const [genericInput, setGenericInput] = useState('')

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

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setSaving(true)
    try {
      await api.post('/medicines', {
        ...form,
        reorderLevel: Number(form.reorderLevel),
        packSize: Number(form.packSize) || 1,
        genericIds: selectedGenerics.filter((g) => g.id).map((g) => g.id),
        newGenerics: selectedGenerics.filter((g) => g.isNew).map((g) => g.name),
      })
      setForm({ name: '', unit: '', reorderLevel: 10, packSize: 1 })
      setSelectedGenerics([])
      setShowForm(false)
      load(query)
      api.get('/generics').then(({ data }) => setGenericsList(data)) // pick up any newly created generics
    } catch (err) {
      setError(err.response?.data?.error || 'Could not add the medicine.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Layout
      title="Medicines"
      subtitle="Your shop's catalog — search, add, and keep names consistent for stock and sales."
      actions={<button className="btn-primary btn-compact" onClick={() => setShowForm((v) => !v)}>{showForm ? 'Cancel' : '+ Add medicine'}</button>}
    >
      {showForm && (
        <div className="panel">
          <div className="panel-head"><h3>New medicine</h3></div>
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
                <div className="field-hint">Units per strip/box. Leave as 1 if sold only as single units (e.g. a syrup bottle).</div>
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

            <div className="form-actions" style={{ marginTop: 18 }}>
              <button className="btn-primary" type="submit" disabled={saving}>{saving ? 'Saving…' : 'Save medicine'}</button>
            </div>
          </form>
        </div>
      )}

      <div className="panel">
        <div className="panel-head">
          <h3>Catalog</h3>
          <input
            className="search-input"
            placeholder="Search medicines…"
            value={query}
            onChange={(e) => { setQuery(e.target.value); load(e.target.value) }}
          />
        </div>

        {medicines.length === 0 ? (
          <EmptyState text="No medicines yet — add your first one above." />
        ) : (
          <table className="data-table">
            <thead>
              <tr><th>Name</th><th>Generic(s)</th><th>Unit</th><th>Pack size</th><th>Reorder level</th></tr>
            </thead>
            <tbody>
              {medicines.map((m) => (
                <tr key={m.id}>
                  <td className="cell-strong">{m.name}</td>
                  <td>
                    {m.generics && m.generics.length > 0
                      ? m.generics.map((g) => <span key={g.id} className="chip chip-static">{g.name}</span>)
                      : '—'}
                  </td>
                  <td>{m.unit || '—'}</td>
                  <td>{m.packSize > 1 ? `${m.packSize} per pack` : 'Single unit'}</td>
                  <td>{m.reorderLevel}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </Layout>
  )
}
