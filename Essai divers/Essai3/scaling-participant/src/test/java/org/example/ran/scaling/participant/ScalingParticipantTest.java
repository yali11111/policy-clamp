package org.example.ran.scaling.participant;

import org.example.ran.action.service.ActionExecutionResult;
import org.onap.policy.ran.common.ActionEvent;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class ScalingParticipantTest {

    private ActionEvent action(
            ActionEvent.ActionType type,
            Map<String, String> parameters) {

        Instant now = Instant.parse("2026-01-01T12:00:00Z");

        return new ActionEvent(
                "action-scale-001",
                "correlation-001",
                "congestion-001",
                now,
                "gnb-001",
                "cell-001",
                "default",
                type,
                ActionEvent.ActionStatus.REQUESTED,
                ActionEvent.ActionTarget.SCALING_PARTICIPANT,
                parameters,
                "test scaling",
                "unit-test",
                now.plusSeconds(60)
        );
    }

    @Test
    void supportsScaleOutAndScaleIn() {
        ScalingParticipant participant =
                new ScalingParticipant(true, 1, 10);

        assertTrue(participant.supports(action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of()
        )));

        assertTrue(participant.supports(action(
                ActionEvent.ActionType.SCALE_IN,
                Map.of()
        )));

        assertFalse(participant.supports(action(
                ActionEvent.ActionType.NO_OP,
                Map.of()
        )));
    }

    @Test
    void simulatesScaleOutWithinConfiguredLimits() {
        ScalingParticipant participant =
                new ScalingParticipant(true, 1, 10);

        ActionExecutionResult result = participant.execute(action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "component", "ran-capacity",
                        "direction", "out",
                        "requestedReplicas", "3"
                )
        ));

        assertEquals("SUCCEEDED", result.status());
        assertTrue(result.simulated());
        assertTrue(result.message().contains("requestedReplicas=3"));
    }

    @Test
    void rejectsReplicaCountOutsideLimits() {
        ScalingParticipant participant =
                new ScalingParticipant(true, 1, 5);

        ActionExecutionResult result = participant.execute(action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of("requestedReplicas", "8")
        ));

        assertEquals("REJECTED", result.status());
    }

    @Test
    void rejectsInvalidReplicaCount() {
        ScalingParticipant participant =
                new ScalingParticipant(true, 1, 10);

        ActionExecutionResult result = participant.execute(action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of("requestedReplicas", "abc")
        ));

        assertEquals("REJECTED", result.status());
    }

    @Test
    void rejectsRealExecutionWithoutAdapter() {
        ScalingParticipant participant =
                new ScalingParticipant(false, 1, 10);

        ActionExecutionResult result = participant.execute(action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of("requestedReplicas", "2")
        ));

        assertEquals("REJECTED", result.status());
        assertFalse(result.message().isBlank());
    }

    @Test
    void rejectsMismatchedDirection() {
        ScalingParticipant participant =
                new ScalingParticipant(true, 1, 10);

        ActionExecutionResult result = participant.execute(action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "direction", "in",
                        "requestedReplicas", "2"
                )
        ));

        assertEquals("REJECTED", result.status());
    }

    @Test
    void rejectsInvalidReplicaLimits() {
        assertThrows(
                IllegalArgumentException.class,
                () -> new ScalingParticipant(true, 5, 2)
        );
    }
}
