package com.clamp.acm.automation.model;

import java.util.Objects;

public record AutomationRequest(
        String target,
        String actionType,
        String requestedBy,
        String reason) {

    public AutomationRequest {
        target = requireText(target, "target");
        actionType = requireText(actionType, "actionType");
        requestedBy = requireText(requestedBy, "requestedBy");
        reason = requireText(reason, "reason");

        if (target.length() > 200) {
            throw new IllegalArgumentException("target is too long");
        }

        if (reason.length() > 1000) {
            throw new IllegalArgumentException("reason is too long");
        }

        if (!Objects.equals(actionType, actionType.toUpperCase())) {
            throw new IllegalArgumentException(
                    "actionType must use uppercase characters");
        }
    }

    private static String requireText(String value, String field) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    field + " must not be blank");
        }
        return value.trim();
    }
}
