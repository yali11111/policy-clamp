
#!/usr/bin/env bash
# 09D-ui-config.sh
# Partie 1/4 — Initialisation et configuration des profils.
# Aucun service externe n'est démarré.

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/ac-multislice-lab"

SRC="${PROJECT_DIR}/ui-multislice/src"
PAGES="${SRC}/pages"
COMPONENTS="${SRC}/components"
CONFIG="${SRC}/config"
DOCS="${PROJECT_DIR}/docs"

if [ ! -d "${PROJECT_DIR}" ]; then
    printf 'Erreur : exécuter d’abord 01-structure.sh\n' >&2
    exit 1
fi

if [ ! -d "${SRC}" ]; then
    printf 'Erreur : sources React introuvables : %s\n' "${SRC}" >&2
    printf 'Exécuter d’abord les scripts UI précédents.\n' >&2
    exit 1
fi

mkdir -p "${PAGES}" "${COMPONENTS}" "${CONFIG}" "${DOCS}"

# ------------------------------------------------------------
# Fonction de création sans écrasement
# ------------------------------------------------------------

write_file() {
    local target="$1"

    if [ -e "${target}" ]; then
        printf 'Conservé (existe déjà) : %s\n' "${target}"
        cat > /dev/null
        return 0
    fi

    mkdir -p "$(dirname "${target}")"
    cat > "${target}"
    printf 'Créé : %s\n' "${target}"
}

# ------------------------------------------------------------
# Configuration par défaut des slices
# ------------------------------------------------------------

write_file "${CONFIG}/sliceConfig.js" <<'EOF'
/**
 * Configuration applicative de démonstration AC MultiSlice Lab.
 *
 * Ces valeurs servent à l'interface React.
 * Elles ne configurent pas directement un cluster Kubernetes.
 */

export const defaultSliceConfig = {
  namespace: "network-slices",
  replicas: 1,
  cpuMillicores: 500,
  memoryMiB: 512,
};

export const defaultQuotaConfig = {
  maxCpuMillicores: 4000,
  maxMemoryMiB: 8192,
  maxReplicas: 50,
};

export const sliceProfiles = {
  URLLC: {
    label: "URLLC",
    description: "Profil applicatif sensible à la latence",
    priority: 100,
    cpuMillicores: 1000,
    memoryMiB: 1024,
  },

  EMBB: {
    label: "eMBB",
    description: "Profil applicatif orienté débit",
    priority: 50,
    cpuMillicores: 500,
    memoryMiB: 512,
  },
};

/**
 * Construit une configuration initiale indépendante.
 */
export function createInitialSliceConfig() {
  return {
    ...defaultSliceConfig,
    ...defaultQuotaConfig,
    kubernetesEnabled: false,
    demoMode: true,
  };
}

/**
 * Calcule les ressources demandées.
 */
export function calculateResources(config) {
  const replicas = Number(config.replicas) || 0;
  const cpuMillicores = Number(config.cpuMillicores) || 0;
  const memoryMiB = Number(config.memoryMiB) || 0;

  return {
    totalCpuMillicores: replicas * cpuMillicores,
    totalMemoryMiB: replicas * memoryMiB,
  };
}

/**
 * Vérifie les quotas de démonstration.
 */
export function validateSliceConfig(config) {
  const errors = [];

  const replicas = Number(config.replicas);
  const cpu = Number(config.cpuMillicores);
  const memory = Number(config.memoryMiB);
  const maxCpu = Number(config.maxCpuMillicores);
  const maxMemory = Number(config.maxMemoryMiB);
  const maxReplicas = Number(config.maxReplicas);

  if (
    typeof config.namespace !== "string"
    || !config.namespace.trim()
  ) {
    errors.push("Le namespace est obligatoire.");
  }

  if (
    !Number.isInteger(replicas)
    || replicas < 0
    || replicas > maxReplicas
  ) {
    errors.push(
      `Les replicas doivent être compris entre 0 et ${maxReplicas}.`
    );
  }

  if (!Number.isFinite(cpu) || cpu < 1 || cpu > maxCpu) {
    errors.push(
      `Le CPU par replica doit être compris entre 1 et ${maxCpu} millicores.`
    );
  }

  if (
    !Number.isFinite(memory)
    || memory < 1
    || memory > maxMemory
  ) {
    errors.push(
      `La mémoire par replica doit être comprise entre 1 et ${maxMemory} MiB.`
    );
  }

  if (
    Number.isFinite(replicas)
    && Number.isFinite(cpu)
    && replicas * cpu > maxCpu
  ) {
    errors.push("Le budget CPU total est dépassé.");
  }

  if (
    Number.isFinite(replicas)
    && Number.isFinite(memory)
    && replicas * memory > maxMemory
  ) {
    errors.push("Le budget mémoire total est dépassé.");
  }

  return errors;
}
EOF

