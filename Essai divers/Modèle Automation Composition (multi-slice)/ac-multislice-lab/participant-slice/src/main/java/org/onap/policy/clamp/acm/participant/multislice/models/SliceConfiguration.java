package org.onap.policy.clamp.acm.participant.multislice.models;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Configuration applicative d'une slice.
 *
 * Cette classe peut être construite à partir des propriétés
 * d'entrée d'un élément Automation Composition.
 */
public class SliceConfiguration {

    @NotBlank
    private String sliceId;

    @NotNull
    private SliceType sliceType;

    @NotBlank
    private String namespace = "network-slices";

    @NotBlank
    private String deploymentName;

    @Min(0)
    private int replicas = 1;

    @Min(1)
    private int cpuMillicores = 500;

    @Min(1)
    private int memoryMiB = 512;

    public SliceConfiguration() {
        // Constructeur requis pour la désérialisation JSON.
    }

    public String getSliceId() {
        return sliceId;
    }

    public void setSliceId(String sliceId) {
        this.sliceId = sliceId;
    }

    public SliceType getSliceType() {
        return sliceType;
    }

    public void setSliceType(SliceType sliceType) {
        this.sliceType = sliceType;
    }

    public String getNamespace() {
        return namespace;
    }

    public void setNamespace(String namespace) {
        this.namespace = namespace;
    }

    public String getDeploymentName() {
        return deploymentName;
    }

    public void setDeploymentName(String deploymentName) {
        this.deploymentName = deploymentName;
    }

    public int getReplicas() {
        return replicas;
    }

    public void setReplicas(int replicas) {
        this.replicas = replicas;
    }

    public int getCpuMillicores() {
        return cpuMillicores;
    }

    public void setCpuMillicores(int cpuMillicores) {
        this.cpuMillicores = cpuMillicores;
    }

    public int getMemoryMiB() {
        return memoryMiB;
    }

    public void setMemoryMiB(int memoryMiB) {
        this.memoryMiB = memoryMiB;
    }

    /**
     * Vérifie les propriétés indépendamment de la validation Spring.
     */
    public void validate() {
        if (sliceId == null || sliceId.isBlank()) {
            throw new IllegalArgumentException(
                    "sliceId est obligatoire.");
        }

        if (sliceType == null) {
            throw new IllegalArgumentException(
                    "sliceType est obligatoire.");
        }

        if (namespace == null || namespace.isBlank()) {
            throw new IllegalArgumentException(
                    "namespace est obligatoire.");
        }

        if (deploymentName == null || deploymentName.isBlank()) {
            throw new IllegalArgumentException(
                    "deploymentName est obligatoire.");
        }

        if (replicas < 0) {
            throw new IllegalArgumentException(
                    "replicas ne peut pas être négatif.");
        }

        if (cpuMillicores < 1) {
            throw new IllegalArgumentException(
                    "cpuMillicores doit être supérieur à zéro.");
        }

        if (memoryMiB < 1) {
            throw new IllegalArgumentException(
                    "memoryMiB doit être supérieur à zéro.");
        }
    }
}
