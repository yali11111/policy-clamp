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
