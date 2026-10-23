package org.example.ran.networkconfig.participant;

import org.example.ran.action.participant.ActionParticipant;
import org.example.ran.action.service.ActionExecutionResult;
import org.onap.policy.ran.common.ActionEvent;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Set;

/**
 * Participant de configuration réseau.
 *
 * Cette implémentation valide et simule les demandes.
 * Elle ne contacte aucun équipement, contrôleur ou API externe.
 */
@Component
public class NetworkConfigParticipant implements ActionParticipant {

    private static final Set<String> ALLOWED_PARAMETERS = Set.of(
            "configKey",
            "configValue",
            "target",
            "changeTicket"
    );

    private final boolean simulationMode;
    private final int maxValueLength;

    public NetworkConfigParticipant(
            @Value("${ran.network-config.simulation-mode:true}")
            boolean simulationMode,
            @Value("${ran.network-config.max-value-length:256}")
            int maxValueLength) {

        if (maxValueLength < 1 || maxValueLength > 4096) {
            throw new IllegalArgumentException(
                    "maxValueLength must be between 1 and 4096");
        }

        this.simulationMode = simulationMode;
        this.maxValueLength = maxValueLength;
    }

    @Override
    public boolean supports(ActionEvent action) {
        return action != null
                && action.actionType()
                == ActionEvent.ActionType.NETWORK_CONFIGURATION;
    }

    @Override
    public ActionExecutionResult execute(ActionEvent action) {
        if (!supports(action)) {
            return ActionExecutionResult.rejected(
                    action == null ? "unknown" : action.actionId(),
                    "Type d'action incompatible avec NetworkConfigParticipant"
            );
        }

        if (!simulationMode) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "Exécution réelle indisponible : aucun adaptateur réseau configuré"
            );
        }

        Map<String, String> parameters = action.parameters();

        if (parameters == null || parameters.isEmpty()) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "Paramètres de configuration absents"
            );
        }

        for (String key : parameters.keySet()) {
            if (!ALLOWED_PARAMETERS.contains(key)
                    && !key.equals("executionMode")) {
                return ActionExecutionResult.rejected(
                        action.actionId(),
                        "Paramètre de configuration non autorisé : " + key
                );
            }
        }

        String configKey = parameters.get("configKey");
        String configValue = parameters.get("configValue");
        String target = parameters.get("target");
        String changeTicket = parameters.get("changeTicket");

        if (configKey == null || configKey.isBlank()) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "configKey est obligatoire"
            );
        }

        if (configValue == null || configValue.isBlank()) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "configValue est obligatoire"
            );
        }

        if (configKey.length() > 128) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "configKey dépasse la longueur autorisée"
            );
        }

        if (configValue.length() > maxValueLength) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "configValue dépasse la longueur autorisée"
            );
        }

        if (target == null || target.isBlank()) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "La cible réseau est obligatoire"
            );
        }

        if (target.length() > 128) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "La cible réseau dépasse la longueur autorisée"
            );
        }

        if (changeTicket != null && changeTicket.length() > 128) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "changeTicket dépasse la longueur autorisée"
            );
        }

        /*
         * Aucun changement réel n'est effectué.
         * Ne pas journaliser configValue : il peut contenir
         * une donnée opérationnelle sensible.
         */
        return ActionExecutionResult.success(
                action.actionId(),
                "Configuration validée et simulée : target="
                        + target
                        + ", configKey="
                        + configKey
                        + ", changeTicket="
                        + (changeTicket == null ? "absent" : "présent")
                        + " ; aucune modification réseau effectuée",
                true
        );
    }
}
