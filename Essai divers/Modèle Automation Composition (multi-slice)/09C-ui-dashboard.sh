
#!/usr/bin/env bash
# 09C1A-ui-dashboard-data.sh
# Données initiales du dashboard AC MultiSlice Lab.

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/ac-multislice-lab"
UI_DIR="${PROJECT_DIR}/ui-multislice"
SRC="${UI_DIR}/src"

if [ ! -d "${PROJECT_DIR}" ]; then
    printf 'Erreur : exécuter d’abord 01-structure.sh\n' >&2
    exit 1
fi

write_file() {
    local target="$1"

    if [ -e "$target" ]; then
        printf 'Conservé (existe déjà) : %s\n' "$target"
        cat > /dev/null
        return 0
    fi

    mkdir -p "$(dirname "$target")"
    cat > "$target"
    printf 'Créé : %s\n' "$target"
}

# ------------------------------------------------------------
# Répertoires du dashboard
# ------------------------------------------------------------

mkdir -p "${SRC}/services"
mkdir -p "${SRC}/pages"

# ------------------------------------------------------------
# Données initiales
# ------------------------------------------------------------

write_file "${SRC}/services/demoData.js" <<'EOF'
/**
 * Données fictives du dashboard.
 *
 * Ces valeurs restent dans le navigateur.
 * Elles ne représentent pas l'état d'un cluster réel.
 */

export const initialSlices = [
  {
    id: "slice-urllc-001",
    type: "URLLC",
    status: "RUNNING",
    priority: 100,
    namespace: "network-slices",
    deploymentName: "urllc-workload",
    replicas: 2,
    cpu: 500,
    memory: 512,
    description: "Low latency · Critical applications",
  },
  {
    id: "slice-embb-001",
    type: "EMBB",
    status: "RUNNING",
    priority: 50,
    namespace: "network-slices",
    deploymentName: "embb-workload",
    replicas: 3,
    cpu: 750,
    memory: 1024,
    description: "High bandwidth · Media workloads",
  },
  {
    id: "slice-urllc-002",
    type: "URLLC",
    status: "STOPPED",
    priority: 100,
    namespace: "network-slices",
    deploymentName: "urllc-edge",
    replicas: 1,
    cpu: 500,
    memory: 512,
    description: "Edge processing · Low latency",
  },
  {
    id: "slice-embb-002",
    type: "EMBB",
    status: "CREATED",
    priority: 50,
    namespace: "network-slices",
    deploymentName: "embb-streaming",
    replicas: 2,
    cpu: 1000,
    memory: 2048,
    description: "Streaming · High throughput",
  },
];

export const initialEvents = [
  {
    id: 1,
    time: "09:42:18",
    type: "SUCCESS",
    message: "slice-urllc-001 deployment completed",
  },
  {
    id: 2,
    time: "09:40:51",
    type: "INFO",
    message: "AC MultiSlice Lab initialized in demo mode",
  },
  {
    id: 3,
    time: "09:38:07",
    type: "SUCCESS",
    message: "slice-embb-001 replicas updated to 3",
  },
];
EOF

printf '\nPartie 1/2 terminée.\n'
printf 'Données de démonstration préparées.\n'
printf 'Aucun fichier existant écrasé.\n'
printf 'Aucun service démarré.\n'

# 09C1B-ui-dashboard-data.sh
# Génération du dashboard React AC MultiSlice Lab.
# Partie 1/2 : initialisation et composants réutilisables.

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/ac-multislice-lab"
SRC="${PROJECT_DIR}/ui-multislice/src"
TARGET="${SRC}/pages/Dashboard.demo.jsx"

if [ ! -f "${SRC}/services/demoData.js" ]; then
    printf 'Erreur : exécuter d’abord 09C1A-ui-dashboard-data.sh\n' >&2
    exit 1
fi

if [ -f "${TARGET}" ]; then
    printf 'Conservé (existe déjà) : %s\n' "${TARGET}"
    exit 0
fi

mkdir -p "$(dirname "${TARGET}")"

