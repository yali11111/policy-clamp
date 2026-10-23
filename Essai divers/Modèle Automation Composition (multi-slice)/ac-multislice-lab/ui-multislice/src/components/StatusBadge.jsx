const labels = {
  CREATED: "Created",
  VALIDATING: "Validating",
  DEPLOYING: "Deploying",
  RUNNING: "Running",
  STOPPING: "Stopping",
  STOPPED: "Stopped",
  FAILED: "Failed",
};

export default function StatusBadge({ status = "CREATED" }) {
  const normalized = String(status).toUpperCase();
  const label = labels[normalized] || normalized;

  return (
    <span className={`status-badge status-${normalized.toLowerCase()}`}>
      <span className="status-dot" />
      {label}
    </span>
  );
}
