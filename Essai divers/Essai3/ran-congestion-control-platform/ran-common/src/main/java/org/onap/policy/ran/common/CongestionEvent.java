package org.onap.policy.ran.common;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Événement décrivant une congestion détectée ou anticipée.
 *
 * confidence est comprise entre 0 et 1.
 * predictedHorizonSeconds indique l'horizon de prédiction.
 */
public record CongestionEvent(
        String eventId,
        String correlationId,
        Instant timestamp,
        String ranNodeId,
        String cellId,
        String sliceId,
        CongestionLevel level,
        CongestionType type,
        double confidence,
        double prbUtilizationPercent,
        double latencyMs,
        double packetLossPercent,
        int activeUsers,
        int predictedHorizonSeconds,
        String reason
) {

    public enum CongestionLevel {
        NORMAL,
        LOW,
        MEDIUM,
        HIGH,
        CRITICAL
    }

    public enum CongestionType {
        DETECTED,
        PREDICTED,
        CLEARED
    }

    public CongestionEvent {
        eventId = requireText(
                eventId == null ? UUID.randomUUID().toString() : eventId,
                "eventId");

        correlationId = requireText(
                correlationId == null
                        ? eventId
                        : correlationId,
                "correlationId");

        timestamp = Objects.requireNonNullElseGet(
                timestamp, Instant::now);

        ranNodeId = requireText(ranNodeId, "ranNodeId");
        cellId = requireText(cellId, "cellId");

        sliceId = sliceId == null || sliceId.isBlank()
                ? "default"
                : sliceId.trim();

        level = Objects.requireNonNull(level, "level");
        type = Objects.requireNonNull(type, "type");

        requireRange(confidence, 0, 1, "confidence");

        requireRange(
                prbUtilizationPercent, 0, 100,
                "prbUtilizationPercent");

        requireNonNegative(latencyMs, "latencyMs");

        requireRange(
                packetLossPercent, 0, 100,
                "packetLossPercent");

        if (activeUsers < 0) {
            throw new IllegalArgumentException(
                    "activeUsers must be >= 0");
        }

        if (predictedHorizonSeconds < 0) {
            throw new IllegalArgumentException(
                    "predictedHorizonSeconds must be >= 0");
        }

        reason = reason == null ? "" : reason.trim();
    }

    public boolean requiresControlAction() {
        return level == CongestionLevel.HIGH
                || level == CongestionLevel.CRITICAL;
    }

    public boolean isPrediction() {
        return type == CongestionType.PREDICTED;
    }

    private static String requireText(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    name + " must not be blank");
        }
        return value.trim();
    }

    private static void requireNonNegative(
            double value, String name) {

        if (!Double.isFinite(value) || value < 0) {
            throw new IllegalArgumentException(
                    name + " must be finite and >= 0");
        }
    }

    private static void requireRange(
            double value,
            double minimum,
            double maximum,
            String name) {

        if (!Double.isFinite(value)
                || value < minimum
                || value > maximum) {

            throw new IllegalArgumentException(
                    name + " must be between "
                            + minimum + " and " + maximum);
        }
    }
}