cat > "${TARGET}" <<'REACT'
import { useMemo, useState } from "react";
import {
  Activity,
  Boxes,
  CheckCircle2,
  Clock3,
  Cpu,
  Layers3,
  Plus,
  Search,
  Server,
  X,
  Zap,
} from "lucide-react";

import {
  initialEvents,
  initialSlices,
} from "../services/demoData.js";

const STATUS_LABELS = {
  RUNNING: "Running",
  CREATED: "Created",
  STOPPED: "Stopped",
  FAILED: "Failed",
};

function StatusBadge({ status }) {
  return (
    <span className={`status-badge status-${status.toLowerCase()}`}>
      <span className="status-dot" />
      {STATUS_LABELS[status] || status}
    </span>
  );
}

function StatCard({ title, value, detail, icon: Icon, color }) {
  return (
    <article className="stat-card">
      <div className={`stat-icon stat-icon-${color}`}>
        <Icon size={20} />
      </div>
      <div className="stat-copy">
        <span>{title}</span>
        <strong>{value}</strong>
        <small>{detail}</small>
      </div>
    </article>
  );
}

function SectionHeader({ title, description, action }) {
  return (
    <div className="section-header">
      <div>
        <h2>{title}</h2>
        <p>{description}</p>
      </div>
      {action}
    </div>
  );
}

function SliceCard({ slice, onDetails, onToggle }) {
  const running = slice.status === "RUNNING";

  return (
    <article className="slice-card">
      <div className="slice-card-top">
        <div
          className={`slice-type-icon ${
            slice.type === "URLLC" ? "type-urllc" : "type-embb"
          }`}
        >
          {slice.type === "URLLC" ? (
            <Zap size={21} />
          ) : (
            <Layers3 size={21} />
          )}
        </div>
        <StatusBadge status={slice.status} />
      </div>

      <div className="slice-heading">
        <span>{slice.type}</span>
        <h3>{slice.id}</h3>
        <p>{slice.description}</p>
      </div>

      <div className="slice-metrics">
        <div>
          <span>Replicas</span>
          <strong>{slice.replicas}</strong>
        </div>
        <div>
          <span>CPU / replica</span>
          <strong>{slice.cpu}m</strong>
        </div>
        <div>
          <span>Memory / replica</span>
          <strong>{slice.memory} MiB</strong>
        </div>
      </div>

      <div className="slice-actions">
        <button
          className="button button-secondary"
          onClick={() => onDetails(slice)}
        >
          Details
        </button>
        <button
          className={`button ${running ? "button-danger" : "button-primary"}`}
          onClick={() => onToggle(slice)}
        >
          {running ? "Simulate stop" : "Simulate deploy"}
        </button>
      </div>
    </article>
  );
}

function EventList({ events }) {
  if (events.length === 0) {
    return (
      <div className="empty-state">
        <Activity size={24} />
        <h3>No events yet</h3>
        <p>Actions in this demo session will appear here.</p>
      </div>
    );
  }

  return (
    <div className="event-list">
      {events.map((event) => (
        <div className="event-row" key={event.id}>
          <div className={`event-icon event-${event.type.toLowerCase()}`}>
            {event.type === "SUCCESS" ? (
              <CheckCircle2 size={18} />
            ) : (
              <Activity size={18} />
            )}
          </div>
          <div className="event-message">
            <p>{event.message}</p>
            <span>{event.type}</span>
          </div>
          <time>
            <Clock3 size={14} />
            {event.time}
          </time>
        </div>
      ))}
    </div>
  );
}

