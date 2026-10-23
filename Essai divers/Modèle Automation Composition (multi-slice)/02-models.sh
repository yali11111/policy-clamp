
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
# SliceType.java
# ------------------------------------------------------------

write_file "${BASE}/models/SliceType.java" <<'EOF'
package org.onap.policy.clamp.acm.participant.multislice.models;

import java.util.Locale;

/**
 * Profils de slice pris en charge par le laboratoire.
 *
 * Les profils sont des catégories applicatives.
 * Ils ne configurent pas directement les paramètres radio 5G.
 */
public enum SliceType {

    URLLC("URLLC"),
    EMBB("eMBB");

    private final String externalName;

    SliceType(String externalName) {
        this.externalName = externalName;
    }

    public String externalName() {
        return externalName;
    }

    /**
     * Convertit un nom reçu dans les propriétés de composition.
     */
    public static SliceType from(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    "Le type de slice est obligatoire.");
        }

        String normalized = value.trim().toUpperCase(Locale.ROOT);

        return switch (normalized) {
            case "URLLC" -> URLLC;
            case "EMBB" -> EMBB;
            default -> throw new IllegalArgumentException(
                    "Type de slice non supporté : " + value);
        };
    }
}
EOF

# ------------------------------------------------------------
# SlicePriority.java
# ------------------------------------------------------------

write_file "${BASE}/models/SlicePriority.java" <<'EOF'
package org.onap.policy.clamp.acm.participant.multislice.models;

/**
 * Priorité applicative des profils du laboratoire.
 *
 * Une valeur plus élevée indique une priorité logique plus élevée.
 * Cette valeur ne configure pas automatiquement les priorités
 * Kubernetes, les 5QI ou les politiques QoS du réseau.
 */
public enum SlicePriority {

    URLLC(100),
    EMBB(50);

    private final int value;

    SlicePriority(int value) {
        this.value = value;
    }

    public int value() {
        return value;
    }

    public static SlicePriority forType(SliceType type) {
        if (type == null) {
            throw new IllegalArgumentException(
                    "Le type de slice est obligatoire.");
        }

        return switch (type) {
            case URLLC -> URLLC;
            case EMBB -> EMBB;
        };
    }
}
EOF

# ------------------------------------------------------------
# SliceConfiguration.java
# ------------------------------------------------------------

write_file "${BASE}/models/SliceConfiguration.java" <<'EOF'
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
EOF

# ------------------------------------------------------------
# SliceStatus.java
# ------------------------------------------------------------

write_file "${BASE}/models/SliceStatus.java" <<'EOF'
package org.onap.policy.clamp.acm.participant.multislice.models;

/**
 * État applicatif d'une slice dans le laboratoire.
 *
 * Ces états ne remplacent pas les DeployState du framework ONAP.
 */
public enum SliceStatus {

    CREATED,
    VALIDATING,
    DEPLOYING,
    RUNNING,
    STOPPING,
    STOPPED,
    FAILED
}
EOF

# ------------------------------------------------------------
# Modèle déclaratif ac-urllc-embb.yaml
# ------------------------------------------------------------

write_file "${PROJECT_DIR}/ac-model/ac-urllc-embb.yaml" <<'EOF'
# Modèle déclaratif de laboratoire.
#
# Ce document décrit les profils et propriétés attendus.
# Il n'est pas, à lui seul, un modèle TOSCA complet importable
# par ONAP ACM : les types et métadonnées doivent être alignés
# sur la version de modèle de composition utilisée.

model:
  name: ac-urllc-embb
  version: 1.0.0
  description: >
    Profils applicatifs URLLC et eMBB pour un laboratoire
    d'orchestration multi-slice.

profiles:
  URLLC:
    priority: 100
    defaultResources:
      cpuMillicores: 1000
      memoryMiB: 1024
    description: >
      Profil destiné aux workloads sensibles à la latence.
      Aucune garantie de latence réseau n'est fournie par ce modèle.

  eMBB:
    priority: 50
    defaultResources:
      cpuMillicores: 500
      memoryMiB: 512
    description: >
      Profil destiné aux workloads orientés débit.
      Aucun débit radio ou réseau n'est réservé par ce modèle.

properties:
  sliceId:
    type: string
    required: true

  sliceType:
    type: string
    required: true
    allowedValues:
      - URLLC
      - eMBB

  namespace:
    type: string
    required: true
    default: network-slices

  deploymentName:
    type: string
    required: true

  replicas:
    type: integer
    required: true
    minimum: 0
    default: 1

  cpuMillicores:
    type: integer
    required: true
    minimum: 1

  memoryMiB:
    type: integer
    required: true
    minimum: 1

outputs:
  sliceStatus:
    type: string

  appliedReplicas:
    type: integer

  effectiveSliceType:
    type: string

  priority:
    type: integer
EOF

printf '\nPartie 2/8 terminée.\n'
printf 'Les modèles métier et le YAML ont été générés.\n'
printf 'Aucun service n’a été démarré.\n'
