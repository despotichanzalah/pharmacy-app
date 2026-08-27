import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import Login from './pages/Login.jsx'
import Register from './pages/Register.jsx'
import ForgotPassword from './pages/ForgotPassword.jsx'
import ResetPassword from './pages/ResetPassword.jsx'
import Dashboard from './pages/Dashboard.jsx'
import Medicines from './pages/Medicines.jsx'
import Stock from './pages/Stock.jsx'
import Sales from './pages/Sales.jsx'
import SalesHistory from './pages/SalesHistory.jsx'
import Returns from './pages/Returns.jsx'
import Suppliers from './pages/Suppliers.jsx'
import Purchases from './pages/Purchases.jsx'
import Reports from './pages/Reports.jsx'
import Staff from './pages/Staff.jsx'

function isLoggedIn() {
  return !!localStorage.getItem('token')
}

function Protected({ children }) {
  return isLoggedIn() ? children : <Navigate to="/login" replace />
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/forgot-password" element={<ForgotPassword />} />
        <Route path="/reset-password" element={<ResetPassword />} />

        <Route path="/dashboard" element={<Protected><Dashboard /></Protected>} />
        <Route path="/dashboard/medicines" element={<Protected><Medicines /></Protected>} />
        <Route path="/dashboard/stock" element={<Protected><Stock /></Protected>} />
        <Route path="/dashboard/sales" element={<Protected><Sales /></Protected>} />
        <Route path="/dashboard/sales-history" element={<Protected><SalesHistory /></Protected>} />
        <Route path="/dashboard/returns" element={<Protected><Returns /></Protected>} />
        <Route path="/dashboard/suppliers" element={<Protected><Suppliers /></Protected>} />
        <Route path="/dashboard/purchases" element={<Protected><Purchases /></Protected>} />
        <Route path="/dashboard/reports" element={<Protected><Reports /></Protected>} />
        <Route path="/dashboard/staff" element={<Protected><Staff /></Protected>} />

        <Route path="*" element={<Navigate to={isLoggedIn() ? '/dashboard' : '/login'} replace />} />
      </Routes>
    </BrowserRouter>
  )
}
