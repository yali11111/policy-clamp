package org.example.ran.action;

import org.example.ran.action.participant.ActionParticipant;
import org.onap.policy.ran.common.ActionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Valide et distribue les commandes aux participants.
 *
 * Le registre d'idempotence est en mémoire. Il convient à une
 * démonstration mono-instance, mais doit être remplacé par un
 * stockage durable pour un environnement de production.
 */
@Service
public class ActionExecutionService {

    private static final Logger LOG =
            LoggerFactory.getLogger(ActionExecutionService.class);

    private final List<ActionParticipant> participants;
    private final boolean simulationMode;
    private final Clock clock;

    private final Set<String> processedActionIds =
            ConcurrentHashMap.newKeySet();

    public ActionExecutionService(
            List<ActionParticipant> participants,
            @Value("${ran.action.simulation-mode:true}")
            boolean simulationMode) {

        this(participants, simulationMode, Clock.systemUTC());
    }

    ActionExecutionService(
            List<ActionParticipant> participants,
            boolean simulationMode,
            Clock clock) {

        this.participants = List.copyOf(
                Objects.requireNonNull(participants, "participants"));

        this.simulationMode = simulationMode;
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    public ActionExecutionResult execute(ActionEvent action) {
        if (action == null) {
            throw new IllegalArgumentException(
                    "Action must not be null");
        }

        Instant now = clock.instant();

        if (action.actionId().isBlank()) {
            return ActionExecutionResult.rejected(
                    "unknown",
                    "Identifiant d'action absent"
            );
        }

        if (action.isTerminal()) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "L'action possède déjà un statut terminal"
            );
        }

        if (action.isExpired(now)) {
            return ActionExecutionResult.expired(action.actionId());
        }

        if (!processedActionIds.add(action.actionId())) {
            LOG.warn(
                    "Duplicate action ignored: actionId={}",
                    action.actionId()
            );

            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "Action déjà traitée par cette instance"
            );
        }

        if (action.actionType() == ActionEvent.ActionType.NO_OP) {
            return ActionExecutionResult.success(
                    action.actionId(),
                    "Aucune action opérationnelle requise",
                    true
            );
        }

        /*
         * Aucune intégration réelle n'est fournie dans cette partie.
         * Le mode simulation est obligatoire tant qu'un adaptateur
         * réseau contrôlé n'a pas été explicitement développé.
         */
        if (!simulationMode) {
            LOG.error(
                    "Real execution requested but no production adapter is configured: actionId={}",
                    action.actionId()
            );

            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "Exécution réelle indisponible : aucun adaptateur de production configuré"
            );
        }

        for (ActionParticipant participant : participants) {
            if (participant.supports(action)) {
                try {
                    return participant.execute(action);
                } catch (RuntimeException exception) {
                    LOG.error(
                            "Participant failed: actionId={}",
                            action.actionId(),
                            exception
                    );

                    return new ActionExecutionResult(
                            action.actionId(),
                            "FAILED",
                            "Échec du participant : "
                                    + exception.getClass().getSimpleName(),
                            clock.instant(),
                            true
                    );
                }
            }
        }

        LOG.warn(
                "No participant supports action type {}",
                action.actionType()
        );

        return ActionExecutionResult.rejected(
                action.actionId(),
                "Aucun participant compatible avec ce type d'action"
        );
    }
}
