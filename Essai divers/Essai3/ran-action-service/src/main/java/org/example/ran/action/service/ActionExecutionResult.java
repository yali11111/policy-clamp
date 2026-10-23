package org.example.ran.action.service;

import java.time.Instant;
import java.util.Objects;

/**
 * Résultat de l'exécution ou du rejet d'une action.
 */
public record ActionExecutionResult(
        String actionId,
        String status,
        String message,
        Instant timestamp,
        boolean simulated
) {
    public ActionExecutionResult {
        if (actionId == null || actionId.isBlank()) {
            throw new IllegalArgumentException(
                    "actionId must not be blank");
        }

        if (status == null || status.isBlank()) {
            throw new IllegalArgumentException(
                    "status must not be blank");
        }

        message = Objects.requireNonNullElse(message, "");
        timestamp = Objects.requireNonNullElseGet(
                timestamp, Instant::now);
    }

    public static ActionExecutionResult success(
            String actionId,
            String message,
            boolean simulated) {

        return new ActionExecutionResult(
                actionId,
                "SUCCEEDED",
                message,
                Instant.now(),
                simulated
        );
    }

    public static ActionExecutionResult rejected(
            String actionId,
            String message) {

        return new ActionExecutionResult(
                actionId,
                "REJECTED",
                message,
                Instant.now(),
                true
        );
    }

    public static ActionExecutionResult expired(String actionId) {
        return new ActionExecutionResult(
                actionId,
                "EXPIRED",
                "Action expirée avant son exécution",
                Instant.now(),
                true
        );
    }
}