export default function DashboardDemo() {
  const [slices, setSlices] = useState(initialSlices);
  const [events, setEvents] = useState(initialEvents);
  const [page, setPage] = useState("overview");
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("ALL");
  const [typeFilter, setTypeFilter] = useState("ALL");
  const [selectedSlice, setSelectedSlice] = useState(null);
  const [showCreate, setShowCreate] = useState(false);
  const [notice, setNotice] = useState("");

  const runningSlices = slices.filter(
    (slice) => slice.status === "RUNNING"
  );

  const activeReplicas = runningSlices.reduce(
    (sum, slice) => sum + slice.replicas,
    0
  );

  const requestedCpu = runningSlices.reduce(
    (sum, slice) => sum + slice.cpu * slice.replicas,
    0
  );

  const filteredSlices = useMemo(() => {
    const term = search.trim().toLowerCase();

    return slices.filter((slice) => {
      const matchesText =
        !term ||
        slice.id.toLowerCase().includes(term) ||
        slice.type.toLowerCase().includes(term) ||
        slice.deploymentName.toLowerCase().includes(term);

      const matchesStatus =
        statusFilter === "ALL" || slice.status === statusFilter;

      const matchesType =
        typeFilter === "ALL" || slice.type === typeFilter;

      return matchesText && matchesStatus && matchesType;
    });
  }, [slices, search, statusFilter, typeFilter]);

  function addEvent(type, message) {
    const event = {
      id: `${Date.now()}-${Math.random()}`,
      time: new Date().toLocaleTimeString("fr-FR"),
      type,
      message,
    };

    setEvents((current) => [event, ...current].slice(0, 50));
  }

  function toggleSlice(slice) {
    const nextStatus =
      slice.status === "RUNNING" ? "STOPPED" : "RUNNING";

    setSlices((current) =>
      current.map((item) =>
        item.id === slice.id
          ? { ...item, status: nextStatus }
          : item
      )
    );

    addEvent(
      "SUCCESS",
      `${nextStatus === "RUNNING" ? "Deploy" : "Stop"} simulé : ${slice.id}`
    );

    setNotice(
      `${slice.id} : changement d'état simulé. Aucun cluster n'a été modifié.`
    );
  }

  function createSlice(event) {
    event.preventDefault();

    const form = new FormData(event.currentTarget);
    const id = String(form.get("id") || "").trim();
    const type = String(form.get("type") || "URLLC");
    const deploymentName = String(
      form.get("deploymentName") || ""
    ).trim();

    if (!id || !deploymentName) {
      setNotice("L'identifiant et le nom du Deployment sont obligatoires.");
      return;
    }

    if (slices.some((slice) => slice.id === id)) {
      setNotice("Cet identifiant existe déjà.");
      return;
    }

    const slice = {
      id,
      type,
      status: "CREATED",
      priority: type === "URLLC" ? 100 : 50,
      namespace: "network-slices",
      deploymentName,
      replicas: 1,
      cpu: type === "URLLC" ? 500 : 750,
      memory: type === "URLLC" ? 512 : 1024,
      description:
        type === "URLLC"
          ? "Low latency · Demo workload"
          : "High bandwidth · Demo workload",
    };

    setSlices((current) => [slice, ...current]);
    addEvent("INFO", `Slice enregistrée : ${id}`);
    setShowCreate(false);
    setPage("inventory");
    setNotice(`${id} a été ajoutée à l'inventaire local.`);
  }

  const pageTitles = {
    overview: "Overview",
    inventory: "Slice inventory",
    events: "Events & logs",
    configuration: "Configuration",
  };

  function renderOverview() {
    return (
      <>
        <section className="welcome-banner">
          <div>
            <span className="eyebrow">AUTOMATION COMPOSITION LAB</span>
            <h2>Network slice orchestration</h2>
            <p>
              Monitor your URLLC and eMBB profiles from one unified console.
            </p>
            <button
              className="button button-light"
              onClick={() => setPage("inventory")}
            >
              Explore slices
            </button>
          </div>

          <div className="welcome-graphic" aria-hidden="true">
            <div className="orbit orbit-one" />
            <div className="orbit orbit-two" />
            <div className="orbit-center">
              <Layers3 size={34} />
            </div>
          </div>
        </section>

        <div className="stats-grid">
          <StatCard
            title="Total slices"
            value={slices.length}
            detail="Registered profiles"
            icon={Boxes}
            color="blue"
          />
          <StatCard
            title="Running slices"
            value={runningSlices.length}
            detail="Simulated running state"
            icon={Activity}
            color="green"
          />
          <StatCard
            title="Active replicas"
            value={activeReplicas}
            detail="Desired replica count"
            icon={Server}
            color="purple"
          />
          <StatCard
            title="CPU requested"
            value={`${requestedCpu}m`}
            detail="Estimated application request"
            icon={Cpu}
            color="orange"
          />
        </div>

        <SectionHeader
          title="Slice profiles"
          description="Overview of registered workloads."
          action={
            <button
              className="button button-secondary"
              onClick={() => setPage("inventory")}
            >
              View all
            </button>
          }
        />

        <div className="slice-grid">
          {slices.slice(0, 4).map((slice) => (
            <SliceCard
              key={slice.id}
              slice={slice}
              onDetails={setSelectedSlice}
              onToggle={toggleSlice}
            />
          ))}
        </div>

        <SectionHeader
          title="Recent activity"
          description="Latest events from this demo session."
          action={
            <button
              className="text-button"
              onClick={() => setPage("events")}
            >
              View event log
            </button>
          }
        />

        <EventList events={events.slice(0, 4)} />
      </>
    );
  }

  function renderInventory() {
    return (
      <>
        <SectionHeader
          title="Slice inventory"
          description="Search, filter and inspect application slice profiles."
          action={
            <button
              className="button button-primary"
              onClick={() => setShowCreate(true)}
            >
              <Plus size={17} />
              New slice
            </button>
          }
        />

        <div className="filter-toolbar">
          <label className="search-box">
            <Search size={17} />
            <input
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Search slices..."
              aria-label="Search slices"
            />
          </label>

          <select
            value={statusFilter}
            onChange={(event) => setStatusFilter(event.target.value)}
            aria-label="Filter by status"
          >
            <option value="ALL">All statuses</option>
            <option value="RUNNING">Running</option>
            <option value="CREATED">Created</option>
            <option value="STOPPED">Stopped</option>
            <option value="FAILED">Failed</option>
          </select>

          <select
            value={typeFilter}
            onChange={(event) => setTypeFilter(event.target.value)}
            aria-label="Filter by profile"
          >
            <option value="ALL">All profiles</option>
            <option value="URLLC">URLLC</option>
            <option value="EMBB">eMBB</option>
          </select>
        </div>

        <div className="inventory-summary">
          <span>{filteredSlices.length} slice(s) found</span>
          <button
            className="text-button"
            onClick={() => {
              setSearch("");
              setStatusFilter("ALL");
              setTypeFilter("ALL");
            }}
          >
            Reset filters
          </button>
        </div>

        {filteredSlices.length > 0 ? (
          <div className="slice-grid">
            {filteredSlices.map((slice) => (
              <SliceCard
                key={slice.id}
                slice={slice}
                onDetails={setSelectedSlice}
                onToggle={toggleSlice}
              />
            ))}
          </div>
        ) : (
          <div className="empty-state">
            <Search size={24} />
            <h3>No matching slices</h3>
            <p>Change your filters or register a new slice.</p>
          </div>
        )}
      </>
    );
  }

  function renderConfiguration() {
    return (
      <>
        <SectionHeader
          title="Configuration"
          description="Current demonstration settings."
        />

        <div className="configuration-grid">
          <article className="panel">
            <h3>Runtime environment</h3>
            <div className="config-row">
              <span>Execution mode</span>
              <strong>Local demo</strong>
            </div>
            <div className="config-row">
              <span>Kubernetes integration</span>
              <strong>Disabled</strong>
            </div>
            <div className="config-row">
              <span>External services</span>
              <strong>Disabled</strong>
            </div>
          </article>

          <article className="panel">
            <h3>Resource guardrails</h3>
            <div className="config-row">
              <span>Maximum CPU</span>
              <strong>4000 millicores</strong>
            </div>
            <div className="config-row">
              <span>Maximum memory</span>
              <strong>8192 MiB</strong>
            </div>
            <div className="config-row">
              <span>Maximum replicas</span>
              <strong>50</strong>
            </div>
          </article>
        </div>

        <p className="panel-note">
          These values are illustrative. They are not applied to a cluster.
        </p>
      </>
    );
  }
REACT

printf 'Partie 1/2 ajoutée au fichier temporaire React.\n'
printf 'Ne pas exécuter ce script avant d’avoir ajouté la partie 2.\n'


cat >> "${TARGET}" <<'REACT'

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-mark">
            <Layers3 size={23} />
          </div>
          <div>
            <strong>AC MultiSlice</strong>
            <span>ORCHESTRATION LAB</span>
          </div>
        </div>

        <span className="nav-label">WORKSPACE</span>

        <nav className="sidebar-nav">
          {[
            { id: "overview", label: "Overview", icon: Activity },
            { id: "inventory", label: "Slice inventory", icon: Boxes },
            { id: "events", label: "Events & logs", icon: Clock3 },
            {
              id: "configuration",
              label: "Configuration",
              icon: Cpu,
            },
          ].map(({ id, label, icon: Icon }) => (
            <button
              key={id}
              className={`nav-item ${page === id ? "active" : ""}`}
              onClick={() => setPage(id)}
            >
              <Icon size={18} />
              {label}
            </button>
          ))}
        </nav>

        <div className="sidebar-bottom">
          <span className="status-dot offline" />
          <div>
            <strong>Demo environment</strong>
            <small>No live cluster connection</small>
          </div>
        </div>
      </aside>

      <main className="main-area">
        <header className="topbar">
          <div className="breadcrumb">
            <span>Workspace</span>
            <span>/</span>
            <strong>{pageTitles[page]}</strong>
          </div>

          <div className="topbar-right">
            <span className="demo-indicator">DEMO MODE</span>
            <div className="avatar" title="Demo user">
              AC
            </div>
          </div>
        </header>

        <div className="page-content">
          {notice && (
            <div className="notice-banner" role="status">
              <CheckCircle2 size={17} />
              <span>{notice}</span>
              <button
                className="icon-button"
                onClick={() => setNotice("")}
                aria-label="Dismiss notification"
              >
                ×
              </button>
            </div>
          )}

          {page === "overview" && renderOverview()}
          {page === "inventory" && renderInventory()}

          {page === "events" && (
            <>
              <SectionHeader
                title="Events & logs"
                description="Actions recorded during this demo session."
                action={
                  <button
                    className="button button-secondary"
                    onClick={() => setEvents([])}
                  >
                    Clear logs
                  </button>
                }
              />
              <EventList events={events} />
            </>
          )}

          {page === "configuration" && renderConfiguration()}
        </div>

        <footer className="app-footer">
          <span>AC MultiSlice Lab</span>
          <span>Demo interface · No live cluster connection</span>
        </footer>
      </main>

      {selectedSlice && (
        <div
          className="modal-backdrop"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) {
              setSelectedSlice(null);
            }
          }}
        >
          <section
            className="modal-panel"
            role="dialog"
            aria-modal="true"
            aria-labelledby="slice-details-title"
          >
            <div className="modal-header">
              <div>
                <span className="eyebrow">SLICE DETAILS</span>
                <h2 id="slice-details-title">{selectedSlice.id}</h2>
              </div>

              <button
                className="icon-button"
                onClick={() => setSelectedSlice(null)}
                aria-label="Close details"
              >
                <X size={20} />
              </button>
            </div>

            <div className="detail-grid">
              <div className="detail-item">
                <span>Profile</span>
                <strong>{selectedSlice.type}</strong>
              </div>

              <div className="detail-item">
                <span>Status</span>
                <StatusBadge status={selectedSlice.status} />
              </div>

              <div className="detail-item">
                <span>Priority</span>
                <strong>{selectedSlice.priority}</strong>
              </div>

              <div className="detail-item">
                <span>Replicas</span>
                <strong>{selectedSlice.replicas}</strong>
              </div>

              <div className="detail-item">
                <span>CPU / replica</span>
                <strong>{selectedSlice.cpu} millicores</strong>
              </div>

              <div className="detail-item">
                <span>Memory / replica</span>
                <strong>{selectedSlice.memory} MiB</strong>
              </div>

              <div className="detail-item">
                <span>Namespace</span>
                <strong>{selectedSlice.namespace}</strong>
              </div>

              <div className="detail-item">
                <span>Deployment</span>
                <strong>{selectedSlice.deploymentName}</strong>
              </div>
            </div>

            <div className="modal-footer">
              <button
                className="button button-secondary"
                onClick={() => setSelectedSlice(null)}
              >
                Close
              </button>

              <button
                className="button button-primary"
                onClick={() => {
                  toggleSlice(selectedSlice);
                  setSelectedSlice(null);
                }}
              >
                {selectedSlice.status === "RUNNING"
                  ? "Simulate stop"
                  : "Simulate deploy"}
              </button>
            </div>

            <p className="modal-disclaimer">
              Demo operation only. No Kubernetes resource is changed.
            </p>
          </section>
        </div>
      )}

      {showCreate && (
        <div
          className="modal-backdrop"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) {
              setShowCreate(false);
            }
          }}
        >
          <section
            className="modal-panel"
            role="dialog"
            aria-modal="true"
            aria-labelledby="create-slice-title"
          >
            <div className="modal-header">
              <div>
                <span className="eyebrow">NEW WORKLOAD</span>
                <h2 id="create-slice-title">Register a slice</h2>
              </div>

              <button
                className="icon-button"
                onClick={() => setShowCreate(false)}
                aria-label="Close form"
              >
                <X size={20} />
              </button>
            </div>

            <form className="slice-form" onSubmit={createSlice}>
              <label>
                Slice identifier
                <input
                  name="id"
                  placeholder="slice-urllc-003"
                  pattern="[a-zA-Z0-9][a-zA-Z0-9._-]*"
                  required
                />
              </label>

              <label>
                Slice profile
                <select name="type" defaultValue="URLLC">
                  <option value="URLLC">URLLC — Low latency</option>
                  <option value="EMBB">eMBB — High bandwidth</option>
                </select>
              </label>

              <label>
                Deployment name
                <input
                  name="deploymentName"
                  placeholder="demo-workload"
                  pattern="[a-zA-Z0-9][a-zA-Z0-9._-]*"
                  required
                />
              </label>

              <p className="form-note">
                The slice is registered in browser memory only.
              </p>

              <div className="modal-footer">
                <button
                  type="button"
                  className="button button-secondary"
                  onClick={() => setShowCreate(false)}
                >
                  Cancel
                </button>

                <button type="submit" className="button button-primary">
                  <Plus size={16} />
                  Create slice
                </button>
              </div>
            </form>
          </section>
        </div>
      )}
    </div>
  );
}
REACT

