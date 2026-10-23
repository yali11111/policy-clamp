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
