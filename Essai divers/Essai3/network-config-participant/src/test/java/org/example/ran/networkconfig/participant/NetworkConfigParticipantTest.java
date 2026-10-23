package org.example.ran.networkconfig.participant;

import org.example.ran.action.service.ActionExecutionResult;
import org.junit.jupiter.api.Test;
import org.onap.policy.ran.common.ActionEvent;

import java.time.Instant;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class NetworkConfigParticipantTest {

    private static final Instant NOW =
            Instant.parse("2026-01-01T12:00:00Z");

    private ActionEvent createAction(
            ActionEvent.ActionType type,
            Map<String, String> parameters) {

        return new ActionEvent(
                "action-config-001",
                "correlation-001",
                "congestion-001",
                NOW,
                "gnb-001",
                "cell-001",
                "default",
                type,
                ActionEvent.ActionStatus.REQUESTED,
                ActionEvent.ActionTarget.NETWORK_CONFIG_PARTICIPANT,
                parameters,
                "test network configuration",
                "unit-test",
                NOW.plusSeconds(60)
        );
    }

    private Map<String, String> validParameters() {
        return Map.of(
                "configKey", "scheduler.policy",
                "configValue", "balanced",
                "target", "cell-001",
                "changeTicket", "CHANGE-001"
        );
    }

    @Test
    void supportsOnlyNetworkConfigurationActions() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 256);

        assertTrue(participant.supports(createAction(
                ActionEvent.ActionType.NETWORK_CONFIGURATION,
                validParameters()
        )));

        assertFalse(participant.supports(createAction(
                ActionEvent.ActionType.SCALE_OUT,
                validParameters()
        )));

        assertFalse(participant.supports(createAction(
                ActionEvent.ActionType.NO_OP,
                Map.of()
        )));

        assertFalse(participant.supports(null));
    }

    @Test
    void simulatesValidConfiguration() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 256);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.NETWORK_CONFIGURATION,
                        validParameters()
                )
        );

        assertEquals("SUCCEEDED", result.status());
        assertTrue(result.simulated());
        assertTrue(result.message().contains("cell-001"));
        assertTrue(result.message().contains("scheduler.policy"));
    }

    @Test
    void rejectsMissingConfigKey() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 256);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.NETWORK_CONFIGURATION,
                        Map.of(
                                "configValue", "balanced",
                                "target", "cell-001"
                        )
                )
        );

        assertEquals("REJECTED", result.status());
        assertTrue(result.message().contains("configKey"));
    }

    @Test
    void rejectsMissingConfigValue() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 256);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.NETWORK_CONFIGURATION,
                        Map.of(
                                "configKey", "scheduler.policy",
                                "target", "cell-001"
                        )
                )
        );

        assertEquals("REJECTED", result.status());
        assertTrue(result.message().contains("configValue"));
    }

    @Test
    void rejectsMissingTarget() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 256);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.NETWORK_CONFIGURATION,
                        Map.of(
                                "configKey", "scheduler.policy",
                                "configValue", "balanced"
                        )
                )
        );

        assertEquals("REJECTED", result.status());
        assertTrue(result.message().contains("cible"));
    }

    @Test
    void rejectsUnsupportedParameter() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 256);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.NETWORK_CONFIGURATION,
                        Map.of(
                                "configKey", "scheduler.policy",
                                "configValue", "balanced",
                                "target", "cell-001",
                                "shellCommand", "unexpected"
                        )
                )
        );

        assertEquals("REJECTED", result.status());
        assertTrue(result.message().contains("non autorisé"));
    }

    @Test
    void rejectsConfigValueExceedingConfiguredLimit() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 8);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.NETWORK_CONFIGURATION,
                        Map.of(
                                "configKey", "scheduler.policy",
                                "configValue", "value-too-long",
                                "target", "cell-001"
                        )
                )
        );

        assertEquals("REJECTED", result.status());
        assertTrue(result.message().contains("longueur"));
    }

    @Test
    void rejectsRealExecutionWithoutAdapter() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(false, 256);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.NETWORK_CONFIGURATION,
                        validParameters()
                )
        );

        assertEquals("REJECTED", result.status());
        assertFalse(result.simulated());
        assertTrue(result.message().contains("adaptateur"));
    }

    @Test
    void rejectsInvalidMaximumValueLength() {
        assertThrows(
                IllegalArgumentException.class,
                () -> new NetworkConfigParticipant(true, 0)
        );

        assertThrows(
                IllegalArgumentException.class,
                () -> new NetworkConfigParticipant(true, 4097)
        );
    }

    @Test
    void rejectsWrongActionType() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 256);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.SCALE_OUT,
                        validParameters()
                )
        );

        assertEquals("REJECTED", result.status());
    }
}
