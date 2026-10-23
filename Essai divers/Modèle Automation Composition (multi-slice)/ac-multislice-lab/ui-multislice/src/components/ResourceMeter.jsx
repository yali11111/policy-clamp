export default function ResourceMeter({
  label,
  value,
  maximum,
  unit = "",
  color = "cpu",
}) {
  const numericValue = Number(value) || 0;
  const numericMaximum = Number(maximum) || 0;

  const percentage = numericMaximum > 0
    ? Math.min(
        100,
        Math.max(0, (numericValue / numericMaximum) * 100)
      )
    : 0;

  const exceeded = numericMaximum > 0
    && numericValue > numericMaximum;

  return (
    <div className="resource-meter-block">
      <div className="resource-meter-heading">
        <span>{label}</span>

        <strong>
          {numericValue.toLocaleString("fr-FR")}
          {" "}
          {unit}
        </strong>
      </div>

      <div
        className="resource-meter-track"
        role="progressbar"
        aria-label={label}
        aria-valuemin={0}
        aria-valuemax={numericMaximum || 100}
        aria-valuenow={numericValue}
        aria-valuetext={
          `${numericValue} ${unit} sur ${numericMaximum} ${unit}`
        }
      >
        <div
          className={[
            "resource-meter-fill",
            `${color}-fill`,
            exceeded ? "resource-meter-exceeded" : "",
          ].filter(Boolean).join(" ")}
          style={{ width: `${percentage}%` }}
        />
      </div>

      <div className="resource-meter-caption">
        <span>
          Limite : {numericMaximum.toLocaleString("fr-FR")} {unit}
        </span>

        <span>
          {numericMaximum > 0
            ? `${Math.round(percentage)} %`
            : "Limite non définie"}
        </span>
      </div>
    </div>
  );
}
