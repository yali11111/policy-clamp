package com.clamp.acm.policy;

import com.clamp.acm.events.MetricsEvent;
import com.clamp.acm.events.PolicyDecisionEvent;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Component
public class PolicyStreamProcessor {

    private final double cpuThreshold;
    private final double latencyThresholdMs;

    public PolicyStreamProcessor(
            @Value("${acm.policy.cpu-threshold:80.0}")
            double cpuThreshold,
            @Value("${acm.policy.latency-threshold-ms:100.0}")
            double latencyThresholdMs) {

        if (cpuThreshold < 0 || cpuThreshold > 100) {
            throw new IllegalArgumentException(
                    "CPU threshold must be between 0 and 100");
        }

        if (latencyThresholdMs < 0) {
            throw new IllegalArgumentException(
                    "Latency threshold must not be negative");
        }

        this.cpuThreshold = cpuThreshold;
        this.latencyThresholdMs = latencyThresholdMs;
    }

    public PolicyDecisionEvent evaluate(MetricsEvent event) {
        if (event == null) {
            return null;
        }

        double cpu = event.metrics()
                .getOrDefault("cpuUtilizationPct", 0.0);

        double latency = event.metrics()
                .getOrDefault("latencyMs", 0.0);

        PolicyDecisionEvent.Decision decision;
        String policyId;
        String reason;

        if (cpu >= cpuThreshold) {
            decision =
                    PolicyDecisionEvent.Decision.MANUAL_REVIEW;
            policyId = "high-cpu-review";
            reason =
                    "CPU threshold exceeded; manual review required";
        } else if (latency >= latencyThresholdMs) {
            decision =
                    PolicyDecisionEvent.Decision.MANUAL_REVIEW;
            policyId = "high-latency-review";
            reason =
                    "Latency threshold exceeded; manual review required";
        } else {
            decision = PolicyDecisionEvent.Decision.NO_ACTION;
            policyId = "default-observation";
            reason =
                    "Metrics are within configured thresholds";
        }

        return new PolicyDecisionEvent(
                UUID.randomUUID().toString(),
                event.eventId(),
                policyId,
                event.target(),
                decision,
                reason,
                Instant.now(),
                Map.of(
                        "cpuUtilizationPct", Double.toString(cpu),
                        "latencyMs", Double.toString(latency)
                )
        );
    }
}
