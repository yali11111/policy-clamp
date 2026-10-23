export default function StatCard({
  title,
  value,
  detail,
  icon: Icon,
  color = "blue",
  percent = 0,
}) {
  const safePercent = Math.max(0, Math.min(Number(percent) || 0, 100));

  return (
    <article className="stat-card">
      <div className="stat-card-top">
        <span className="stat-label">{title}</span>

        {Icon && (
          <div className={`stat-icon ${color}`}>
            <Icon size={19} />
          </div>
        )}
      </div>

      <div className="stat-value">{value}</div>

      <div
        className="progress-track"
        role="progressbar"
        aria-label={title}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={Math.round(safePercent)}
      >
        <div
          className={`progress-fill ${color}`}
          style={{ width: `${safePercent}%` }}
        />
      </div>

      <p className="stat-detail">{detail}</p>
    </article>
  );
}
