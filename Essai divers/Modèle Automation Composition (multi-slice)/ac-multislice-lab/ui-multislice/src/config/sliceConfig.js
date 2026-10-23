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
