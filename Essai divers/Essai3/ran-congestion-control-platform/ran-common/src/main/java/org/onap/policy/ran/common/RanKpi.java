package org.onap.policy.ran.common;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * KPI radio observé sur une cellule RAN.
 *
 * Les valeurs sont normalisées afin de faciliter leur traitement
 * par les services de prédiction et de contrôle.
 *
 * Les pourcentages sont exprimés entre 0 et 100.
 * Le débit est exprimé en Mbps, la latence en millisecondes.
 */
public record RanKpi(
        String eventId,
        Instant timestamp,
        String source,
        String plmnId,
        String ranNodeId,
        String cellId,
        String sliceId,
        double prbUtilizationPercent,
        double downlinkThroughputMbps,
        double uplinkThroughputMbps,
        double latencyMs,
        double packetLossPercent,
        int activeUsers,
        double signalQualityDb,
        boolean synthetic
) {

    public RanKpi {
        eventId = requireText(
                eventId == null ? UUID.randomUUID().toString() : eventId,
                "eventId");

        timestamp = Objects.requireNonNullElseGet(
                timestamp, Instant::now);

        source = requireText(source, "source");
        plmnId = requireText(plmnId, "plmnId");
        ranNodeId = requireText(ranNodeId, "ranNodeId");
        cellId = requireText(cellId, "cellId");
        sliceId = normalizeOptional(sliceId);

        requireRange(
                prbUtilizationPercent, 0, 100,
                "prbUtilizationPercent");

        requireNonNegative(
                downlinkThroughputMbps, "downlinkThroughputMbps");

        requireNonNegative(
                uplinkThroughputMbps, "uplinkThroughputMbps");

        requireNonNegative(latencyMs, "latencyMs");

        requireRange(
                packetLossPercent, 0, 100,
                "packetLossPercent");

        if (activeUsers < 0) {
            throw new IllegalArgumentException(
                    "activeUsers must be >= 0");
        }

        if (!Double.isFinite(signalQualityDb)) {
            throw new IllegalArgumentException(
                    "signalQualityDb must be finite");
        }
    }

    public static RanKpi create(
            String ranNodeId,
            String cellId,
            double prbUtilizationPercent,
            double downlinkThroughputMbps,
            double uplinkThroughputMbps,
            double latencyMs,
            double packetLossPercent,
            int activeUsers) {

        return new RanKpi(
                UUID.randomUUID().toString(),
                Instant.now(),
                "ran-kpi-service",
                "00101",
                ranNodeId,
                cellId,
                "default",
                prbUtilizationPercent,
                downlinkThroughputMbps,
                uplinkThroughputMbps,
                latencyMs,
                packetLossPercent,
                activeUsers,
                0.0,
                true
        );
    }

    public boolean indicatesHighRadioLoad() {
        return prbUtilizationPercent >= 80.0;
    }

    private static String requireText(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    name + " must not be blank");
        }
        return value.trim();
    }

    private static String normalizeOptional(String value) {
        return value == null || value.isBlank()
                ? "default"
                : value.trim();
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
