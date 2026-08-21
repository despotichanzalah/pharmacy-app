import { useEffect, useState } from 'react'
import api from '../api.js'
import Layout from '../components/Layout.jsx'
import EmptyState from '../components/EmptyState.jsx'

export default function Suppliers() {
  const [suppliers, setSuppliers] = useState([])
  const [showForm, setShowForm] = useState(false)
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState({ name: '', contact: '', address: '' })

  function load() {
    api.get('/suppliers').then(({ data }) => setSuppliers(data))
  }

  useEffect(() => { load() }, [])

  function update(field, value) {
    setForm((f) => ({ ...f, [field]: value }))
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setSaving(true)
    try {
      await api.post('/suppliers', form)
      setForm({ name: '', contact: '', address: '' })
      setShowForm(false)
      load()
    } catch (err) {
      setError(err.response?.data?.error || 'Could not add the supplier.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Layout
      title="Suppliers"
      subtitle="Who you buy stock from."
      actions={<button className="btn-primary btn-compact" onClick={() => setShowForm((v) => !v)}>{showForm ? 'Cancel' : '+ Add supplier'}</button>}
    >
      {showForm && (
        <div className="panel">
          <div className="panel-head"><h3>New supplier</h3></div>
          {error && <div className="alert-error">{error}</div>}
          <form className="form-grid" onSubmit={handleSubmit}>
            <div className="field">
              <label>Name</label>
              <input required value={form.name} onChange={(e) => update('name', e.target.value)} placeholder="MedSupply Co" />
            </div>
            <div className="field">
              <label>Contact</label>
              <input value={form.contact} onChange={(e) => update('contact', e.target.value)} placeholder="0300-1234567" />
            </div>
            <div className="field">
              <label>Address</label>
              <input value={form.address} onChange={(e) => update('address', e.target.value)} placeholder="Lahore" />
            </div>
            <div className="form-actions">
              <button className="btn-primary" type="submit" disabled={saving}>{saving ? 'Saving…' : 'Save supplier'}</button>
            </div>
          </form>
        </div>
      )}

      <div className="panel">
        <div className="panel-head"><h3>All suppliers</h3></div>
        {suppliers.length === 0 ? (
          <EmptyState text="No suppliers yet." />
        ) : (
          <table className="data-table">
            <thead><tr><th>Name</th><th>Contact</th><th>Address</th></tr></thead>
            <tbody>
              {suppliers.map((s) => (
                <tr key={s.id}>
                  <td className="cell-strong">{s.name}</td>
                  <td>{s.contact || '—'}</td>
                  <td>{s.address || '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </Layout>
  )
}
