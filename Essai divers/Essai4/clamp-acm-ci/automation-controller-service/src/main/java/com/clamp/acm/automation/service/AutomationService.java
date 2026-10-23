package com.clamp.acm.automation.service;

import com.clamp.acm.automation.model.AutomationRequest;
import com.clamp.acm.automation.model.AutomationResponse;
import com.clamp.acm.events.PolicyDecisionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class AutomationService {

    private static final Logger log =
            LoggerFactory.getLogger(AutomationService.class);

    private static final List<String> ALLOWED_ACTIONS = List.of(
            "SCALE_OUT",
            "SCALE_IN",
            "TRAFFIC_STEERING",
            "NETWORK_CONFIG"
    );

    private final Map<String, AutomationResponse> requests =
            new ConcurrentHashMap<>();

    private final boolean executionEnabled;

    public AutomationService(
            @Value("${acm.automation.execution-enabled:false}")
            boolean executionEnabled) {
        this.executionEnabled = executionEnabled;
    }

    public AutomationResponse submit(AutomationRequest request) {
        if (!ALLOWED_ACTIONS.contains(request.actionType())) {
            throw new IllegalArgumentException(
                    "Action not allowed: " + request.actionType());
        }

        String id = UUID.randomUUID().toString();
        Instant now = Instant.now();

        String status = executionEnabled
                ? "ACCEPTED"
                : "SIMULATION_ONLY";

        String message = executionEnabled
                ? "Request accepted; execution adapter must validate target."
                : "Simulation only; no network operation was executed.";

        AutomationResponse response = new AutomationResponse(
                id,
                request.target(),
                request.actionType(),
                status,
                message,
                now
        );

        requests.put(id, response);

        log.info(
                "Automation request recorded: id={}, target={}, action={}, status={}",
                id,
                request.target(),
                request.actionType(),
                status
        );

        return response;
    }

    public AutomationResponse handleDecision(
            PolicyDecisionEvent decision) {

        if (decision == null) {
            throw new IllegalArgumentException(
                    "Policy decision is required");
        }

        String actionType = switch (decision.decision()) {
            case SCALE_OUT_REQUESTED -> "SCALE_OUT";
            case SCALE_IN_REQUESTED -> "SCALE_IN";
            case TRAFFIC_STEERING_REQUESTED -> "TRAFFIC_STEERING";
            case NO_ACTION, MANUAL_REVIEW -> null;
        };

        if (actionType == null) {
            log.info(
                    "No automated operation for decision {}: {}",
                    decision.decisionId(),
                    decision.decision()
            );

            return null;
        }

        AutomationRequest request = new AutomationRequest(
                decision.target(),
                actionType,
                "policy-engine-service",
                decision.reason()
        );

        return submit(request);
    }

    public List<AutomationResponse> findAll() {
        return requests.values()
                .stream()
                .sorted((a, b) ->
                        b.createdAt().compareTo(a.createdAt()))
                .toList();
    }

    public AutomationResponse findById(String requestId) {
        return requests.get(requestId);
    }
}
