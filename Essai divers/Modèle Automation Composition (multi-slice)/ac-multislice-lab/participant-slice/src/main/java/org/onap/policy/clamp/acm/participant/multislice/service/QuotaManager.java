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
