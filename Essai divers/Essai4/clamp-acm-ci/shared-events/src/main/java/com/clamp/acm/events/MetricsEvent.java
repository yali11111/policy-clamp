package com.clamp.acm.events;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.Instant;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;

/**
 * Evenement de metriques publie par le service de monitoring.
 *
 * Les valeurs sont numeriques et exprimees dans les unites
 * definies par le contrat EventSchemas.md.
 */
public record MetricsEvent(
        String eventId,
        String source,
        String target,
        Instant timestamp,
        Map<String, Double> metrics,
        Map<String, String> attributes) {

    @JsonCreator
    public MetricsEvent(
            @JsonProperty("eventId") String eventId,
            @JsonProperty("source") String source,
            @JsonProperty("target") String target,
            @JsonProperty("timestamp") Instant timestamp,
            @JsonProperty("metrics") Map<String, Double> metrics,
            @JsonProperty("attributes") Map<String, String> attributes) {

        this.eventId = requireText(eventId, "eventId");
        this.source = requireText(source, "source");
        this.target = requireText(target, "target");
        this.timestamp = Objects.requireNonNull(
                timestamp, "timestamp is required");

        this.metrics = immutableMetrics(metrics);
        this.attributes = immutableAttributes(attributes);
    }

    private static String requireText(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    name + " must not be blank");
        }
        return value;
    }

    private static Map<String, Double> immutableMetrics(
            Map<String, Double> input) {

        Map<String, Double> copy = new LinkedHashMap<>();

        if (input != null) {
            input.forEach((key, value) -> {
                if (key == null || key.isBlank()) {
                    throw new IllegalArgumentException(
                            "Metric name must not be blank");
                }
                if (value == null || !Double.isFinite(value)) {
                    throw new IllegalArgumentException(
                            "Metric value must be finite: " + key);
                }
                copy.put(key, value);
            });
        }

        return Collections.unmodifiableMap(copy);
    }

    private static Map<String, String> immutableAttributes(
            Map<String, String> input) {

        Map<String, String> copy = new LinkedHashMap<>();

        if (input != null) {
            input.forEach((key, value) -> {
                if (key == null || key.isBlank() || value == null) {
                    throw new IllegalArgumentException(
                            "Invalid attribute");
                }
                copy.put(key, value);
            });
        }

        return Collections.unmodifiableMap(copy);
    }
}
