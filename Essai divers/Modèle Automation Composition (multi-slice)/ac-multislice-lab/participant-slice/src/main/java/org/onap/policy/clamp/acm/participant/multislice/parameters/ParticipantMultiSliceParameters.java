package org.onap.policy.clamp.acm.participant.multislice.parameters;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

/**
 * Propriétés centralisées du participant multi-slice.
 */
@Validated
@ConfigurationProperties(prefix = "slice")
public class ParticipantMultiSliceParameters {

    private final Kubernetes kubernetes = new Kubernetes();
    private final Quota quota = new Quota();
    private final Defaults defaults = new Defaults();

    public Kubernetes getKubernetes() {
        return kubernetes;
    }

    public Quota getQuota() {
        return quota;
    }

    public Defaults getDefaults() {
        return defaults;
    }

    public static class Kubernetes {

        private boolean enabled;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }
    }

    public static class Quota {

        @Min(1)
        private int maxCpuMillicores = 4000;

        @Min(1)
        private int maxMemoryMiB = 8192;

        @Min(1)
        private int maxReplicas = 50;

        public int getMaxCpuMillicores() {
            return maxCpuMillicores;
        }

        public void setMaxCpuMillicores(int value) {
            this.maxCpuMillicores = value;
        }

        public int getMaxMemoryMiB() {
            return maxMemoryMiB;
        }

        public void setMaxMemoryMiB(int value) {
            this.maxMemoryMiB = value;
        }

        public int getMaxReplicas() {
            return maxReplicas;
        }

        public void setMaxReplicas(int value) {
            this.maxReplicas = value;
        }
    }

    public static class Defaults {

        @NotBlank
        private String namespace = "network-slices";

        @Min(0)
        private int replicas = 1;

        @Min(1)
        private int cpuMillicores = 500;

        @Min(1)
        private int memoryMiB = 512;

        public String getNamespace() {
            return namespace;
        }

        public void setNamespace(String namespace) {
            this.namespace = namespace;
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
    }
}