printf '\nPartie 2/2 terminée.\n'
printf 'Dashboard React complété : %s\n' "${TARGET}"
printf 'Aucun service externe démarré.\n'

# 09C2-ui-dashboard-interactions.sh
# Interactions complémentaires du dashboard AC MultiSlice Lab.
# Aucun service externe n'est démarré.

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/ac-multislice-lab"
SRC="${PROJECT_DIR}/ui-multislice/src"
SERVICES="${SRC}/services"
TARGET="${SERVICES}/dashboardActions.js"

if [ ! -d "${PROJECT_DIR}" ]; then
    printf 'Erreur : exécuter d’abord 01-structure.sh\n' >&2
    exit 1
fi

if [ ! -f "${SRC}/pages/Dashboard.demo.jsx" ]; then
    printf 'Erreur : Dashboard.demo.jsx introuvable.\n' >&2
    printf 'Exécuter d’abord les scripts 09C1A et 09C1B.\n' >&2
    exit 1
fi

mkdir -p "${SERVICES}"

if [ -e "${TARGET}" ]; then
    printf 'Conservé (existe déjà) : %s\n' "${TARGET}"
    exit 0
fi

cat > "${TARGET}" <<'EOF'
/**
 * Actions locales du dashboard AC MultiSlice Lab.
 *
 * Ces fonctions ne communiquent pas avec ONAP ACM ou Kubernetes.
 */

