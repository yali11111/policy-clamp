package org.example.ran.predictor.service;

import org.onap.policy.ran.common.CongestionEvent;
import org.onap.policy.ran.common.RanKpi;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.UUID;

@Service
public class CongestionPredictorService {

    private final double prbThreshold;
    private final double latencyThreshold;
    private final double packetLossThreshold;
    private final int horizonSeconds;

    public CongestionPredictorService(
            @Value("${ran.predictor.thresholds.prb-percent:80.0}")
            double prbThreshold,
            @Value("${ran.predictor.thresholds.latency-ms:50.0}")
            double latencyThreshold,
            @Value("${ran.predictor.thresholds.packet-loss-percent:1.0}")
            double packetLossThreshold,
            @Value("${ran.predictor.horizon-seconds:30}")
            int horizonSeconds) {

        if (!Double.isFinite(prbThreshold)
                || prbThreshold <= 0 || prbThreshold > 100) {
            throw new IllegalArgumentException("Invalid PRB threshold");
        }

        if (!Double.isFinite(latencyThreshold)
                || latencyThreshold <= 0) {
            throw new IllegalArgumentException("Invalid latency threshold");
        }

        if (!Double.isFinite(packetLossThreshold)
                || packetLossThreshold <= 0
                || packetLossThreshold > 100) {
            throw new IllegalArgumentException(
                    "Invalid packet loss threshold");
        }

        if (horizonSeconds < 0) {
            throw new IllegalArgumentException(
                    "Invalid prediction horizon");
        }

        this.prbThreshold = prbThreshold;
        this.latencyThreshold = latencyThreshold;
        this.packetLossThreshold = packetLossThreshold;
        this.horizonSeconds = horizonSeconds;
    }

    public CongestionEvent evaluate(RanKpi kpi) {
        validateKpi(kpi);

        double score = calculateScore(kpi);

        CongestionEvent.CongestionLevel level;

        if (score >= 0.85) {
            level = CongestionEvent.CongestionLevel.CRITICAL;
        } else if (score >= 0.65) {
            level = CongestionEvent.CongestionLevel.HIGH;
        } else if (score >= 0.40) {
            level = CongestionEvent.CongestionLevel.MEDIUM;
        } else if (score >= 0.20) {
            level = CongestionEvent.CongestionLevel.LOW;
        } else {
            level = CongestionEvent.CongestionLevel.NORMAL;
        }

        CongestionEvent.CongestionType type =
                level == CongestionEvent.CongestionLevel.HIGH
                || level == CongestionEvent.CongestionLevel.CRITICAL
                ? CongestionEvent.CongestionType.DETECTED
                : CongestionEvent.CongestionType.PREDICTED;

        String reason = String.format(
                "score=%.3f; PRB=%.2f%%; latency=%.2fms; loss=%.2f%%",
                score,
                kpi.prbUtilizationPercent(),
                kpi.latencyMs(),
                kpi.packetLossPercent()
        );

        return new CongestionEvent(
                UUID.randomUUID().toString(),
                kpi.eventId(),
                Instant.now(),
                kpi.ranNodeId(),
                kpi.cellId(),
                kpi.sliceId(),
                level,
                type,
                score,
                kpi.prbUtilizationPercent(),
                kpi.latencyMs(),
                kpi.packetLossPercent(),
                kpi.activeUsers(),
                horizonSeconds,
                reason
        );
    }

    public double calculateScore(RanKpi kpi) {
        validateKpi(kpi);

        double prb = normalize(
                kpi.prbUtilizationPercent(), prbThreshold);

        double latency = normalize(
                kpi.latencyMs(), latencyThreshold);

        double loss = normalize(
                kpi.packetLossPercent(), packetLossThreshold);

        return Math.max(0.0, Math.min(1.0,
                0.50 * prb
                + 0.30 * latency
                + 0.20 * loss));
    }

    private double normalize(double value, double threshold) {
        return Math.max(
                0.0,
                Math.min(1.0, value / (2.0 * threshold))
        );
    }

    private void validateKpi(RanKpi kpi) {
        if (kpi == null) {
            throw new IllegalArgumentException("KPI must not be null");
        }

        validateRange(
                kpi.prbUtilizationPercent(), 0, 100, "PRB");

        validateRange(
                kpi.latencyMs(), 0, Double.MAX_VALUE, "Latency");

        validateRange(
                kpi.packetLossPercent(), 0, 100, "Packet loss");

        if (kpi.activeUsers() < 0) {
            throw new IllegalArgumentException(
                    "Active users must be >= 0");
        }
    }

    private void validateRange(
            double value,
            double min,
            double max,
            String field) {

        if (!Double.isFinite(value) || value < min || value > max) {
            throw new IllegalArgumentException(
                    "Invalid KPI field: " + field);
        }
    }
}
