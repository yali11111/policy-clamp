package org.example.ran.scaling.participant;

import org.example.ran.action.participant.ActionParticipant;
import org.example.ran.action.service.ActionExecutionResult;
import org.onap.policy.ran.common.ActionEvent;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Set;

/**
 * Participant de mise à l'échelle simulée.
 *
 * Aucune API Kubernetes ou infrastructure réelle n'est appelée.
 */
@Component
public class ScalingParticipant implements ActionParticipant {

    private static final Set<ActionEvent.ActionType> SUPPORTED =
            Set.of(
                    ActionEvent.ActionType.SCALE_OUT,
                    ActionEvent.ActionType.SCALE_IN
            );

    private final boolean simulationMode;
    private final int minReplicas;
    private final int maxReplicas;

    public ScalingParticipant(
            @Value("${ran.scaling.simulation-mode:true}")
            boolean simulationMode,
            @Value("${ran.scaling.min-replicas:1}")
            int minReplicas,
            @Value("${ran.scaling.max-replicas:10}")
            int maxReplicas) {

        if (minReplicas < 1 || maxReplicas < minReplicas) {
            throw new IllegalArgumentException(
                    "Invalid scaling replica limits");
        }

        this.simulationMode = simulationMode;
        this.minReplicas = minReplicas;
        this.maxReplicas = maxReplicas;
    }

    @Override
    public boolean supports(ActionEvent action) {
        return action != null
                && SUPPORTED.contains(action.actionType());
    }

    @Override
    public ActionExecutionResult execute(ActionEvent action) {
        if (!supports(action)) {
            return ActionExecutionResult.rejected(
                    action == null ? "unknown" : action.actionId(),
                    "Type d'action incompatible avec ScalingParticipant"
            );
        }

        if (!simulationMode) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "Exécution réelle indisponible : aucun adaptateur de scaling configuré"
            );
        }

        Map<String, String> parameters = action.parameters();

        String direction = action.actionType()
                == ActionEvent.ActionType.SCALE_OUT ? "out" : "in";

        String configuredDirection = parameters.get("direction");

        if (configuredDirection != null
                && !configuredDirection.equalsIgnoreCase(direction)) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "La direction demandée ne correspond pas au type d'action"
            );
        }

        int requestedReplicas;

        try {
            requestedReplicas = Integer.parseInt(
                    parameters.getOrDefault("requestedReplicas", "1")
            );
        } catch (NumberFormatException exception) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "requestedReplicas doit être un entier"
            );
        }

        if (requestedReplicas < minReplicas
                || requestedReplicas > maxReplicas) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "Nombre de réplicas hors des limites autorisées"
            );
        }

        String component = parameters.getOrDefault(
                "component", "ran-capacity");

        if (component.isBlank()) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "Le composant cible ne peut pas être vide"
            );
        }

        return ActionExecutionResult.success(
                action.actionId(),
                "Mise à l'échelle simulée : direction="
                        + direction
                        + ", component="
                        + component
                        + ", requestedReplicas="
                        + requestedReplicas
                        + ", limites=["
                        + minReplicas
                        + ","
                        + maxReplicas
                        + "] ; aucune infrastructure modifiée",
                true
        );
    }
}
