export default function StatCard({ label, value, tone = 'neutral', hint }) {
  return (
    <div className="stat-tile">
      <div className="stat-tile-label">{label}</div>
      <div className={`stat-tile-value tone-${tone}`}>{value}</div>
      {hint && <div className="stat-tile-hint">{hint}</div>}
    </div>
  )
}