printf '\nPartie 1/4 préparée.\n'
printf 'Configuration des profils et validation générées.\n'
printf 'Ne pas exécuter le script avant les 4 parties.\n'

# La partie 2/4 continuera ici.


# ------------------------------------------------------------
# Partie 2/4 — Composants React réutilisables
# ------------------------------------------------------------

write_file "${COMPONENTS}/ConfigField.jsx" <<'EOF'
import { useId } from "react";

export default function ConfigField({
  label,
  hint,
  children,
}) {
  const id = useId();

  return (
    <div className="config-field">
      <label
        className="config-field-label"
        htmlFor={id}
      >
        {label}
      </label>

      <div className="config-field-control">
        {typeof children === "function"
          ? children(id)
          : children}
      </div>

      {hint && (
        <p className="config-field-hint">
          {hint}
        </p>
      )}
    </div>
  );
}
EOF

write_file "${COMPONENTS}/ConfigSection.jsx" <<'EOF'
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
EOF

write_file "${COMPONENTS}/ResourceMeter.jsx" <<'EOF'
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
EOF

write_file "${COMPONENTS}/IntegrationStatus.jsx" <<'EOF'
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
EOF

printf '\nPartie 2/4 préparée.\n'
printf 'Composants React de configuration générés.\n'
printf 'Ne pas exécuter le script avant les 4 parties.\n'

# La partie 3/4 continuera ici.


# ------------------------------------------------------------
# Partie 3/4 — Page de configuration React
# ------------------------------------------------------------

write_file "${PAGES}/Configuration.demo.jsx" <<'EOF'
import { useMemo, useState } from "react";
import {
  Save,
  RotateCcw,
  Info,
  CheckCircle2,
  AlertTriangle,
  Settings2,
} from "lucide-react";

import {
  createInitialSliceConfig,
  sliceProfiles,
  calculateResources,
  validateSliceConfig,
} from "../config/sliceConfig.js";

import ConfigField from "../components/ConfigField.jsx";
import ConfigSection from "../components/ConfigSection.jsx";
import ResourceMeter from "../components/ResourceMeter.jsx";
import IntegrationStatus from "../components/IntegrationStatus.jsx";

const initialConfig = createInitialSliceConfig();

