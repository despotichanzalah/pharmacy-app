import { useEffect, useState } from 'react'
import api from '../api.js'
import Layout from '../components/Layout.jsx'
import EmptyState from '../components/EmptyState.jsx'

export default function Sales() {
  const user = JSON.parse(localStorage.getItem('user') || '{}')
  const [medicines, setMedicines] = useState([])
  const [batches, setBatches] = useState([])
  const [customerName, setCustomerName] = useState('')
  const [discountPercent, setDiscountPercent] = useState(0)
  const [cart, setCart] = useState([])
  const [pickBatchId, setPickBatchId] = useState('')
  const [pickQty, setPickQty] = useState(1)
  const [pickMode, setPickMode] = useState('units') // 'units' | 'packs'
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [saving, setSaving] = useState(false)
  const [receipt, setReceipt] = useState(null) // holds completed sale + line items for printing

  const medicineName = (id) => medicines.find((m) => m.id === id)?.name || `#${id}`
  const medicinePackSize = (id) => medicines.find((m) => m.id === id)?.packSize || 1
  const batchById = (id) => batches.find((b) => b.id === Number(id))

  function loadAll() {
    api.get('/medicines').then(({ data }) => setMedicines(data))
    api.get('/batches/low-stock?threshold=999999').then(({ data }) => setBatches(data.filter((b) => b.quantity > 0)))
  }

  useEffect(() => { loadAll() }, [])

  const pickedBatch = batchById(pickBatchId)
  const pickedPackSize = pickedBatch ? medicinePackSize(pickedBatch.medicine?.id) : 1

  function addToCart() {
    const batch = batchById(pickBatchId)
    if (!batch || pickQty < 1) return

    const packSize = medicinePackSize(batch.medicine?.id)
    const unitQty = pickMode === 'packs' ? Number(pickQty) * packSize : Number(pickQty)
    const label = pickMode === 'packs' && packSize > 1
      ? `${pickQty} pack${pickQty > 1 ? 's' : ''} (${unitQty} units)`
      : `${unitQty} unit${unitQty > 1 ? 's' : ''}`

    const alreadyIn = cart.find((c) => c.batchId === batch.id)
    if (alreadyIn) {
      const newUnitQty = alreadyIn.quantity + unitQty
      setCart(cart.map((c) => c.batchId === batch.id
        ? { ...c, quantity: newUnitQty, label: `${newUnitQty} unit${newUnitQty > 1 ? 's' : ''}` }
        : c))
    } else {
      setCart([...cart, { batchId: batch.id, quantity: unitQty, label, batch }])
    }
    setPickBatchId('')
    setPickQty(1)
    setPickMode('units')
  }

  function removeFromCart(batchId) {
    setCart(cart.filter((c) => c.batchId !== batchId))
  }

  const subtotal = cart.reduce((sum, c) => sum + c.quantity * c.batch.salePrice, 0)
  const discountAmount = subtotal * (Number(discountPercent) || 0) / 100
  const total = subtotal - discountAmount

  async function completeSale() {
    setError('')
    setSuccess('')
    if (cart.length === 0) { setError('Add at least one item to the cart.'); return }
    setSaving(true)
    try {
      const { data } = await api.post('/sales', {
        customerName,
        discountPercent: Number(discountPercent) || 0,
        items: cart.map((c) => ({ batchId: c.batchId, quantity: c.quantity })),
      })
      setSuccess(`Sale #${data.id} completed — Rs ${data.totalAmount}`)
      setReceipt({ sale: data, items: cart, customerName, discountPercent: Number(discountPercent) || 0, subtotal })
      setCart([])
      setCustomerName('')
      setDiscountPercent(0)
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
                <select value={pickBatchId} onChange={(e) => { setPickBatchId(e.target.value); setPickMode('units') }}>
                  <option value="" disabled>Select a batch…</option>
                  {batches.map((b) => (
                    <option key={b.id} value={b.id}>
                      {medicineName(b.medicine?.id)} — {b.batchNumber} ({b.quantity} left, Rs {b.salePrice}/unit)
                    </option>
                  ))}
                </select>
              </div>

              {pickedBatch && pickedPackSize > 1 && (
                <div className="tab-row" style={{ marginBottom: 0, gridColumn: '1 / -1' }}>
                  <button type="button" className={`tab-pill ${pickMode === 'units' ? 'active' : ''}`} onClick={() => setPickMode('units')}>
                    Sell loose (tablets)
                  </button>
                  <button type="button" className={`tab-pill ${pickMode === 'packs' ? 'active' : ''}`} onClick={() => setPickMode('packs')}>
                    Sell whole pack (×{pickedPackSize})
                  </button>
                </div>
              )}

              <div className="field">
                <label>{pickMode === 'packs' ? 'Number of packs' : 'Quantity (units)'}</label>
                <input type="number" min="1" value={pickQty} onChange={(e) => setPickQty(e.target.value)} />
                {pickedBatch && pickMode === 'packs' && (
                  <div className="field-hint">= {Number(pickQty || 0) * pickedPackSize} tablets total</div>
                )}
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
                    <td>{c.label || `${c.quantity} units`}</td>
                    <td>Rs {(c.quantity * c.batch.salePrice).toFixed(2)}</td>
                    <td><button className="link-danger" onClick={() => removeFromCart(c.batchId)}>Remove</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}

          <div className="form-grid" style={{ marginTop: 18 }}>
            <div className="field">
              <label>Customer name (optional)</label>
              <input value={customerName} onChange={(e) => setCustomerName(e.target.value)} placeholder="Walk-in customer" />
            </div>
            <div className="field">
              <label>Discount %</label>
              <input type="number" min="0" max="100" step="0.5" value={discountPercent} onChange={(e) => setDiscountPercent(e.target.value)} />
            </div>
          </div>

          <div className="cart-total" style={{ flexDirection: 'column', alignItems: 'stretch', gap: 6 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 15, fontWeight: 500 }}>
              <span>Subtotal</span>
              <span>Rs {subtotal.toFixed(2)}</span>
            </div>
            {discountAmount > 0 && (
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 15, color: 'var(--bad-text)' }}>
                <span>Discount ({Number(discountPercent)}%)</span>
                <span>- Rs {discountAmount.toFixed(2)}</span>
              </div>
            )}
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span>Total</span>
              <span>Rs {total.toFixed(2)}</span>
            </div>
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

            <table className="data-table receipt-table">
              <thead><tr><th>Medicine</th><th>Qty</th><th>Price</th><th>Total</th></tr></thead>
              <tbody>
                {receipt.items.map((c) => (
                  <tr key={c.batchId}>
                    <td className="cell-strong">{medicineName(c.batch.medicine?.id)}</td>
                    <td>{c.label || `${c.quantity}`}</td>
                    <td>Rs {c.batch.salePrice}</td>
                    <td>Rs {(c.quantity * c.batch.salePrice).toFixed(2)}</td>
                  </tr>
                ))}
              </tbody>
            </table>

            <div className="cart-total" style={{ flexDirection: 'column', alignItems: 'stretch', gap: 4 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13 }}>
                <span>Subtotal</span>
                <span>Rs {receipt.subtotal.toFixed(2)}</span>
              </div>
              {receipt.discountPercent > 0 && (
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13 }}>
                  <span>Discount ({receipt.discountPercent}%)</span>
                  <span>- Rs {(receipt.subtotal * receipt.discountPercent / 100).toFixed(2)}</span>
                </div>
              )}
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>Total</span>
                <span>Rs {receipt.sale.totalAmount}</span>
              </div>
            </div>
          </div>
        </div>
      )}
    </Layout>
  )
}
