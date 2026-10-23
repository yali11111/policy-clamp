package com.clamp.acm.events;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.Instant;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;

/**
 * Decision publiee par le moteur de politiques.
 *
 * Une decision n'autorise pas automatiquement une operation
 * destructive : le controleur doit appliquer ses propres
 * validations, limites et controles de securite.
 */
public record PolicyDecisionEvent(
        String decisionId,
        String sourceEventId,
        String policyId,
        String target,
        Decision decision,
        String reason,
        Instant timestamp,
        Map<String, String> evidence) {

    public enum Decision {
        NO_ACTION,
        MANUAL_REVIEW,
        SCALE_OUT_REQUESTED,
        SCALE_IN_REQUESTED,
        TRAFFIC_STEERING_REQUESTED
    }

    @JsonCreator
    public PolicyDecisionEvent(
            @JsonProperty("decisionId") String decisionId,
            @JsonProperty("sourceEventId") String sourceEventId,
            @JsonProperty("policyId") String policyId,
            @JsonProperty("target") String target,
            @JsonProperty("decision") Decision decision,
            @JsonProperty("reason") String reason,
            @JsonProperty("timestamp") Instant timestamp,
            @JsonProperty("evidence") Map<String, String> evidence) {

        this.decisionId = requireText(decisionId, "decisionId");
        this.sourceEventId = requireText(
                sourceEventId, "sourceEventId");
        this.policyId = requireText(policyId, "policyId");
        this.target = requireText(target, "target");
        this.decision = Objects.requireNonNull(
                decision, "decision is required");
        this.reason = requireText(reason, "reason");
        this.timestamp = Objects.requireNonNull(
                timestamp, "timestamp is required");

        Map<String, String> copy = new LinkedHashMap<>();

        if (evidence != null) {
            evidence.forEach((key, value) -> {
                if (key == null || key.isBlank() || value == null) {
                    throw new IllegalArgumentException(
                            "Invalid evidence entry");
                }
                copy.put(key, value);
            });
        }

        this.evidence = Collections.unmodifiableMap(copy);
    }

    private static String requireText(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    name + " must not be blank");
        }
        return value;
    }
}
