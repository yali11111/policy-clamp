
#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/ac-multislice-lab"
BASE="${PROJECT_DIR}/participant-slice/src/main/java/org/onap/policy/clamp/acm/participant/multislice"

if [ ! -d "${PROJECT_DIR}" ]; then
    printf 'Erreur : exécuter d’abord 01-structure.sh\n' >&2
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
# KubernetesClient.java
# ------------------------------------------------------------

write_file "${BASE}/service/KubernetesClient.java" <<'EOF'
package org.onap.policy.clamp.acm.participant.multislice.service;

import io.fabric8.kubernetes.api.model.ObjectMeta;
import io.fabric8.kubernetes.api.model.apps.Deployment;
import io.fabric8.kubernetes.client.KubernetesClientException;
import io.fabric8.kubernetes.client.KubernetesClientBuilder;
import java.util.Objects;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Façade Kubernetes.
 *
 * L'intégration est désactivée par défaut. Lorsque celle-ci est
 * désactivée, aucune connexion au cluster n'est créée.
 */
@Component
public class KubernetesClient implements AutoCloseable {

    private final boolean enabled;
    private final io.fabric8.kubernetes.client.KubernetesClient client;

    public KubernetesClient(
            @Value("${slice.kubernetes.enabled:false}") boolean enabled) {

        this.enabled = enabled;
        this.client = enabled
                ? new KubernetesClientBuilder().build()
                : null;
    }

    public boolean isEnabled() {
        return enabled;
    }

    /**
     * Retourne le Deployment existant.
     *
     * Aucun Deployment n'est créé implicitement.
     */
    public Deployment requireDeployment(
            String namespace,
            String deploymentName) {

        requireEnabled();
        validateName(namespace, "namespace");
        validateName(deploymentName, "deploymentName");

        Deployment deployment = client.apps()
                .deployments()
                .inNamespace(namespace)
                .withName(deploymentName)
                .get();

        if (deployment == null) {
            throw new IllegalArgumentException(
                    "Deployment introuvable : "
                            + namespace + "/" + deploymentName);
        }

        return deployment;
    }

    /**
     * Met à jour les replicas d'un Deployment existant.
     */
    public void scale(
            String namespace,
            String deploymentName,
            int replicas) {

        requireEnabled();

        if (replicas < 0) {
            throw new IllegalArgumentException(
                    "Le nombre de replicas ne peut pas être négatif.");
        }

        Deployment deployment =
                requireDeployment(namespace, deploymentName);

        client.apps()
                .deployments()
                .inNamespace(namespace)
                .withName(deploymentName)
                .scale(replicas);

        Objects.requireNonNull(deployment.getMetadata());
    }

    /**
     * Retourne le nombre de replicas désiré.
     */
    public int getDesiredReplicas(
            String namespace,
            String deploymentName) {

        Deployment deployment =
                requireDeployment(namespace, deploymentName);

        if (deployment.getSpec() == null
                || deployment.getSpec().getReplicas() == null) {
            return 0;
        }

        return deployment.getSpec().getReplicas();
    }

    private void requireEnabled() {
        if (!enabled || client == null) {
            throw new IllegalStateException(
                    "Kubernetes est désactivé. "
                            + "Définir slice.kubernetes.enabled=true "
                            + "pour activer cette intégration.");
        }
    }

    private void validateName(String value, String property) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    property + " est obligatoire.");
        }
    }

    @Override
    public void close() {
        if (client != null) {
            client.close();
        }
    }
}
EOF

# ------------------------------------------------------------
# QuotaManager.java
# ------------------------------------------------------------

write_file "${BASE}/service/QuotaManager.java" <<'EOF'
package org.onap.policy.clamp.acm.participant.multislice.service;

import org.onap.policy.clamp.acm.participant.multislice.models.SliceConfiguration;
import org.onap.policy.clamp.acm.participant.multislice.models.SlicePriority;
import org.onap.policy.clamp.acm.participant.multislice.models.SliceType;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Validation des demandes de ressources du laboratoire.
 *
 * Les limites sont des garde-fous applicatifs. Elles ne remplacent
 * pas les ResourceQuota du cluster ni un ordonnanceur global.
 */
@Component
public class QuotaManager {

    private final int maxCpuMillicores;
    private final int maxMemoryMiB;
    private final int maxReplicas;

