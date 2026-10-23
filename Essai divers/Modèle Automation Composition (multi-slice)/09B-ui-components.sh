
#!/usr/bin/env bash
# 09B-ui-components.sh
# Génération des composants React réutilisables.
# Aucun service n'est démarré.

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/ac-multislice-lab"
UI_DIR="${PROJECT_DIR}/ui-multislice"
COMPONENTS="${UI_DIR}/src/components"

if [ ! -d "${UI_DIR}/src" ]; then
    printf 'Erreur : exécuter d’abord 09A-ui-structure.sh\n' >&2
    exit 1
fi

write_file() {
    target="$1"

    if [ -e "$target" ]; then
        printf 'Conservé (existe déjà) : %s\n' "$target"
        return 0
    fi

    mkdir -p "$(dirname "$target")"
    cat > "$target"
    printf 'Créé : %s\n' "$target"
}

# ------------------------------------------------------------
# Sidebar.jsx
# ------------------------------------------------------------

write_file "${COMPONENTS}/Sidebar.jsx" <<'EOF'
import {
  Activity,
  Boxes,
  LayoutDashboard,
  Network,
  Settings2,
  ShieldCheck,
} from "lucide-react";

const navigation = [
  { label: "Overview", icon: LayoutDashboard, id: "overview" },
  { label: "Slice inventory", icon: Boxes, id: "inventory" },
  { label: "Events & logs", icon: Activity, id: "events" },
  { label: "Configuration", icon: Settings2, id: "configuration" },
];

export default function Sidebar({
  active = "overview",
  onNavigate = () => {},
}) {
  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <div className="brand-icon">
          <Network size={23} />
        </div>

        <div className="brand-copy">
          <strong>AC MultiSlice</strong>
          <span>Orchestration Lab</span>
        </div>
      </div>

      <div className="sidebar-section-label">WORKSPACE</div>

      <nav className="sidebar-navigation" aria-label="Navigation principale">
        {navigation.map(({ label, icon: Icon, id }) => (
          <button
            key={id}
            type="button"
            className={`nav-item ${active === id ? "active" : ""}`}
            onClick={() => onNavigate(id)}
            aria-current={active === id ? "page" : undefined}
          >
            <Icon size={19} />
            <span>{label}</span>
          </button>
        ))}
      </nav>

      <div className="sidebar-bottom">
        <div className="environment-card">
          <div className="environment-title">
            <ShieldCheck size={18} />
            <span>Demo environment</span>
          </div>
          <div className="environment-status">
            <span className="status-dot offline" />
            No cluster connected
          </div>
        </div>

        <div className="sidebar-footer">
          <span>AC MultiSlice Lab</span>
          <span>v1.0.0</span>
        </div>
      </div>
    </aside>
  );
}
EOF

# ------------------------------------------------------------
# StatCard.jsx
# ------------------------------------------------------------

write_file "${COMPONENTS}/StatCard.jsx" <<'EOF'
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
EOF

# ------------------------------------------------------------
# StatusBadge.jsx
# ------------------------------------------------------------

write_file "${COMPONENTS}/StatusBadge.jsx" <<'EOF'
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
EOF

# ------------------------------------------------------------
# SectionHeader.jsx
# ------------------------------------------------------------

write_file "${COMPONENTS}/SectionHeader.jsx" <<'EOF'
export default function SectionHeader({
  title,
  description,
  action,
}) {
  return (
    <div className="section-header">
      <div>
        <h2>{title}</h2>
        {description && <p>{description}</p>}
      </div>

      {action && (
        <div className="section-header-action">
          {action}
        </div>
      )}
    </div>
  );
}
EOF

# ------------------------------------------------------------
# EmptyState.jsx
# ------------------------------------------------------------

write_file "${COMPONENTS}/EmptyState.jsx" <<'EOF'
import { SearchX } from "lucide-react";

export default function EmptyState({
  title = "No slices found",
  description = "Try changing your search or filters.",
}) {
  return (
    <div className="empty-state">
      <div className="empty-state-icon">
        <SearchX size={25} />
      </div>

      <h3>{title}</h3>
      <p>{description}</p>
    </div>
  );
}
EOF

# ------------------------------------------------------------
# SliceCard.jsx
# ------------------------------------------------------------

write_file "${COMPONENTS}/SliceCard.jsx" <<'EOF'
import {
  Gauge,
  MoreHorizontal,
  Play,
  Server,
  Square,
  Zap,
} from "lucide-react";

import StatusBadge from "./StatusBadge.jsx";

export default function SliceCard({
  slice,
  onDetails = () => {},
  onDeploy = () => {},
  onUndeploy = () => {},
}) {
  const isRunning = slice.status === "RUNNING";
  const isBusy = [
    "VALIDATING",
    "DEPLOYING",
    "STOPPING",
  ].includes(slice.status);

  const isUrlcc = slice.type === "URLLC";
  const Icon = isUrlcc ? Zap : Gauge;

  return (
    <article className="slice-card">
      <div className="slice-card-main">
        <div className={`slice-profile-icon ${isUrlcc ? "urlcc" : "embb"}`}>
          <Icon size={22} />
        </div>

        <div className="slice-card-content">
          <div className="slice-title-row">
            <h3>{slice.id}</h3>
            <StatusBadge status={slice.status} />
          </div>

          <p className="slice-description">
            {slice.description ||
              (isUrlcc
                ? "Low latency · Critical applications"
                : "High bandwidth · Data applications")}
          </p>

          <div className="slice-metrics">
            <span>Priority {slice.priority}</span>
            <span>{slice.cpu} m CPU</span>
            <span>{slice.memory} MiB RAM</span>
            <span>{slice.replicas} replicas</span>
          </div>
        </div>

        <button
          type="button"
          className="icon-button details-menu"
          onClick={() => onDetails(slice)}
          aria-label={`View details for ${slice.id}`}
          title="View details"
        >
          <MoreHorizontal size={20} />
        </button>
      </div>

      <div className="slice-card-footer">
        <div className="slice-namespace">
          <Server size={15} />
          <span>{slice.namespace || "network-slices"}</span>
        </div>

        <div className="slice-actions">
          <button
            type="button"
            className="button button-secondary button-small"
            onClick={() => onDetails(slice)}
          >
            Details
          </button>

          {isRunning ? (
            <button
              type="button"
              className="button button-danger button-small"
              disabled={isBusy}
              onClick={() => onUndeploy(slice)}
            >
              <Square size={14} />
              Undeploy
            </button>
          ) : (
            <button
              type="button"
              className="button button-primary button-small"
              disabled={isBusy}
              onClick={() => onDeploy(slice)}
            >
              <Play size={14} />
              Deploy
            </button>
          )}
        </div>
      </div>
    </article>
  );
}
EOF

printf '\nPartie 2/4 terminée.\n'
printf 'Composants React générés dans : %s\n' "${COMPONENTS}"
printf 'Aucun fichier existant écrasé.\n'
printf 'Aucun service démarré.\n'