export default function ConfigurationDemo() {
  const [config, setConfig] = useState({ ...initialConfig });
  const [errors, setErrors] = useState([]);
  const [notice, setNotice] = useState("");
  const [savedConfig, setSavedConfig] = useState(null);

  const resources = useMemo(
    () => calculateResources(config),
    [config]
  );

  const profileName = useMemo(() => {
    const match = Object.entries(sliceProfiles).find(
      ([, profile]) =>
        profile.cpuMillicores === Number(config.cpuMillicores)
        && profile.memoryMiB === Number(config.memoryMiB)
    );

    return match?.[0] ?? "CUSTOM";
  }, [config.cpuMillicores, config.memoryMiB]);

  function update(key, value) {
    setConfig((current) => ({
      ...current,
      [key]: value,
    }));

    setErrors([]);
    setNotice("");
  }

  function applyProfile(type) {
    const profile = sliceProfiles[type];

    if (!profile) {
      return;
    }

    setConfig((current) => ({
      ...current,
      cpuMillicores: profile.cpuMillicores,
      memoryMiB: profile.memoryMiB,
    }));

    setErrors([]);
    setNotice("");
  }

  function saveConfiguration(event) {
    event.preventDefault();

    const validationErrors = validateSliceConfig(config);
    setErrors(validationErrors);

    if (validationErrors.length > 0) {
      setNotice("");
      return;
    }

    const normalizedConfig = {
      ...config,
      replicas: Number(config.replicas),
      cpuMillicores: Number(config.cpuMillicores),
      memoryMiB: Number(config.memoryMiB),
      maxCpuMillicores: Number(config.maxCpuMillicores),
      maxMemoryMiB: Number(config.maxMemoryMiB),
      maxReplicas: Number(config.maxReplicas),
    };

    setConfig(normalizedConfig);
    setSavedConfig(normalizedConfig);
    setNotice(
      "Configuration validée pour cette session de démonstration."
    );
  }

  function resetConfiguration() {
    const reset = { ...initialConfig };

    setConfig(reset);
    setSavedConfig(null);
    setErrors([]);
    setNotice("Valeurs par défaut restaurées.");
  }

  function exportConfiguration() {
    const validationErrors = validateSliceConfig(config);
    setErrors(validationErrors);

    if (validationErrors.length > 0) {
      setNotice("");
      return;
    }

    const blob = new Blob(
      [JSON.stringify(config, null, 2)],
      { type: "application/json;charset=utf-8" }
    );

    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");

    link.href = url;
    link.download = "ac-multislice-config.json";
    document.body.appendChild(link);
    link.click();
    link.remove();
    URL.revokeObjectURL(url);

    setNotice("Export JSON déclenché.");
  }

  const cpuPercentage = Number(config.maxCpuMillicores) > 0
    ? resources.totalCpuMillicores / Number(config.maxCpuMillicores)
    : 0;

  const memoryPercentage = Number(config.maxMemoryMiB) > 0
    ? resources.totalMemoryMiB / Number(config.maxMemoryMiB)
    : 0;

  return (
    <div className="configuration-page">
      <header className="config-page-header">
        <div>
          <div className="config-eyebrow">
            <Settings2 size={15} />
            WORKSPACE SETTINGS
          </div>

          <h1>Configuration</h1>

          <p>
            Configurez les profils applicatifs et les limites
            de ressources du laboratoire multi-slice.
          </p>
        </div>

        <div className="config-header-actions">
          <button
            type="button"
            className="button button-secondary"
            onClick={resetConfiguration}
          >
            <RotateCcw size={16} />
            Réinitialiser
          </button>

          <button
            type="button"
            className="button button-secondary"
            onClick={exportConfiguration}
          >
            Exporter JSON
          </button>

          <button
            type="submit"
            form="slice-config-form"
            className="button button-primary"
          >
            <Save size={16} />
            Enregistrer
          </button>
        </div>
      </header>

      <div className="config-demo-banner">
        <Info size={19} />

        <div>
          <strong>Environnement de démonstration</strong>
          <p>
            Les paramètres sont gérés localement dans cette page.
            Ils ne sont pas appliqués à un cluster Kubernetes ni au
            runtime ONAP ACM.
          </p>
        </div>
      </div>

      {notice && (
        <div className="config-success" role="status">
          <CheckCircle2 size={18} />
          <span>{notice}</span>
        </div>
      )}

      {errors.length > 0 && (
        <div className="config-errors" role="alert">
          <AlertTriangle size={19} />

          <div>
            <strong>Configuration invalide</strong>
            <ul>
              {errors.map((error) => (
                <li key={error}>{error}</li>
              ))}
            </ul>
          </div>
        </div>
      )}

      <form
        id="slice-config-form"
        onSubmit={saveConfiguration}
      >
        <div className="config-layout">
          <div className="config-main-column">
            <ConfigSection
              icon="layers"
              title="Paramètres des slices"
              description="Valeurs utilisées comme paramètres par défaut."
            >
              <ConfigField
                label="Namespace Kubernetes"
                hint="Namespace logique cible, sans création automatique."
              >
                {(id) => (
                  <input
                    id={id}
                    name="namespace"
                    value={config.namespace}
                    onChange={(event) =>
                      update("namespace", event.target.value)
                    }
                    placeholder="network-slices"
                    required
                  />
                )}
              </ConfigField>

              <div className="config-two-columns">
                <ConfigField label="Nombre de replicas">
                  {(id) => (
                    <input
                      id={id}
                      name="replicas"
                      type="number"
                      min="0"
                      max={config.maxReplicas}
                      step="1"
                      value={config.replicas}
                      onChange={(event) =>
                        update("replicas", event.target.value)
                      }
                      required
                    />
                  )}
                </ConfigField>

                <ConfigField label="Profil applicatif">
                  {(id) => (
                    <select
                      id={id}
                      value={profileName}
                      onChange={(event) =>
                        applyProfile(event.target.value)
                      }
                    >
                      <option value="URLLC">
                        URLLC — Sensible à la latence
                      </option>
                      <option value="EMBB">
                        eMBB — Orienté débit
                      </option>
                      <option value="CUSTOM" disabled>
                        Configuration personnalisée
                      </option>
                    </select>
                  )}
                </ConfigField>
              </div>

              {profileName !== "CUSTOM" && (
                <div className="profile-preview">
                  <span className="profile-preview-dot" />

                  <div>
                    <strong>
                      {sliceProfiles[profileName].label}
                    </strong>
                    <p>
                      {sliceProfiles[profileName].description}
                    </p>
                  </div>

                  <span className="profile-priority">
                    Priorité {sliceProfiles[profileName].priority}
                  </span>
                </div>
              )}
            </ConfigSection>

            <ConfigSection
              icon="cpu"
              title="Ressources par replica"
              description="Demandes théoriques pour chaque instance."
            >
              <div className="config-two-columns">
                <ConfigField
                  label="CPU (millicores)"
                  hint="1000 millicores correspondent à 1 CPU."
                >
                  {(id) => (
                    <input
                      id={id}
                      name="cpuMillicores"
                      type="number"
                      min="1"
                      max={config.maxCpuMillicores}
                      step="1"
                      value={config.cpuMillicores}
                      onChange={(event) =>
                        update("cpuMillicores", event.target.value)
                      }
                      required
                    />
                  )}
                </ConfigField>

                <ConfigField
                  label="Mémoire (MiB)"
                  hint="Quantité de mémoire demandée par replica."
                >
                  {(id) => (
                    <input
                      id={id}
                      name="memoryMiB"
                      type="number"
                      min="1"
                      max={config.maxMemoryMiB}
                      step="1"
                      value={config.memoryMiB}
                      onChange={(event) =>
                        update("memoryMiB", event.target.value)
                      }
                      required
                    />
                  )}
                </ConfigField>
              </div>
            </ConfigSection>

            <ConfigSection
              icon="shield"
              title="Quotas applicatifs"
              description="Limites utilisées par le validateur local."
            >
              <div className="config-two-columns">
                <ConfigField label="CPU total maximum (millicores)">
                  {(id) => (
                    <input
                      id={id}
                      name="maxCpuMillicores"
                      type="number"
                      min="1"
                      step="1"
                      value={config.maxCpuMillicores}
                      onChange={(event) =>
                        update("maxCpuMillicores", event.target.value)
                      }
                      required
                    />
                  )}
                </ConfigField>

                <ConfigField label="Mémoire totale maximum (MiB)">
                  {(id) => (
                    <input
                      id={id}
                      name="maxMemoryMiB"
                      type="number"
                      min="1"
                      step="1"
                      value={config.maxMemoryMiB}
                      onChange={(event) =>
                        update("maxMemoryMiB", event.target.value)
                      }
                      required
                    />
                  )}
                </ConfigField>

                <ConfigField label="Nombre maximum de replicas">
                  {(id) => (
                    <input
                      id={id}
                      name="maxReplicas"
                      type="number"
                      min="1"
                      step="1"
                      value={config.maxReplicas}
                      onChange={(event) =>
                        update("maxReplicas", event.target.value)
                      }
                      required
                    />
                  )}
                </ConfigField>
              </div>
            </ConfigSection>
          </div>

          <aside className="config-side-column">
            <ConfigSection
              icon="database"
              title="Estimation des ressources"
              description="Calculée à partir des paramètres courants."
            >
              <div className="resource-summary">
                <div className="resource-summary-row">
                  <span>Replicas demandés</span>
                  <strong>{Number(config.replicas) || 0}</strong>
                </div>

                <ResourceMeter
                  label="CPU total"
                  value={resources.totalCpuMillicores}
                  maximum={config.maxCpuMillicores}
                  unit="mCPU"
                  color="cpu"
                />

                <ResourceMeter
                  label="Mémoire totale"
                  value={resources.totalMemoryMiB}
                  maximum={config.maxMemoryMiB}
                  unit="MiB"
                  color="memory"
                />

                {(cpuPercentage > 1 || memoryPercentage > 1) && (
                  <p className="resource-warning">
                    Une ou plusieurs limites sont dépassées.
                  </p>
                )}

                <p className="resource-footnote">
                  Estimation théorique : aucune mesure réelle
                  du cluster n'est effectuée.
                </p>
              </div>
            </ConfigSection>

            <ConfigSection
              icon="shield"
              title="État des intégrations"
              description="État déclaré pour cette démonstration."
            >
              <IntegrationStatus
                name="Kubernetes"
                description="Connexion au cluster"
                enabled={false}
              />

              <IntegrationStatus
                name="ONAP ACM"
                description="Cycle de vie du participant"
                enabled={false}
              />

              <IntegrationStatus
                name="Kafka"
                description="Transport des événements"
                enabled={false}
              />
            </ConfigSection>

            <div className="config-summary-card">
              <span className="config-summary-label">
                ÉTAT DE LA CONFIGURATION
              </span>

              <strong>
                {errors.length > 0
                  ? "À corriger"
                  : savedConfig
                    ? "Validée"
                    : "Non enregistrée"}
              </strong>

              <p>
                {savedConfig
                  ? "La configuration a été validée en mémoire."
                  : "Validez les paramètres pour préparer l'export."}
              </p>
            </div>
          </aside>
        </div>
      </form>

      <footer className="config-page-footer">
        <span>AC MultiSlice Lab</span>
        <span>Configuration locale · Demo mode</span>
      </footer>
    </div>
  );
}
EOF

