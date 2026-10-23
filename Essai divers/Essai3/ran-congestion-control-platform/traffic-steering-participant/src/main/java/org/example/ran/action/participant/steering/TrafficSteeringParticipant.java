package org.example.ran.action.participant.steering;

import org.example.ran.action.participant.ActionParticipant;
import org.example.ran.action.service.ActionExecutionResult;
import org.onap.policy.ran.common.ActionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.Set;

/**
 * Participant spécialisé dans la simulation du traffic steering.
 *
 * Aucune connexion à un contrôleur RAN n'est effectuée.
 */
@Component
public class TrafficSteeringParticipant implements ActionParticipant {

    private static final Logger LOG =
            LoggerFactory.getLogger(TrafficSteeringParticipant.class);

    private static final Set<String> ALLOWED_MODES =
            Set.of("balanced", "emergency");

    private final Clock clock;

    public TrafficSteeringParticipant() {
        this(Clock.systemUTC());
    }

    TrafficSteeringParticipant(Clock clock) {
        this.clock = clock;
    }

    @Override
    public boolean supports(ActionEvent action) {
        return action != null
                && action.actionType()
                == ActionEvent.ActionType.TRAFFIC_STEERING;
    }

    @Override
    public ActionExecutionResult execute(ActionEvent action) {
        if (!supports(action)) {
            return reject(action, "Type TRAFFIC_STEERING requis");
        }

        if (action.actionId() == null || action.actionId().isBlank()) {
            return reject(action, "Identifiant d'action absent");
        }

        if (action.isTerminal()) {
            return reject(action, "Action déjà dans un état terminal");
        }

        Instant now = clock.instant();

        if (action.isExpired(now)) {
            return ActionExecutionResult.expired(action.actionId());
        }

        Map<String, String> parameters = action.parameters();

        if (parameters == null || parameters.isEmpty()) {
            return reject(action, "Paramètres de steering absents");
        }

        String mode = parameters.get("mode");
        String sourceCell = parameters.get("sourceCell");
        String preserveQos = parameters.get("preserveQos");
        String executionMode = parameters.get("executionMode");

        if (mode == null || !ALLOWED_MODES.contains(mode)) {
            return reject(action, "Mode de steering non autorisé");
        }

        if (action.cellId() == null
                || action.cellId().isBlank()
                || sourceCell == null
                || !sourceCell.equals(action.cellId())) {
            return reject(action, "Cellule source absente ou incohérente");
        }

        if (!"true".equalsIgnoreCase(preserveQos)) {
            return reject(action, "La préservation de la QoS est obligatoire");
        }

        /*
         * Ce participant ne réalise que des simulations.
         * Un mode PARTICIPANT ne doit jamais déclencher une
         * opération réseau depuis cette implémentation.
         */
        if (!"SIMULATION".equals(executionMode)) {
            return reject(
                    action,
                    "Exécution réelle non prise en charge par ce participant"
            );
        }

        LOG.info(
                "TRAFFIC STEERING SIMULÉ : actionId={}, node={}, cell={}, mode={}, preserveQos={}",
                action.actionId(),
                action.ranNodeId(),
                action.cellId(),
                mode,
                preserveQos
        );

        return ActionExecutionResult.success(
                action.actionId(),
                "Rééquilibrage simulé ; aucune modification réseau effectuée",
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
                "Traffic steering rejeté : actionId={}, raison={}",
                actionId,
                message
        );

        return ActionExecutionResult.rejected(actionId, message);
    }
}
