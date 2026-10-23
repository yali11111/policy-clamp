import {
  CheckCircle2,
  CircleSlash,
  Server,
} from "lucide-react";

export default function IntegrationStatus({
  name,
  description,
  enabled = false,
}) {
  const Icon = enabled ? CheckCircle2 : CircleSlash;

  return (
    <div className="integration-status">
      <div className="integration-status-icon">
        <Server size={17} aria-hidden="true" />
      </div>

      <div className="integration-status-info">
        <strong>{name}</strong>
        <small>{description}</small>
      </div>

      <span
        className={
          enabled
            ? "integration-pill integration-pill-enabled"
            : "integration-pill"
        }
      >
        <Icon size={13} aria-hidden="true" />
        {enabled ? "Activé" : "Désactivé"}
      </span>
    </div>
  );
}
