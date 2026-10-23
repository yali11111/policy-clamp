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