/**
 * Crée un événement de démonstration.
 */
export function createDashboardEvent(type, message) {
  return {
    id: `${Date.now()}-${Math.random()}`,
    time: new Date().toLocaleTimeString("fr-FR"),
    type,
    message,
  };
}

/**
 * Retourne une copie des slices pour éviter de modifier
 * directement le tableau fourni.
 */
export function cloneSlices(slices) {
  if (!Array.isArray(slices)) {
    throw new TypeError("Les slices doivent être un tableau.");
  }

  return slices.map((slice) => ({ ...slice }));
}

/**
 * Vérifie un identifiant de slice.
 */
export function validateSliceId(sliceId) {
  return (
    typeof sliceId === "string"
    && /^[a-zA-Z0-9][a-zA-Z0-9._-]*$/.test(sliceId.trim())
  );
}

/**
 * Construit une nouvelle slice à partir d'un profil.
 */
export function buildDemoSlice({
  id,
  type,
  deploymentName,
  namespace = "network-slices",
}) {
  if (!validateSliceId(id)) {
    throw new Error("Identifiant de slice invalide.");
  }

  if (!validateSliceId(deploymentName)) {
    throw new Error("Nom de Deployment invalide.");
  }

  if (!["URLLC", "EMBB"].includes(type)) {
    throw new Error("Profil de slice non supporté.");
  }

  return {
    id: id.trim(),
    type,
    status: "CREATED",
    priority: type === "URLLC" ? 100 : 50,
    namespace,
    deploymentName: deploymentName.trim(),
    replicas: 1,
    cpu: type === "URLLC" ? 500 : 750,
    memory: type === "URLLC" ? 512 : 1024,
    description:
      type === "URLLC"
        ? "Low latency · Demo workload"
        : "High bandwidth · Demo workload",
  };
}