printf '\nPartie 3/4 préparée.\n'
printf 'Page Configuration.demo.jsx générée par le script.\n'
printf 'Ne pas exécuter avant la partie 4/4.\n'

# La partie 4/4 continuera ici.


# ------------------------------------------------------------
# Partie 4/4 — Styles, documentation et vérifications
# ------------------------------------------------------------

# ------------------------------------------------------------
# Feuille de styles de la page Configuration
# ------------------------------------------------------------

write_file "${SRC}/styles/configuration.css" <<'EOF'
/* AC MultiSlice Lab — Configuration */

.configuration-page {
  --config-bg: #f6f8fc;
  --config-card: #ffffff;
  --config-border: #e3e8f0;
  --config-text: #172033;
  --config-muted: #667085;
  --config-primary: #3659d9;
  --config-primary-light: #edf2ff;
  --config-success: #157347;
  --config-danger: #b42318;

  min-height: 100vh;
  padding: 32px;
  color: var(--config-text);
  background: var(--config-bg);
  font-family: Inter, system-ui, -apple-system, sans-serif;
}

.configuration-page *,
.configuration-page *::before,
.configuration-page *::after {
  box-sizing: border-box;
}

.configuration-page button,
.configuration-page input,
.configuration-page select {
  font: inherit;
}

