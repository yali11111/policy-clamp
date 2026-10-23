package org.example.ran.action.participant.steering;

import org.example.ran.action.service.ActionExecutionResult;
import org.junit.jupiter.api.Test;
import org.onap.policy.ran.common.ActionEvent;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class TrafficSteeringParticipantTest {

    private static final Instant NOW =
            Instant.parse("2026-01-01T12:00:00Z");

    private TrafficSteeringParticipant participant() {
        return new TrafficSteeringParticipant(
                Clock.fixed(NOW, ZoneOffset.UTC)
        );
    }

    private ActionEvent action(
            Map<String, String> parameters,
            Instant expiresAt) {

        return new ActionEvent(
                "steering-001",
                "correlation-001",
                "congestion-001",
                NOW,
                "gnb-001",
                "cell-001",
                "default",
                ActionEvent.ActionType.TRAFFIC_STEERING,
                ActionEvent.ActionStatus.REQUESTED,
                ActionEvent.ActionTarget.TRAFFIC_STEERING_PARTICIPANT,
                parameters,
                "Test de steering",
                "ran-control-service",
                expiresAt
        );
    }

    @Test
    void shouldSupportOnlyTrafficSteering() {
        TrafficSteeringParticipant participant = participant();

        ActionEvent action = action(
                Map.of(),
                NOW.plusSeconds(60)
        );

        assertTrue(participant.supports(action));
        assertFalse(participant.supports(null));
    }

    @Test
    void shouldSimulateValidBalancedSteering() {
        TrafficSteeringParticipant participant = participant();

        ActionEvent action = action(
                Map.of(
                        "mode", "balanced",
                        "sourceCell", "cell-001",
                        "preserveQos", "true",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        ActionExecutionResult result = participant.execute(action);

        assertEquals("SUCCEEDED", result.status());
        assertTrue(result.simulated());
    }

    @Test
    void shouldRejectInvalidMode() {
        TrafficSteeringParticipant participant = participant();

        ActionEvent action = action(
                Map.of(
                        "mode", "unrestricted",
                        "sourceCell", "cell-001",
                        "preserveQos", "true",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        assertEquals(
                "REJECTED",
                participant.execute(action).status()
        );
    }

    @Test
    void shouldRejectInconsistentSourceCell() {
        TrafficSteeringParticipant participant = participant();

        ActionEvent action = action(
                Map.of(
                        "mode", "balanced",
                        "sourceCell", "cell-999",
                        "preserveQos", "true",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        assertEquals(
                "REJECTED",
                participant.execute(action).status()
        );
    }

    @Test
    void shouldRejectRealExecutionMode() {
        TrafficSteeringParticipant participant = participant();

        ActionEvent action = action(
                Map.of(
                        "mode", "emergency",
                        "sourceCell", "cell-001",
                        "preserveQos", "true",
                        "executionMode", "PARTICIPANT"
                ),
                NOW.plusSeconds(60)
        );

        ActionExecutionResult result = participant.execute(action);

        assertEquals("REJECTED", result.status());
        assertTrue(result.simulated());
    }

    @Test
    void shouldRejectExpiredAction() {
        TrafficSteeringParticipant participant = participant();

        ActionEvent action = action(
                Map.of(
                        "mode", "balanced",
                        "sourceCell", "cell-001",
                        "preserveQos", "true",
                        "executionMode", "SIMULATION"
                ),
                NOW.minusSeconds(1)
        );

        assertEquals(
                "EXPIRED",
                participant.execute(action).status()
        );
    }
}