/**
 * Sérialise l'inventaire pour un export JSON.
 */
export function serializeSlices(slices) {
  if (!Array.isArray(slices)) {
    throw new TypeError("Les slices doivent être un tableau.");
  }

  return JSON.stringify(slices, null, 2);
}

/**
 * Vérifie les limites applicatives de démonstration.
 */
export function validateDemoResources(slice) {
  const errors = [];

  if (!Number.isInteger(slice.replicas)
      || slice.replicas < 0
      || slice.replicas > 50) {
    errors.push("Les replicas doivent être compris entre 0 et 50.");
  }

  if (!Number.isInteger(slice.cpu)
      || slice.cpu < 1
      || slice.cpu > 4000) {
    errors.push("Le CPU doit être compris entre 1 et 4000 millicores.");
  }

  if (!Number.isInteger(slice.memory)
      || slice.memory < 1
      || slice.memory > 8192) {
    errors.push("La mémoire doit être comprise entre 1 et 8192 MiB.");
  }

  if (slice.replicas * slice.cpu > 4000) {
    errors.push("Le budget CPU total est dépassé.");
  }

  if (slice.replicas * slice.memory > 8192) {
    errors.push("Le budget mémoire total est dépassé.");
  }

  return errors;
}
EOF

printf 'Créé : %s\n' "${TARGET}"