.config-page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 24px;
  margin-bottom: 24px;
}

.config-eyebrow {
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--config-primary);
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.12em;
}

.config-page-header h1 {
  margin: 12px 0 8px;
  font-size: clamp(28px, 3vw, 36px);
  line-height: 1.2;
  letter-spacing: -0.04em;
}

.config-page-header > div:first-child > p {
  max-width: 650px;
  margin: 0;
  color: var(--config-muted);
  font-size: 14px;
  line-height: 1.7;
}

.config-header-actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 10px;
}

.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-height: 40px;
  padding: 0 14px;
  border: 1px solid transparent;
  border-radius: 9px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 650;
  transition:
    background 150ms ease,
    border-color 150ms ease,
    transform 150ms ease;
}

.button:active {
  transform: translateY(1px);
}

.button:focus-visible,
.configuration-page input:focus-visible,
.configuration-page select:focus-visible {
  outline: 3px solid #a5b8ff;
  outline-offset: 2px;
}

.button-primary {
  color: white;
  background: var(--config-primary);
}

.button-primary:hover {
  background: #2947b8;
}

.button-secondary {
  color: #344054;
  background: white;
  border-color: var(--config-border);
}

.button-secondary:hover {
  background: #f9fafb;
  border-color: #b7c2d5;
}

