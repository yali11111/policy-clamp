package org.example.ran.action.participant;

import org.onap.policy.ran.common.ActionEvent;
import org.example.ran.action.service.ActionExecutionResult;

/**
 * Interface d'intégration des exécutants d'actions.
 *
 * Chaque participant doit vérifier les paramètres et les
 * autorisations avant toute opération externe.
 */
public interface ActionParticipant {

    boolean supports(ActionEvent action);

    ActionExecutionResult execute(ActionEvent action);
}
