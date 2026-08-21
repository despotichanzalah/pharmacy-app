export default function PageHeader({ eyebrow, title, action }) {
  return (
    <div className="page-header">
      <div>
        <div className="page-eyebrow">{eyebrow}</div>
        <h1 className="page-title">{title}</h1>
      </div>
      {action}
    </div>
  )
}