.config-demo-banner,
.config-success,
.config-errors {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 22px;
  padding: 15px 17px;
  border: 1px solid;
  border-radius: 11px;
}

.config-demo-banner {
  color: #2444a6;
  background: #eef3ff;
  border-color: #d6e1ff;
}

.config-demo-banner > svg {
  flex-shrink: 0;
  margin-top: 2px;
}

.config-demo-banner strong,
.config-errors strong {
  display: block;
  font-size: 13px;
}

.config-demo-banner p {
  margin: 5px 0 0;
  color: #425a91;
  font-size: 12px;
  line-height: 1.6;
}

.config-success {
  align-items: center;
  color: #166534;
  background: #f0fdf4;
  border-color: #bbf7d0;
  font-size: 13px;
}

.config-errors {
  color: #991b1b;
  background: #fef2f2;
  border-color: #fecaca;
}

.config-errors ul {
  margin: 8px 0 0;
  padding-left: 18px;
  font-size: 13px;
  line-height: 1.7;
}

.config-layout {
  display: grid;
  grid-template-columns: minmax(0, 1.65fr) minmax(280px, 0.9fr);
  align-items: start;
  gap: 22px;
}

.config-main-column,
.config-side-column {
  display: grid;
  min-width: 0;
  gap: 20px;
}

.config-card {
  min-width: 0;
  overflow: hidden;
  background: var(--config-card);
  border: 1px solid var(--config-border);
  border-radius: 14px;
  box-shadow: 0 2px 5px rgb(16 24 40 / 2%);
}

.config-card-heading {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 20px;
  border-bottom: 1px solid #edf0f5;
}

.config-card-icon {
  display: grid;
  flex-shrink: 0;
  width: 38px;
  height: 38px;
  place-items: center;
  color: var(--config-primary);
  background: var(--config-primary-light);
  border-radius: 10px;
}

.config-card-title-group {
  min-width: 0;
}

.config-card-title-group h2 {
  margin: 1px 0 5px;
  font-size: 15px;
  font-weight: 750;
  letter-spacing: -0.02em;
}

.config-card-title-group p {
  margin: 0;
  color: var(--config-muted);
  font-size: 12px;
  line-height: 1.6;
}

.config-card-body {
  display: grid;
  gap: 20px;
  padding: 20px;
}

.config-field {
  display: grid;
  min-width: 0;
  gap: 8px;
}

.config-field-label {
  color: #344054;
  font-size: 12px;
  font-weight: 700;
}

.config-field-control input,
.config-field-control select {
  width: 100%;
  min-width: 0;
  height: 42px;
  padding: 0 12px;
  color: #1d2939;
  background: white;
  border: 1px solid #d0d7e2;
  border-radius: 8px;
  font-size: 13px;
}

.config-field-control input:hover,
.config-field-control select:hover {
  border-color: #aab6c8;
}

.config-field-hint {
  margin: 0;
  color: var(--config-muted);
  font-size: 11px;
  line-height: 1.5;
}

.config-two-columns {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 18px;
}

.profile-preview {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 13px;
  background: #f8faff;
  border: 1px solid #e0e8ff;
  border-radius: 10px;
}

.profile-preview-dot {
  width: 9px;
  height: 9px;
  flex-shrink: 0;
  background: var(--config-primary);
  border-radius: 50%;
}

