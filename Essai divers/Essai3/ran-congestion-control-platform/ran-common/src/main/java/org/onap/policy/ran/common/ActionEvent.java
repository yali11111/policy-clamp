package org.onap.policy.ran.common;

import java.time.Instant;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * Commande de contrôle produite par le moteur de politique.
 *
 * Les participants peuvent simuler ces actions ou les transmettre
 * à une intégration réseau explicitement configurée.
 */
public record ActionEvent(
        String actionId,
        String correlationId,
        String congestionEventId,
        Instant timestamp,
        String ranNodeId,
        String cellId,
        String sliceId,
        ActionType actionType,
        ActionStatus status,
        ActionTarget target,
        Map<String, String> parameters,
        String reason,
        String requestedBy,
        Instant expiresAt
) {

    public enum ActionType {
        TRAFFIC_STEERING,
        SCALE_OUT,
        SCALE_IN,
        NETWORK_CONFIGURATION,
        NO_OP
    }

    public enum ActionStatus {
        REQUESTED,
        ACCEPTED,
        REJECTED,
        EXECUTING,
        SUCCEEDED,
        FAILED,
        EXPIRED,
        ROLLED_BACK
    }

    public enum ActionTarget {
        TRAFFIC_STEERING_PARTICIPANT,
        SCALING_PARTICIPANT,
        NETWORK_CONFIG_PARTICIPANT,
        SIMULATOR
    }

    public ActionEvent {
        actionId = requireText(
                actionId == null ? UUID.randomUUID().toString() : actionId,
                "actionId");

        correlationId = requireText(
                correlationId == null ? actionId : correlationId,
                "correlationId");

        congestionEventId = congestionEventId == null
                ? ""
                : congestionEventId.trim();

        timestamp = Objects.requireNonNullElseGet(
                timestamp, Instant::now);

        ranNodeId = requireText(ranNodeId, "ranNodeId");
        cellId = requireText(cellId, "cellId");

        sliceId = sliceId == null || sliceId.isBlank()
                ? "default"
                : sliceId.trim();

        actionType = Objects.requireNonNull(
                actionType, "actionType");

        status = Objects.requireNonNull(status, "status");

        target = Objects.requireNonNull(target, "target");

        parameters = parameters == null
                ? Map.of()
                : Map.copyOf(parameters);

        reason = reason == null ? "" : reason.trim();

        requestedBy = requestedBy == null || requestedBy.isBlank()
                ? "ran-control-service"
                : requestedBy.trim();

        if (expiresAt != null && expiresAt.isBefore(timestamp)) {
            throw new IllegalArgumentException(
                    "expiresAt must not be before timestamp");
        }
    }

    public boolean isTerminal() {
        return switch (status) {
            case REJECTED, SUCCEEDED, FAILED, EXPIRED, ROLLED_BACK -> true;
            default -> false;
        };
    }

    public boolean isExpired(Instant now) {
        return expiresAt != null && !now.isBefore(expiresAt);
    }

    public ActionEvent withStatus(ActionStatus newStatus) {
        return new ActionEvent(
                actionId,
                correlationId,
                congestionEventId,
                timestamp,
                ranNodeId,
                cellId,
                sliceId,
                actionType,
                newStatus,
                target,
                parameters,
                reason,
                requestedBy,
                expiresAt
        );
    }

    public static ActionEvent noOp(
            String ranNodeId,
            String cellId,
            String reason) {

        Instant now = Instant.now();

        return new ActionEvent(
                UUID.randomUUID().toString(),
                UUID.randomUUID().toString(),
                "",
                now,
                ranNodeId,
                cellId,
                "default",
                ActionType.NO_OP,
                ActionStatus.REQUESTED,
                ActionTarget.SIMULATOR,
                Map.of(),
                reason,
                "ran-control-service",
                null
        );
    }

    private static String requireText(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    name + " must not be blank");
        }
        return value.trim();
    }
}
