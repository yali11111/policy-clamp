package com.clamp.acm.policy;

import com.clamp.acm.events.MetricsEvent;
import com.clamp.acm.events.PolicyDecisionEvent;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.Produced;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.support.serializer.JsonSerde;

@Configuration
public class PolicyTopology {

    @Bean
    public Topology policyStreamTopology(
            StreamsBuilder builder,
            PolicyStreamProcessor processor,
            @Value("${acm.kafka.metrics-topic:acm.metrics}")
            String metricsTopic,
            @Value("${acm.kafka.decisions-topic:acm.policy-decisions}")
            String decisionsTopic) {

        JsonSerde<MetricsEvent> metricsSerde =
                new JsonSerde<>(MetricsEvent.class);

        JsonSerde<PolicyDecisionEvent> decisionSerde =
                new JsonSerde<>(PolicyDecisionEvent.class);

        builder.stream(
                    metricsTopic,
                    Consumed.with(Serdes.String(), metricsSerde))
                .mapValues(processor::evaluate)
                .filter((key, decision) -> decision != null)
                .to(
                    decisionsTopic,
                    Produced.with(Serdes.String(), decisionSerde));

        return builder.build();
    }
}
