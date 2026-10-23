package org.example.ran.action.participant.scaling;

import org.example.ran.action.service.ActionExecutionResult;
import org.junit.jupiter.api.Test;
import org.onap.policy.ran.common.ActionEvent;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class ScalingParticipantTest {

    private static final Instant NOW =
            Instant.parse("2026-01-01T12:00:00Z");

    private ScalingPolicy policy() {
        return new ScalingPolicy(1, 10, 2);
    }

    private ScalingParticipant participant() {
        return new ScalingParticipant(
                policy(),
                true,
                Clock.fixed(NOW, ZoneOffset.UTC)
        );
    }

    private ActionEvent action(
            ActionEvent.ActionType type,
            Map<String, String> parameters,
            Instant expiresAt) {

        return new ActionEvent(
                "scaling-001",
                "correlation-001",
                "congestion-001",
                NOW,
                "gnb-001",
                "cell-001",
                "default",
                type,
                ActionEvent.ActionStatus.REQUESTED,
                ActionEvent.ActionTarget.SCALING_PARTICIPANT,
                parameters,
                "Test de scaling",
                "ran-control-service",
                expiresAt
        );
    }

    @Test
    void shouldSupportScaleOutAndScaleIn() {
        ScalingParticipant participant = participant();

        assertTrue(participant.supports(action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(),
                NOW.plusSeconds(60)
        )));

        assertTrue(participant.supports(action(
                ActionEvent.ActionType.SCALE_IN,
                Map.of(),
                NOW.plusSeconds(60)
        )));

        assertFalse(participant.supports(null));
    }

    @Test
    void shouldSimulateScaleOut() {
        ActionEvent action = action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "component", "ran-capacity",
                        "direction", "out",
                        "requestedReplicas", "3",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        ActionExecutionResult result = participant().execute(action);

        assertEquals("SUCCEEDED", result.status());
        assertTrue(result.simulated());
    }

    @Test
    void shouldRejectTargetAboveMaximum() {
        ActionEvent action = action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "component", "ran-capacity",
                        "direction", "out",
                        "requestedReplicas", "11",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        assertEquals(
                "REJECTED",
                participant().execute(action).status()
        );
    }

    @Test
    void shouldRejectInconsistentDirection() {
        ActionEvent action = action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "component", "ran-capacity",
                        "direction", "in",
                        "requestedReplicas", "3",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        assertEquals(
                "REJECTED",
                participant().execute(action).status()
        );
    }

    @Test
    void shouldRejectMalformedReplicaCount() {
        ActionEvent action = action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "component", "ran-capacity",
                        "direction", "out",
                        "requestedReplicas", "three",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        assertEquals(
                "REJECTED",
                participant().execute(action).status()
        );
    }

    @Test
    void shouldRejectExpiredAction() {
        ActionEvent action = action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "component", "ran-capacity",
                        "direction", "out",
                        "requestedReplicas", "3",
                        "executionMode", "SIMULATION"
                ),
                NOW.minusSeconds(1)
        );

        assertEquals(
                "EXPIRED",
                participant().execute(action).status()
        );
    }

    @Test
    void shouldRejectRealExecution() {
        ScalingParticipant realModeParticipant =
                new ScalingParticipant(
                        policy(),
                        false,
                        Clock.fixed(NOW, ZoneOffset.UTC)
                );

        ActionEvent action = action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "component", "ran-capacity",
                        "direction", "out",
                        "requestedReplicas", "3",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        assertEquals(
                "REJECTED",
                realModeParticipant.execute(action).status()
        );
    }

    @Test
    void shouldValidatePolicyLimits() {
        assertThrows(
                IllegalArgumentException.class,
                () -> new ScalingPolicy(1, 0, 2)
        );

        assertThrows(
                IllegalArgumentException.class,
                () -> new ScalingPolicy(1, 10, 0)
        );

        assertTrue(policy().isValidTarget(1));
        assertTrue(policy().isValidTarget(10));
        assertFalse(policy().isValidTarget(11));

        assertTrue(policy().isValidStep(2));
        assertFalse(policy().isValidStep(3));
    }
}