.profile-preview > div {
  flex: 1;
  min-width: 0;
}

.profile-preview strong {
  font-size: 12px;
}

.profile-preview p {
  margin: 4px 0 0;
  color: var(--config-muted);
  font-size: 11px;
  line-height: 1.5;
}

.profile-priority {
  flex-shrink: 0;
  padding: 5px 8px;
  color: #344cb4;
  background: #e9eeff;
  border-radius: 6px;
  font-size: 10px;
  font-weight: 750;
}

.resource-summary {
  display: grid;
  gap: 22px;
}

.resource-summary-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding-bottom: 15px;
  border-bottom: 1px solid #edf0f5;
}

.resource-summary-row span {
  color: var(--config-muted);
  font-size: 12px;
}

.resource-summary-row strong {
  font-size: 22px;
  letter-spacing: -0.04em;
}

.resource-meter-block {
  display: grid;
  gap: 9px;
}

.resource-meter-heading,
.resource-meter-caption {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.resource-meter-heading {
  font-size: 12px;
}

.resource-meter-heading span {
  color: #475467;
}

.resource-meter-heading strong {
  font-size: 12px;
}

.resource-meter-track {
  width: 100%;
  height: 8px;
  overflow: hidden;
  background: #edf0f5;
  border-radius: 999px;
}

.resource-meter-fill {
  height: 100%;
  min-width: 0;
  border-radius: inherit;
  transition: width 200ms ease;
}

.cpu-fill {
  background: #4969e7;
}

.memory-fill {
  background: #16a085;
}

.resource-meter-exceeded {
  background: #dc2626;
}

.resource-meter-caption {
  color: var(--config-muted);
  font-size: 10px;
}

.resource-warning {
  margin: 0;
  padding: 10px;
  color: #9a3412;
  background: #fff7ed;
  border: 1px solid #fed7aa;
  border-radius: 8px;
  font-size: 11px;
  line-height: 1.6;
}

.resource-footnote {
  margin: 0;
  color: var(--config-muted);
  font-size: 11px;
  line-height: 1.7;
}

.integration-status {
  display: flex;
  align-items: center;
  gap: 10px;
}

.integration-status-icon {
  display: grid;
  flex-shrink: 0;
  width: 34px;
  height: 34px;
  place-items: center;
  color: #667085;
  background: #f2f4f7;
  border-radius: 9px;
}

.integration-status-info {
  display: grid;
  flex: 1;
  min-width: 0;
  gap: 4px;
}

.integration-status-info strong {
  font-size: 12px;
}

.integration-status-info small {
  color: var(--config-muted);
  font-size: 10px;
}

.integration-pill {
  display: inline-flex;
  align-items: center;
  flex-shrink: 0;
  gap: 5px;
  padding: 5px 7px;
  color: #667085;
  background: #f2f4f7;
  border-radius: 6px;
  font-size: 10px;
  font-weight: 700;
}

.integration-pill-enabled {
  color: #166534;
  background: #dcfce7;
}

.config-summary-card {
  display: grid;
  gap: 10px;
  padding: 19px;
  background: white;
  border: 1px solid var(--config-border);
  border-radius: 14px;
}

.config-summary-label {
  color: var(--config-muted);
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.1em;
}

.config-summary-card > strong {
  font-size: 20px;
  letter-spacing: -0.03em;
}

.config-summary-card p {
  margin: 0;
  color: var(--config-muted);
  font-size: 12px;
  line-height: 1.7;
}

.config-page-footer {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 12px;
  margin-top: 28px;
  padding-top: 18px;
  color: var(--config-muted);
  border-top: 1px solid var(--config-border);
  font-size: 11px;
}

@media (max-width: 1050px) {
  .config-page-header {
    flex-direction: column;
  }

  .config-header-actions {
    justify-content: flex-start;
  }

  .config-layout {
    grid-template-columns: minmax(0, 1fr);
  }

  .config-side-column {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    align-items: start;
  }

  .config-side-column > :last-child {
    grid-column: 1 / -1;
  }
}

@media (max-width: 640px) {
  .configuration-page {
    padding: 18px 14px;
  }

  .config-header-actions {
    display: grid;
    width: 100%;
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .config-header-actions .button {
    width: 100%;
    padding: 0 8px;
    font-size: 11px;
  }

  .config-header-actions .button-primary {
    grid-column: 1 / -1;
  }

  .config-card-heading,
  .config-card-body {
    padding: 15px;
  }

  .config-two-columns,
  .config-side-column {
    grid-template-columns: minmax(0, 1fr);
  }

  .config-side-column > :last-child {
    grid-column: auto;
  }

  .profile-preview {
    align-items: flex-start;
    flex-wrap: wrap;
  }

  .profile-priority {
    margin-left: 19px;
  }
}
EOF

# ------------------------------------------------------------
# Documentation de la page de configuration
# ------------------------------------------------------------

write_file "${DOCS}/ui-configuration.md" <<'EOF'
# Interface de configuration AC MultiSlice Lab

## Objectif

La page `Configuration.demo.jsx` permet de tester les paramètres
applicatifs des profils URLLC et eMBB.

## Fonctionnalités

- Sélection d'un profil et application de ses valeurs par défaut.
- Configuration du namespace et du nombre de replicas.
- Configuration CPU et mémoire par replica.
- Configuration des quotas applicatifs.
- Calcul local des ressources théoriques.
- Validation des valeurs avant enregistrement.
- Réinitialisation des paramètres.
- Export de la configuration au format JSON.
- Affichage de l'état des intégrations externes.

## Fichiers générés

- `ui-multislice/src/config/sliceConfig.js`
- `ui-multislice/src/components/ConfigField.jsx`
- `ui-multislice/src/components/ConfigSection.jsx`
- `ui-multislice/src/components/ResourceMeter.jsx`
- `ui-multislice/src/components/IntegrationStatus.jsx`
- `ui-multislice/src/pages/Configuration.demo.jsx`
- `ui-multislice/src/styles/configuration.css`

## Intégration dans l'application React

Importer la feuille CSS et la page depuis le point d'entrée existant :

    import "./styles/configuration.css";
    import ConfigurationDemo from "./pages/Configuration.demo.jsx";

Puis rendre le composant dans la route ou la zone de contenu souhaitée :

    <ConfigurationDemo />

Ne pas remplacer automatiquement le routeur ou le point d'entrée existant :
adapter les imports à l'architecture réelle de l'application.

## Dépendances

La page utilise React et `lucide-react`.

Si cette dernière dépendance est absente du projet, l'ajouter avec :

    npm install lucide-react

## Limites

- L'enregistrement est local à la session React.
- Aucun backend n'est appelé.
- L'export JSON est effectué par le navigateur.
- Kubernetes, ONAP ACM et Kafka ne sont pas connectés.
- Les quotas sont des garde-fous de démonstration, pas des quotas
  effectifs du cluster.
- Les profils URLLC et eMBB ne garantissent ni latence, ni débit,
  ni qualité de service réseau.
EOF

# ------------------------------------------------------------
# Vérifications de génération
# ------------------------------------------------------------

printf '\n=== Vérification des fichiers de configuration UI ===\n'

for file in \
    "${CONFIG}/sliceConfig.js" \
    "${COMPONENTS}/ConfigField.jsx" \
    "${COMPONENTS}/ConfigSection.jsx" \
    "${COMPONENTS}/ResourceMeter.jsx" \
    "${COMPONENTS}/IntegrationStatus.jsx" \
    "${PAGES}/Configuration.demo.jsx" \
    "${SRC}/styles/configuration.css" \
    "${DOCS}/ui-configuration.md"
do
    if [ -f "${file}" ]; then
        printf '[OK] %s\n' "${file}"
    else
        printf '[MANQUANT] %s\n' "${file}" >&2
        exit 1
    fi
done

printf '\nPartie 4/4 terminée.\n'
printf 'Configuration React, styles et documentation générés.\n'
printf 'Aucun service externe n’a été démarré.\n'
printf '\nGénération terminée.\n'
