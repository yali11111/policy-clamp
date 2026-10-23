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
