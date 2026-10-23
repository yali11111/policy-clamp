package org.onap.policy.clamp.acm.participant.multislice.service;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;
import org.onap.policy.clamp.acm.participant.multislice.models.SliceType;

class QuotaManagerTest {

    private final QuotaManager quotaManager =
            new QuotaManager(4000, 8192, 50);

    @Test
    void shouldAcceptRequestWithinLimits() {
        assertDoesNotThrow(() -> quotaManager.validate(
                SliceType.URLLC, 2, 1000, 1024));
    }

    @Test
    void shouldRejectCpuBudgetExceeded() {
        assertThrows(
                IllegalArgumentException.class,
                () -> quotaManager.validate(
                        SliceType.URLLC, 5, 1000, 512));
    }

    @Test
    void shouldRejectMemoryBudgetExceeded() {
        assertThrows(
                IllegalArgumentException.class,
                () -> quotaManager.validate(
                        SliceType.EMBB, 2, 500, 5000));
    }

    @Test
    void shouldRejectNegativeReplicas() {
        assertThrows(
                IllegalArgumentException.class,
                () -> quotaManager.validate(
                        SliceType.EMBB, -1, 500, 512));
    }
}
