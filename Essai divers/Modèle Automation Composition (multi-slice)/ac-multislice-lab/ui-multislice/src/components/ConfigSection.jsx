import {
  Settings2,
  Cpu,
  ShieldCheck,
  Database,
  Layers3,
} from "lucide-react";

const icons = {
  settings: Settings2,
  cpu: Cpu,
  shield: ShieldCheck,
  database: Database,
  layers: Layers3,
};

export default function ConfigSection({
  icon = "settings",
  title,
  description,
  children,
  className = "",
}) {
  const Icon = icons[icon] || Settings2;

  return (
    <section
      className={`config-card ${className}`.trim()}
    >
      <header className="config-card-heading">
        <div className="config-card-icon">
          <Icon size={19} aria-hidden="true" />
        </div>

        <div className="config-card-title-group">
          <h2>{title}</h2>
          {description && <p>{description}</p>}
        </div>
      </header>

      <div className="config-card-body">
        {children}
      </div>
    </section>
  );
}
