package org.onap.policy.clamp.acm.participant.multislice.handler;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.onap.policy.clamp.acm.participant.multislice.models.SliceConfiguration;
import org.onap.policy.clamp.acm.participant.multislice.models.SliceType;
import org.onap.policy.clamp.acm.participant.multislice.service.SliceService;
import org.mockito.Mockito;

class SliceElementHandlerTest {

    @Test
    void shouldConvertValidProperties() {
        SliceService service = Mockito.mock(SliceService.class);
        SliceElementHandler handler =
                new SliceElementHandler(service, new ObjectMapper());

        Map<String, Object> properties = Map.of(
                "sliceId", "slice-001",
                "sliceType", "URLLC",
                "namespace", "network-slices",
                "deploymentName", "urllc-app",
                "replicas", 1,
                "cpuMillicores", 500,
                "memoryMiB", 512);

        SliceConfiguration config = handler.convert(properties);

        assertEquals("slice-001", config.getSliceId());
        assertEquals(SliceType.URLLC, config.getSliceType());
    }

    @Test
    void shouldRejectEmptyProperties() {
        SliceService service = Mockito.mock(SliceService.class);
        SliceElementHandler handler =
                new SliceElementHandler(service, new ObjectMapper());

        assertThrows(
                IllegalArgumentException.class,
                () -> handler.convert(Map.of()));
    }
}
