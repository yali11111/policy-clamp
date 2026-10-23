package org.onap.policy.clamp.acm.participant.multislice.parameters;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

import org.junit.jupiter.api.Test;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.context.annotation.Configuration;

class ParticipantMultiSliceParametersTest {

    private final ApplicationContextRunner contextRunner =
            new ApplicationContextRunner()
                    .withUserConfiguration(TestConfiguration.class);

    @Test
    void shouldLoadDefaultValues() {
        contextRunner.run(context -> {
            ParticipantMultiSliceParameters parameters =
                    context.getBean(ParticipantMultiSliceParameters.class);

            assertFalse(parameters.getKubernetes().isEnabled());
            assertEquals(
                    4000,
                    parameters.getQuota().getMaxCpuMillicores());
            assertEquals(
                    8192,
                    parameters.getQuota().getMaxMemoryMiB());
            assertEquals(
                    "network-slices",
                    parameters.getDefaults().getNamespace());
        });
    }

    @Test
    void shouldOverrideProperties() {
        contextRunner
                .withPropertyValues(
                        "slice.kubernetes.enabled=true",
                        "slice.quota.max-replicas=10",
                        "slice.defaults.namespace=test-slices")
                .run(context -> {
                    ParticipantMultiSliceParameters parameters =
                            context.getBean(
                                    ParticipantMultiSliceParameters.class);

                    assertEquals(
                            true,
                            parameters.getKubernetes().isEnabled());
                    assertEquals(
                            10,
                            parameters.getQuota().getMaxReplicas());
                    assertEquals(
                            "test-slices",
                            parameters.getDefaults().getNamespace());
                });
    }

    @Configuration(proxyBeanMethods = false)
    @EnableConfigurationProperties(ParticipantMultiSliceParameters.class)
    static class TestConfiguration {
    }
}
