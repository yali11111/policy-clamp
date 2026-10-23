package org.example.ran.control.policy;

import org.onap.policy.ran.common.ActionEvent;
import org.onap.policy.ran.common.CongestionEvent;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class ControlLoopEngine {

    private final boolean simulationMode;
    private final double steeringThreshold;
    private final double scaleOutThreshold;
    private final double criticalThreshold;
    private final Duration cooldown;
    private final Duration actionTtl;
    private final Clock clock;

    private final Map<String, Instant> lastActionByCell =
            new ConcurrentHashMap<>();

    public ControlLoopEngine(
            @Value("${ran.control.simulation-mode:true}")
            boolean simulationMode,
            @Value("${ran.control.thresholds.steering-prb:75.0}")
            double steeringThreshold,
            @Value("${ran.control.thresholds.scale-out-prb:90.0}")
            double scaleOutThreshold,
            @Value("${ran.control.thresholds.critical-prb:97.0}")
            double criticalThreshold,
            @Value("${ran.control.cooldown-seconds:30}")
            long cooldownSeconds,
            @Value("${ran.control.action-ttl-seconds:60}")
            long actionTtlSeconds) {

        this(
                simulationMode,
                steeringThreshold,
                scaleOutThreshold,
                criticalThreshold,
                cooldownSeconds,
                actionTtlSeconds,
                Clock.systemUTC()
        );
    }

    ControlLoopEngine(
            boolean simulationMode,
            double steeringThreshold,
            double scaleOutThreshold,
            double criticalThreshold,
            long cooldownSeconds,
            long actionTtlSeconds,
            Clock clock) {

        if (!Double.isFinite(steeringThreshold)
                || steeringThreshold < 0
                || steeringThreshold > 100) {
            throw new IllegalArgumentException(
                    "steeringThreshold must be between 0 and 100");
        }

        if (!Double.isFinite(scaleOutThreshold)
                || scaleOutThreshold < steeringThreshold
                || scaleOutThreshold > 100) {
            throw new IllegalArgumentException(
                    "scaleOutThreshold must be >= steeringThreshold and <= 100");
        }

        if (!Double.isFinite(criticalThreshold)
                || criticalThreshold < scaleOutThreshold
                || criticalThreshold > 100) {
            throw new IllegalArgumentException(
                    "criticalThreshold must be >= scaleOutThreshold and <= 100");
        }

        if (cooldownSeconds < 0 || actionTtlSeconds <= 0) {
            throw new IllegalArgumentException(
                    "Invalid cooldown or action TTL");
        }

        this.simulationMode = simulationMode;
        this.steeringThreshold = steeringThreshold;
        this.scaleOutThreshold = scaleOutThreshold;
        this.criticalThreshold = criticalThreshold;
        this.cooldown = Duration.ofSeconds(cooldownSeconds);
        this.actionTtl = Duration.ofSeconds(actionTtlSeconds);
        this.clock = clock;
    }

    public ActionEvent evaluate(CongestionEvent event) {
        if (event == null) {
            throw new IllegalArgumentException(
                    "Congestion event must not be null");
        }

        Instant now = clock.instant();

        String cellKey = event.ranNodeId() + "/" + event.cellId();

        if (event.level() == CongestionEvent.CongestionLevel.NORMAL
                || event.type() == CongestionEvent.CongestionType.CLEARED) {
            return noOp(event, now, "Congestion absente ou résolue");
        }

        if (event.level() == CongestionEvent.CongestionLevel.LOW
                || event.level() == CongestionEvent.CongestionLevel.MEDIUM) {
            return noOp(event, now, "Niveau de congestion insuffisant");
        }

        if (!Double.isFinite(event.confidence())
                || event.confidence() < 0.50
                || event.confidence() > 1.0) {
            return noOp(event, now, "Confiance insuffisante ou invalide");
        }

        Instant lastAction = lastActionByCell.get(cellKey);

        if (lastAction != null
                && now.isBefore(lastAction.plus(cooldown))) {
            return noOp(event, now, "Période de cooldown active");
        }

        ActionEvent action = selectAction(event, now);

        if (action.actionType() != ActionEvent.ActionType.NO_OP) {
            lastActionByCell.put(cellKey, now);
        }

        return action;
    }

    private ActionEvent selectAction(
            CongestionEvent event,
            Instant now) {

        double prb = event.prbUtilizationPercent();

        ActionEvent.ActionType actionType;
        ActionEvent.ActionTarget target;
        Map<String, String> parameters;
        String reason;

        if (event.level() == CongestionEvent.CongestionLevel.CRITICAL
                || prb >= criticalThreshold) {

            actionType = ActionEvent.ActionType.TRAFFIC_STEERING;
            target = ActionEvent.ActionTarget.TRAFFIC_STEERING_PARTICIPANT;

            parameters = Map.of(
                    "mode", "emergency",
                    "sourceCell", event.cellId(),
                    "preserveQos", "true"
            );

            reason = "Congestion critique : délestage prioritaire";

        } else if (prb >= scaleOutThreshold) {

            actionType = ActionEvent.ActionType.SCALE_OUT;
            target = ActionEvent.ActionTarget.SCALING_PARTICIPANT;

            parameters = Map.of(
                    "component", "ran-capacity",
                    "direction", "out",
                    "requestedReplicas", "1"
            );

            reason = "Utilisation PRB élevée : demande de capacité";

        } else if (prb >= steeringThreshold) {

            actionType = ActionEvent.ActionType.TRAFFIC_STEERING;
            target = ActionEvent.ActionTarget.TRAFFIC_STEERING_PARTICIPANT;

            parameters = Map.of(
                    "mode", "balanced",
                    "sourceCell", event.cellId(),
                    "preserveQos", "true"
            );

            reason = "Charge radio élevée : rééquilibrage du trafic";

        } else {
            actionType = ActionEvent.ActionType.NO_OP;
            target = ActionEvent.ActionTarget.SIMULATOR;
            parameters = Map.of();
            reason = "Seuil PRB insuffisant pour une action";
        }

        java.util.Map<String, String> enriched =
                new java.util.HashMap<>(parameters);

        enriched.put(
                "executionMode",
                simulationMode ? "SIMULATION" : "PARTICIPANT"
        );

        return new ActionEvent(
                null,
                event.correlationId(),
                event.eventId(),
                now,
                event.ranNodeId(),
                event.cellId(),
                event.sliceId(),
                actionType,
                ActionEvent.ActionStatus.REQUESTED,
                target,
                Map.copyOf(enriched),
                reason,
                "ran-control-service",
                now.plus(actionTtl)
        );
    }

    private ActionEvent noOp(
            CongestionEvent event,
            Instant now,
            String reason) {

        return new ActionEvent(
                null,
                event.correlationId(),
                event.eventId(),
                now,
                event.ranNodeId(),
                event.cellId(),
                event.sliceId(),
                ActionEvent.ActionType.NO_OP,
                ActionEvent.ActionStatus.REQUESTED,
                ActionEvent.ActionTarget.SIMULATOR,
                Map.of("executionMode", "SIMULATION"),
                reason,
                "ran-control-service",
                now.plus(actionTtl)
        );
    }
}
