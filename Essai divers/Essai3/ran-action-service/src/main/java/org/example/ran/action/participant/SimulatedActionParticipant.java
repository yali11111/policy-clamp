package org.example.ran.action.participant;

import org.example.ran.action.service.ActionExecutionResult;
import org.onap.policy.ran.common.ActionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.Set;

/**
 * Participant de démonstration.
 *
 * Il journalise la commande sans contacter un réseau réel,
 * Kubernetes, un contrôleur O-RAN ou un équipement RAN.
 */
@Component
@ConditionalOnProperty(
        name = "ran.action.simulation-mode",
        havingValue = "true",
        matchIfMissing = true
)
public class SimulatedActionParticipant implements ActionParticipant {

    private static final Logger LOG =
            LoggerFactory.getLogger(SimulatedActionParticipant.class);

    private static final Set<ActionEvent.ActionType> SUPPORTED =
            Set.of(
                    ActionEvent.ActionType.TRAFFIC_STEERING,
                    ActionEvent.ActionType.SCALE_OUT,
                    ActionEvent.ActionType.SCALE_IN,
                    ActionEvent.ActionType.NETWORK_CONFIGURATION,
                    ActionEvent.ActionType.NO_OP
            );

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
                    "Type d'action non pris en charge"
            );
        }

        if (action.actionType() == ActionEvent.ActionType.NO_OP) {
            LOG.info(
                    "Simulation NO_OP: actionId={}, cell={}, reason={}",
                    action.actionId(),
                    action.cellId(),
                    action.reason()
            );

            return ActionExecutionResult.success(
                    action.actionId(),
                    "Aucune modification réseau demandée",
                    true
            );
        }

        LOG.info(
                "SIMULATION ONLY: actionId={}, type={}, node={}, cell={}, parameters={}",
                action.actionId(),
                action.actionType(),
                action.ranNodeId(),
                action.cellId(),
                action.parameters()
        );

        return ActionExecutionResult.success(
                action.actionId(),
                "Action simulée ; aucune modification réseau effectuée",
                true
        );
    }
}
