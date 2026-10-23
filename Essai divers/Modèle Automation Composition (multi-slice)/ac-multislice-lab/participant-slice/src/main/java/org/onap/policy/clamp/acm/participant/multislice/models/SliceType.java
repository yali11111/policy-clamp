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