    public QuotaManager(
            @Value("${slice.quota.max-cpu-millicores:4000}")
            int maxCpuMillicores,
            @Value("${slice.quota.max-memory-mib:8192}")
            int maxMemoryMiB,
            @Value("${slice.quota.max-replicas:50}")
            int maxReplicas) {

        if (maxCpuMillicores < 1
                || maxMemoryMiB < 1
                || maxReplicas < 1) {
            throw new IllegalArgumentException(
                    "Les limites de quota doivent être positives.");
        }

        this.maxCpuMillicores = maxCpuMillicores;
        this.maxMemoryMiB = maxMemoryMiB;
        this.maxReplicas = maxReplicas;
    }

    public void validate(SliceConfiguration config) {
        if (config == null) {
            throw new IllegalArgumentException(
                    "La configuration de slice est obligatoire.");
        }

        config.validate();

        validate(
                config.getSliceType(),
                config.getReplicas(),
                config.getCpuMillicores(),
                config.getMemoryMiB());
    }

    /**
     * Valide les ressources demandées par replica.
     */
    public void validate(
            SliceType type,
            int replicas,
            int cpuMillicores,
            int memoryMiB) {

        if (type == null) {
            throw new IllegalArgumentException(
                    "Le type de slice est obligatoire.");
        }

        if (replicas < 0 || replicas > maxReplicas) {
            throw new IllegalArgumentException(
                    "Nombre de replicas hors limites : " + replicas);
        }

        if (cpuMillicores < 1 || cpuMillicores > maxCpuMillicores) {
            throw new IllegalArgumentException(
                    "CPU par replica hors limites : " + cpuMillicores);
        }

        if (memoryMiB < 1 || memoryMiB > maxMemoryMiB) {
            throw new IllegalArgumentException(
                    "Mémoire par replica hors limites : " + memoryMiB);
        }

        long totalCpu = (long) replicas * cpuMillicores;
        long totalMemory = (long) replicas * memoryMiB;

        if (totalCpu > maxCpuMillicores) {
            throw new IllegalArgumentException(
                    "Budget CPU total dépassé : " + totalCpu
                            + " millicores.");
        }

        if (totalMemory > maxMemoryMiB) {
            throw new IllegalArgumentException(
                    "Budget mémoire total dépassé : " + totalMemory
                            + " MiB.");
        }

        // Force la résolution du profil et de sa priorité.
        SlicePriority.forType(type);
    }

    public int getMaxCpuMillicores() {
        return maxCpuMillicores;
    }

    public int getMaxMemoryMiB() {
        return maxMemoryMiB;
    }

    public int getMaxReplicas() {
        return maxReplicas;
    }
}
EOF

# ------------------------------------------------------------
# Scaler.java
# ------------------------------------------------------------

write_file "${BASE}/service/Scaler.java" <<'EOF'
package org.onap.policy.clamp.acm.participant.multislice.service;

import org.springframework.stereotype.Service;

/**
 * Service de mise à l'échelle d'un Deployment.
 */
@Service
public class Scaler {

    private final KubernetesClient kubernetesClient;
    private final QuotaManager quotaManager;

    public Scaler(
            KubernetesClient kubernetesClient,
            QuotaManager quotaManager) {
        this.kubernetesClient = kubernetesClient;
        this.quotaManager = quotaManager;
    }

    /**
     * Applique le nombre de replicas demandé.
     *
     * Les quotas doivent être validés par l'appelant avant le scaling.
     */
    public void scale(
            String namespace,
            String deploymentName,
            int replicas) {

        if (replicas < 0
                || replicas > quotaManager.getMaxReplicas()) {
            throw new IllegalArgumentException(
                    "Nombre de replicas hors limites : " + replicas);
        }

        if (!kubernetesClient.isEnabled()) {
            throw new IllegalStateException(
                    "Scaling impossible : Kubernetes est désactivé.");
        }

        kubernetesClient.scale(
                namespace,
                deploymentName,
                replicas);
    }
}
EOF

printf '\nPartie 3/8 terminée.\n'
printf 'Client Kubernetes, quotas et scaler générés.\n'
printf 'Aucune connexion Kubernetes n’a été effectuée.\n'
printf 'Aucun service n’a été démarré.\n'
