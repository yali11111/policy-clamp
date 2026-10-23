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
