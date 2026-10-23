package com.clamp.acm.automation.model;

import java.time.Instant;

public record AutomationResponse(
        String requestId,
        String target,
        String actionType,
        String status,
        String message,
        Instant createdAt) {
}
