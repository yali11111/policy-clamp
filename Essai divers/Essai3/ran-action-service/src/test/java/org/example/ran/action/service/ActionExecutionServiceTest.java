package org.example.ran.action.service;

import org.example.ran.action.participant.ActionParticipant;
import org.onap.policy.ran.common.ActionEvent;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class ActionExecutionServiceTest {

    private static final Instant NOW =
            Instant.parse("2026-01-01T12:00:00Z");

    private static ActionEvent createAction(
            ActionEvent.ActionType type,
            Instant expiresAt) {

        return new ActionEvent(
                "action-001",
                "correlation-001",
                "congestion-001",
                NOW,
                "gnb-001",
                "cell-001",
                "default",
                type,
                ActionEvent.ActionStatus.REQUESTED,
                ActionEvent.ActionTarget.SIMULATOR,
                Map.of("mode", "balanced"),
                "test action",
                "unit-test",
                expiresAt
        );
    }

    @Test
    void shouldExecuteActionWithSimulator() {
        ActionParticipant participant = new ActionParticipant() {
            @Override
            public boolean supports(ActionEvent action) {
                return action.actionType()
                        == ActionEvent.ActionType.TRAFFIC_STEERING;
            }

            @Override
            public ActionExecutionResult execute(ActionEvent action) {
                return ActionExecutionResult.success(
                        action.actionId(),
                        "simulated",
                        true
                );
            }
        };

        ActionExecutionService service =
                new ActionExecutionService(
                        List.of(participant),
                        true,
                        Clock.fixed(NOW, ZoneOffset.UTC)
                );

        ActionEvent action = createAction(
                ActionEvent.ActionType.TRAFFIC_STEERING,
                NOW.plusSeconds(60)
        );

        ActionExecutionResult result = service.execute(action);

        assertEquals("SUCCEEDED", result.status());
        assertTrue(result.simulated());
    }

    @Test
    void shouldRejectExpiredAction() {
        ActionExecutionService service =
                new ActionExecutionService(
                        List.of(),
                        true,
                        Clock.fixed(NOW, ZoneOffset.UTC)
                );

        ActionEvent action = createAction(
                ActionEvent.ActionType.TRAFFIC_STEERING,
                NOW.minusSeconds(1)
        );

        ActionExecutionResult result = service.execute(action);

        assertEquals("EXPIRED", result.status());
    }

    @Test
    void shouldIgnoreDuplicateActionId() {
        ActionParticipant participant = new ActionParticipant() {
            @Override
            public boolean supports(ActionEvent action) {
                return action.actionType()
                        == ActionEvent.ActionType.TRAFFIC_STEERING;
            }

            @Override
            public ActionExecutionResult execute(ActionEvent action) {
                return ActionExecutionResult.success(
                        action.actionId(),
                        "simulated",
                        true
                );
            }
        };

        ActionExecutionService service =
                new ActionExecutionService(
                        List.of(participant),
                        true,
                        Clock.fixed(NOW, ZoneOffset.UTC)
                );

        ActionEvent action = createAction(
                ActionEvent.ActionType.TRAFFIC_STEERING,
                NOW.plusSeconds(60)
        );

        ActionExecutionResult first = service.execute(action);
        ActionExecutionResult second = service.execute(action);

        assertEquals("SUCCEEDED", first.status());
        assertEquals("REJECTED", second.status());
    }

    @Test
    void shouldRejectRealExecutionWithoutAdapter() {
        ActionExecutionService service =
                new ActionExecutionService(
                        List.of(),
                        false,
                        Clock.fixed(NOW, ZoneOffset.UTC)
                );

        ActionEvent action = createAction(
                ActionEvent.ActionType.TRAFFIC_STEERING,
                NOW.plusSeconds(60)
        );

        ActionExecutionResult result = service.execute(action);

        assertEquals("REJECTED", result.status());
        assertTrue(result.message().contains("adaptateur"));
    }

    @Test
    void shouldAcceptNoOpWithoutParticipant() {
        ActionExecutionService service =
                new ActionExecutionService(
                        List.of(),
                        true,
                        Clock.fixed(NOW, ZoneOffset.UTC)
                );

        ActionEvent action = createAction(
                ActionEvent.ActionType.NO_OP,
                NOW.plusSeconds(60)
        );

        ActionExecutionResult result = service.execute(action);

        assertEquals("SUCCEEDED", result.status());
        assertTrue(result.simulated());
    }
}
