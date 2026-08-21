export default function Drawer({ open, onClose, title, children }) {
  if (!open) return null
  return (
    <div className="drawer-overlay" onClick={onClose}>
      <div className="drawer-panel" onClick={(e) => e.stopPropagation()}>
        <div className="drawer-head">
          <h3>{title}</h3>
          <button className="drawer-close" onClick={onClose}>&times;</button>
        </div>
        <div className="drawer-body">{children}</div>
      </div>
    </div>
  )
}
