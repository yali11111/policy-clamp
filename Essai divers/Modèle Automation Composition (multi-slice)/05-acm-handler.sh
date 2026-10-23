
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
# SliceElementHandler.java
# ------------------------------------------------------------

write_file "${BASE}/handler/SliceElementHandler.java" <<'EOF'
package org.onap.policy.clamp.acm.participant.multislice.handler;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import org.onap.policy.clamp.acm.participant.multislice.models.SliceConfiguration;
import org.onap.policy.clamp.acm.participant.multislice.models.SliceStatus;
import org.onap.policy.clamp.acm.participant.multislice.models.SliceType;
import org.onap.policy.clamp.acm.participant.multislice.service.SliceService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Adaptateur de cycle de vie pour le participant multi-slice.
 *
 * Cette classe sépare la conversion des propriétés et la logique métier.
 * Elle ne dépend pas directement des DTO internes ONAP : une classe
 * d'intégration propre à la version ACM devra déléguer à ces méthodes.
 */
@Component
public class SliceElementHandler {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(SliceElementHandler.class);

    private final SliceService sliceService;
    private final ObjectMapper objectMapper;

    public SliceElementHandler(
            SliceService sliceService,
            ObjectMapper objectMapper) {
        this.sliceService = sliceService;
        this.objectMapper = objectMapper;
    }

    /**
     * Enregistre et valide la configuration d'une slice.
     *
     * @param inputProperties propriétés d'entrée de l'élément
     * @return état applicatif obtenu
     */
    public SliceStatus prepare(Map<String, Object> inputProperties) {
        SliceConfiguration configuration = convert(inputProperties);

        SliceStatus status = sliceService.register(configuration);

        LOGGER.info(
                "Configuration de slice préparée : id={}, type={}",
                configuration.getSliceId(),
                configuration.getSliceType().externalName());

        return status;
    }

    /**
     * Déploie une slice déjà enregistrée.
     *
     * @param sliceId identifiant métier de la slice
     * @return état obtenu
     */
    public SliceStatus deploy(String sliceId) {
        LOGGER.info("Demande de déploiement : {}", sliceId);
        return sliceService.deploy(sliceId);
    }

    /**
     * Retire une slice déjà enregistrée.
     *
     * @param sliceId identifiant métier de la slice
     * @return état obtenu
     */
    public SliceStatus undeploy(String sliceId) {
        LOGGER.info("Demande de retrait : {}", sliceId);
        return sliceService.undeploy(sliceId);
    }

    /**
     * Retourne l'état applicatif courant.
     */
    public SliceStatus status(String sliceId) {
        return sliceService.getStatus(sliceId);
    }

    /**
     * Convertit une map de propriétés en configuration métier.
     */
    public SliceConfiguration convert(Map<String, Object> properties) {
        if (properties == null || properties.isEmpty()) {
            throw new IllegalArgumentException(
                    "Les propriétés d'entrée sont obligatoires.");
        }

        Object source = properties.containsKey("slice")
                ? properties.get("slice")
                : properties;

        final SliceConfiguration configuration;

        try {
            configuration = objectMapper.convertValue(
                    source,
                    SliceConfiguration.class);
        } catch (IllegalArgumentException exception) {
            throw new IllegalArgumentException(
                    "Impossible de convertir les propriétés de slice.",
                    exception);
        }

        // Accepte également une valeur de type string pour sliceType.
        Object rawType = asMap(source).get("sliceType");

        if (rawType != null) {
            if (rawType instanceof SliceType type) {
                configuration.setSliceType(type);
            } else {
                configuration.setSliceType(
                        SliceType.from(rawType.toString()));
            }
        }

        configuration.validate();

        return configuration;
    }

    private Map<?, ?> asMap(Object source) {
        if (source instanceof Map<?, ?> map) {
            return map;
        }

        return objectMapper.convertValue(source, Map.class);
    }
}
EOF

# ------------------------------------------------------------
# SliceElementHandlerIntegrationNotes.md
# ------------------------------------------------------------

write_file "${PROJECT_DIR}/docs/acm-handler-integration.md" <<'EOF'
# Intégration du gestionnaire ACM

`SliceElementHandler` est un adaptateur métier autonome.

Il expose :
- `prepare(Map<String, Object>)`
- `deploy(String)`
- `undeploy(String)`
- `status(String)`

Pour le raccorder à un participant ONAP ACM réel :

1. Étendre la classe de base appropriée à la version ONAP utilisée.
2. Adapter les signatures de `deploy` et `undeploy` aux DTO ACM.
3. Extraire la configuration depuis `InstanceElementDto.inProperties()`.
4. Convertir les exceptions métier en résultats d'état ACM.
5. Appeler `ParticipantIntermediaryApi` pour publier les changements d'état.
6. Ajouter les tests avec les véritables dépendances du participant.

Ne pas déclarer l'élément comme compatible avec le runtime avant d'avoir
validé cette intégration et le modèle de composition TOSCA correspondant.
EOF

printf '\nPartie 5/8 terminée.\n'
printf 'Gestionnaire métier et notes d’intégration ACM générés.\n'
printf 'Aucun service externe n’a été démarré.\n'
