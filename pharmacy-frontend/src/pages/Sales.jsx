import { useEffect, useState } from 'react'
import api from '../api.js'
import Layout from '../components/Layout.jsx'
import EmptyState from '../components/EmptyState.jsx'

export default function Sales() {
  const user = JSON.parse(localStorage.getItem('user') || '{}')
  const [medicines, setMedicines] = useState([])
  const [batches, setBatches] = useState([])
  const [customerName, setCustomerName] = useState('')
  const [cart, setCart] = useState([])
  const [pickBatchId, setPickBatchId] = useState('')
  const [pickQty, setPickQty] = useState(1)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [saving, setSaving] = useState(false)
  const [receipt, setReceipt] = useState(null) // holds completed sale + line items for printing

  const medicineName = (id) => medicines.find((m) => m.id === id)?.name || `#${id}`
  const batchById = (id) => batches.find((b) => b.id === Number(id))

  function loadAll() {
    api.get('/medicines').then(({ data }) => setMedicines(data))
    api.get('/batches/low-stock?threshold=999999').then(({ data }) => setBatches(data.filter((b) => b.quantity > 0)))
  }

  useEffect(() => { loadAll() }, [])

  function addToCart() {
    const batch = batchById(pickBatchId)
    if (!batch || pickQty < 1) return
    const alreadyIn = cart.find((c) => c.batchId === batch.id)
    if (alreadyIn) {
      setCart(cart.map((c) => c.batchId === batch.id ? { ...c, quantity: c.quantity + Number(pickQty) } : c))
    } else {
      setCart([...cart, { batchId: batch.id, quantity: Number(pickQty), batch }])
    }
    setPickBatchId('')
    setPickQty(1)
  }

  function removeFromCart(batchId) {
    setCart(cart.filter((c) => c.batchId !== batchId))
  }

  const total = cart.reduce((sum, c) => sum + c.quantity * c.batch.salePrice, 0)

  async function completeSale() {
    setError('')
    setSuccess('')
    if (cart.length === 0) { setError('Add at least one item to the cart.'); return }
    setSaving(true)
    try {
      const { data } = await api.post('/sales', {
        customerName,
        items: cart.map((c) => ({ batchId: c.batchId, quantity: c.quantity })),
      })
      setSuccess(`Sale #${data.id} completed — Rs ${data.totalAmount}`)
      setReceipt({ sale: data, items: cart, customerName })
      setCart([])
      setCustomerName('')
      loadAll()
    } catch (err) {
      setError(err.response?.data?.error || 'Could not complete the sale.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Layout title="Sales" subtitle="Build a cart from your stock, then check out.">
      <div className="pos-grid">
        <div className="panel">
          <div className="panel-head"><h3>Add item</h3></div>
          {batches.length === 0 ? (
            <EmptyState text="No stock available to sell — add a batch first." />
          ) : (
            <div className="form-grid">
              <div className="field">
                <label>Batch</label>
                <select value={pickBatchId} onChange={(e) => setPickBatchId(e.target.value)}>
                  <option value="" disabled>Select a batch…</option>
                  {batches.map((b) => (
                    <option key={b.id} value={b.id}>
                      {medicineName(b.medicine?.id)} — {b.batchNumber} ({b.quantity} left, Rs {b.salePrice})
                    </option>
                  ))}
                </select>
              </div>
              <div className="field">
                <label>Quantity</label>
                <input type="number" min="1" value={pickQty} onChange={(e) => setPickQty(e.target.value)} />
              </div>
              <div className="form-actions">
                <button className="btn-secondary" type="button" onClick={addToCart} disabled={!pickBatchId}>Add to cart</button>
              </div>
            </div>
          )}
        </div>

        <div className="panel">
          <div className="panel-head"><h3>Cart</h3></div>

          {error && <div className="alert-error">{error}</div>}
          {success && <div className="alert-success">{success}</div>}

          {cart.length === 0 ? (
            <EmptyState text="Cart is empty." />
          ) : (
            <table className="data-table">
              <thead><tr><th>Medicine</th><th>Batch</th><th>Qty</th><th>Line total</th><th></th></tr></thead>
              <tbody>
                {cart.map((c) => (
                  <tr key={c.batchId}>
                    <td className="cell-strong">{medicineName(c.batch.medicine?.id)}</td>
                    <td>{c.batch.batchNumber}</td>
                    <td>{c.quantity}</td>
                    <td>Rs {(c.quantity * c.batch.salePrice).toFixed(2)}</td>
                    <td><button className="link-danger" onClick={() => removeFromCart(c.batchId)}>Remove</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}

          <div className="field" style={{ marginTop: 18 }}>
            <label>Customer name (optional)</label>
            <input value={customerName} onChange={(e) => setCustomerName(e.target.value)} placeholder="Walk-in customer" />
          </div>

          <div className="cart-total">
            <span>Total</span>
            <span>Rs {total.toFixed(2)}</span>
          </div>

          <button className="btn-primary" onClick={completeSale} disabled={saving || cart.length === 0}>
            {saving ? 'Processing…' : 'Complete sale'}
          </button>
        </div>
      </div>

      {receipt && (
        <div className="panel receipt-print">
          <div className="panel-head">
            <h3>Receipt — Sale #{receipt.sale.id}</h3>
            <div style={{ display: 'flex', gap: 10 }}>
              <button className="btn-secondary btn-compact no-print" onClick={() => window.print()}>Print receipt</button>
              <button className="btn-secondary btn-compact no-print" onClick={() => setReceipt(null)}>Close</button>
            </div>
          </div>

          <div className="receipt-body">
            <div className="receipt-shop-name">{user.shopName || 'Pharmacy'}</div>
            <div className="receipt-meta">
              <span>Sale #{receipt.sale.id}</span>
              <span>{new Date(receipt.sale.saleDate).toLocaleString()}</span>
            </div>
            {receipt.customerName && <div className="receipt-meta"><span>Customer: {receipt.customerName}</span></div>}

            <table className="data-table">
              <thead><tr><th>Medicine</th><th>Batch</th><th>Qty</th><th>Price</th><th>Total</th></tr></thead>
              <tbody>
                {receipt.items.map((c) => (
                  <tr key={c.batchId}>
                    <td className="cell-strong">{medicineName(c.batch.medicine?.id)}</td>
                    <td>{c.batch.batchNumber}</td>
                    <td>{c.quantity}</td>
                    <td>Rs {c.batch.salePrice}</td>
                    <td>Rs {(c.quantity * c.batch.salePrice).toFixed(2)}</td>
                  </tr>
                ))}
              </tbody>
            </table>

            <div className="cart-total">
              <span>Total</span>
              <span>Rs {receipt.sale.totalAmount}</span>
            </div>
          </div>
        </div>
      )}
    </Layout>
  )
}