# ------------------------------------------------------------
# Documentation des interactions
# ------------------------------------------------------------

DOC="${PROJECT_DIR}/docs/ui-interactions.md"

if [ ! -e "${DOC}" ]; then
    cat > "${DOC}" <<'EOF'
# Interactions du dashboard

Le module `dashboardActions.js` fournit des utilitaires pour :

- valider les identifiants ;
- construire une slice de démonstration ;
- générer des événements ;
- vérifier les limites de ressources ;
- exporter les données en JSON.

## Mode d'exécution

Toutes les opérations sont locales au navigateur.

Aucun appel REST vers ONAP ACM n'est effectué.
Aucune ressource Kubernetes n'est créée ou modifiée.

## Intégration React

Importer les fonctions nécessaires :

```jsx
import {
  buildDemoSlice,
  createDashboardEvent,
  serializeSlices,
  validateDemoResources,
} from "../services/dashboardActions.js";
```

Les opérations de scaling réel nécessitent une API backend sécurisée,
une authentification et une intégration explicitement configurée.
EOF

    printf 'Créé : %s\n' "${DOC}"
else
    printf 'Conservé (existe déjà) : %s\n' "${DOC}"
fi

printf '\n09C2 terminé.\n'
printf 'Utilitaires d’interaction générés.\n'
printf 'Aucun fichier existant écrasé.\n'
printf 'Aucun service démarré.\n'

