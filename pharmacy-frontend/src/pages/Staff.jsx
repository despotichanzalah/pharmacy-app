import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import api from '../api.js'
import Layout from '../components/Layout.jsx'
import EmptyState from '../components/EmptyState.jsx'

export default function Staff() {
  const navigate = useNavigate()
  const user = JSON.parse(localStorage.getItem('user') || '{}')
  const [staff, setStaff] = useState([])
  const [error, setError] = useState('')
  const [deletingShop, setDeletingShop] = useState(false)

  function load() {
    api.get('/users').then(({ data }) => setStaff(data))
  }

  useEffect(() => { load() }, [])

  async function handleDeleteUser(member) {
    if (!window.confirm(`Remove ${member.name} from the shop? This can't be undone.`)) return
    try {
      await api.delete(`/users/${member.id}`)
      load()
    } catch (err) {
      alert(err.response?.data?.error || 'Could not remove this account.')
    }
  }

  async function handleDeleteShop() {
    const confirmText = window.prompt(
      `This will permanently delete "${user.shopName}" and ALL its data — medicines, stock, sales, everything. This cannot be undone.\n\nType DELETE to confirm.`
    )
    if (confirmText !== 'DELETE') return

    setDeletingShop(true)
    setError('')
    try {
      await api.delete('/shops/mine')
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      navigate('/login')
    } catch (err) {
      setError(err.response?.data?.error || 'Could not delete the shop.')
      setDeletingShop(false)
    }
  }

  return (
    <Layout title="Staff" subtitle="Everyone with access to this shop.">
      {error && <div className="alert-error">{error}</div>}

      <div className="panel">
        <div className="panel-head"><h3>Team members</h3></div>
        {staff.length === 0 ? (
          <EmptyState text="No staff found." />
        ) : (
          <table className="data-table">
            <thead><tr><th>Name</th><th>Email</th><th>Role</th><th></th></tr></thead>
            <tbody>
              {staff.map((s) => (
                <tr key={s.id}>
                  <td className="cell-strong">{s.name}</td>
                  <td>{s.email}</td>
                  <td>{s.role?.name}</td>
                  <td>
                    {s.email !== user.email && (
                      <button className="link-danger" onClick={() => handleDeleteUser(s)}>Remove</button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <div className="panel" style={{ borderColor: 'var(--bad-text)' }}>
        <div className="panel-head"><h3 style={{ color: 'var(--bad-text)' }}>Danger zone</h3></div>
        <p style={{ color: 'var(--ink-soft)', marginBottom: 16 }}>
          Permanently close this shop. All medicines, stock, sales, and staff accounts will be deleted. This cannot be undone.
        </p>
        <button className="btn-secondary" style={{ borderColor: 'var(--bad-text)', color: 'var(--bad-text)' }} onClick={handleDeleteShop} disabled={deletingShop}>
          {deletingShop ? 'Deleting…' : 'Delete this shop permanently'}
        </button>
      </div>
    </Layout>
  )
}
