package org.onap.policy.clamp.acm.participant.multislice.models;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class SliceTypeTest {

    @Test
    void shouldParseUrllc() {
        assertEquals(SliceType.URLLC, SliceType.from("URLLC"));
    }

    @Test
    void shouldParseEmbbIgnoringCase() {
        assertEquals(SliceType.EMBB, SliceType.from("eMBB"));
        assertEquals(SliceType.EMBB, SliceType.from("embb"));
    }

    @Test
    void shouldRejectUnknownType() {
        assertThrows(
                IllegalArgumentException.class,
                () -> SliceType.from("UNKNOWN"));
    }

    @Test
    void shouldRejectNullType() {
        assertThrows(
                IllegalArgumentException.class,
                () -> SliceType.from(null));
    }
}
