
#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/ac-multislice-lab"
RESOURCES="${PROJECT_DIR}/participant-slice/src/main/resources"
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
# application.yaml
# ------------------------------------------------------------

write_file "${RESOURCES}/application.yaml" <<'EOF'
spring:
  application:
    name: ac-multislice-lab

  main:
    banner-mode: "off"

  jackson:
    deserialization:
      fail-on-unknown-properties: false

server:
  port: 8080

# Intégration Kubernetes explicitement désactivée par défaut.
slice:
  kubernetes:
    enabled: false

  quota:
    max-cpu-millicores: 4000
    max-memory-mib: 8192
    max-replicas: 50

  defaults:
    namespace: network-slices
    replicas: 1
    cpu-millicores: 500
    memory-mib: 512

# Kafka n'est pas configuré dans cette version autonome.
# L'intégration Kafka ONAP pourra être ajoutée dans une étape ultérieure.

management:
  endpoints:
    web:
      exposure:
        include: health,info

  endpoint:
    health:
      show-details: never

logging:
  level:
    root: INFO
    org.onap.policy.clamp.acm.participant.multislice: INFO
EOF

# ------------------------------------------------------------
# ParticipantMultiSliceParameters.java
# ------------------------------------------------------------

write_file "${BASE}/parameters/ParticipantMultiSliceParameters.java" <<'EOF'
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
EOF

# ------------------------------------------------------------
# OpenAPI
# ------------------------------------------------------------

write_file "${RESOURCES}/openapi/openapi.yaml" <<'EOF'
openapi: 3.0.3

info:
  title: AC MultiSlice Lab API
  version: 1.0.0
  description: API descriptive du laboratoire multi-slice.

paths:
  /actuator/health:
    get:
      summary: Vérifie l'état du processus applicatif
      responses:
        "200":
          description: Processus accessible

  /api/slices:
    get:
      summary: Point d'entrée réservé à une future API de gestion des slices
      responses:
        "501":
          description: API de gestion non implémentée dans cette version
EOF

# ------------------------------------------------------------
# Informations de profil et sécurité de démarrage
# ------------------------------------------------------------

write_file "${RESOURCES}/application-local.yaml" <<'EOF'
# Profil local : conserve les intégrations externes désactivées.
slice:
  kubernetes:
    enabled: false

logging:
  level:
    root: INFO
EOF

printf '\nPartie 6/8 terminée.\n'
printf 'Configuration Spring Boot et OpenAPI générées.\n'
printf 'Kubernetes reste désactivé.\n'
printf 'Aucun broker Kafka ou autre service n’a été démarré.\n'
