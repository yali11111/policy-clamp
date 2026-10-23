package org.example.ran.action.participant.scaling;

import org.example.ran.action.participant.ActionParticipant;
import org.example.ran.action.service.ActionExecutionResult;
import org.onap.policy.ran.common.ActionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.Objects;

@Component
public class ScalingParticipant implements ActionParticipant {

    private static final Logger LOG =
            LoggerFactory.getLogger(ScalingParticipant.class);

    private final ScalingPolicy policy;
    private final boolean simulationMode;
    private final Clock clock;

    public ScalingParticipant(
            ScalingPolicy policy,
            @Value("${ran.scaling.simulation-mode:true}")
            boolean simulationMode) {

        this(policy, simulationMode, Clock.systemUTC());
    }

    ScalingParticipant(
            ScalingPolicy policy,
            boolean simulationMode,
            Clock clock) {

        this.policy = Objects.requireNonNull(policy, "policy");
        this.simulationMode = simulationMode;
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    @Override
    public boolean supports(ActionEvent action) {
        return action != null
                && (action.actionType()
                    == ActionEvent.ActionType.SCALE_OUT
                    || action.actionType()
                    == ActionEvent.ActionType.SCALE_IN);
    }

    @Override
    public ActionExecutionResult execute(ActionEvent action) {
        if (!supports(action)) {
            return reject(action, "Type SCALE_OUT ou SCALE_IN requis");
        }

        if (action.actionId() == null || action.actionId().isBlank()) {
            return reject(action, "Identifiant d'action absent");
        }

        if (action.isTerminal()) {
            return reject(action, "Action déjà terminale");
        }

        Instant now = clock.instant();

        if (action.isExpired(now)) {
            return ActionExecutionResult.expired(action.actionId());
        }

        if (!simulationMode) {
            return reject(
                    action,
                    "Exécution réelle indisponible : aucun adaptateur configuré"
            );
        }

        Map<String, String> parameters = action.parameters();

        if (parameters == null || parameters.isEmpty()) {
            return reject(action, "Paramètres de scaling absents");
        }

        if (!"SIMULATION".equals(parameters.get("executionMode"))) {
            return reject(action, "Le mode SIMULATION est obligatoire");
        }

        String component = parameters.get("component");

        if (component == null || component.isBlank()) {
            return reject(action, "Composant cible absent");
        }

        String expectedDirection =
                action.actionType() == ActionEvent.ActionType.SCALE_OUT
                        ? "out"
                        : "in";

        if (!expectedDirection.equals(parameters.get("direction"))) {
            return reject(action, "Direction incompatible avec l'action");
        }

        final int requestedReplicas;

        try {
            requestedReplicas = Integer.parseInt(
                    parameters.getOrDefault("requestedReplicas", "")
            );
        } catch (NumberFormatException exception) {
            return reject(action, "requestedReplicas doit être un entier");
        }

        if (!policy.isValidTarget(requestedReplicas)) {
            return reject(
                    action,
                    "Nombre de réplicas hors des limites configurées"
            );
        }

        LOG.info(
                "SCALING SIMULÉ : actionId={}, component={}, direction={}, targetReplicas={}",
                action.actionId(),
                component,
                expectedDirection,
                requestedReplicas
        );

        return ActionExecutionResult.success(
                action.actionId(),
                "Mise à l'échelle simulée vers "
                        + requestedReplicas
                        + " réplicas pour "
                        + component
                        + " ; aucune modification réelle effectuée",
                true
        );
    }

    private ActionExecutionResult reject(
            ActionEvent action,
            String message) {

        String actionId = action == null
                || action.actionId() == null
                || action.actionId().isBlank()
                ? "unknown"
                : action.actionId();

        LOG.warn(
                "Scaling rejeté : actionId={}, raison={}",
                actionId,
                message
        );

        return ActionExecutionResult.rejected(actionId, message);
    }
}
