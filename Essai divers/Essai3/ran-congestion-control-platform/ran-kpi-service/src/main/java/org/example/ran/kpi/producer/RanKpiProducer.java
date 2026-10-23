package org.example.ran.kpi.producer;

import org.onap.policy.ran.common.RanKpi;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.concurrent.CompletableFuture;

/**
 * Publie les KPI RAN dans Kafka.
 */
@Component
public class RanKpiProducer {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(RanKpiProducer.class);

    private final KafkaTemplate<String, Object> kafkaTemplate;
    private final String topic;

    public RanKpiProducer(
            KafkaTemplate<String, Object> kafkaTemplate,
            @Value("${ran.kafka.topics.kpi:ran.kpi}") String topic) {

        this.kafkaTemplate = kafkaTemplate;
        this.topic = topic;
    }

    public CompletableFuture<Void> publish(RanKpi kpi) {
        String key = kpi.cellId();

        return kafkaTemplate.send(topic, key, kpi)
                .thenAccept(result -> LOGGER.debug(
                        "KPI published: eventId={}, cellId={}, topic={}, partition={}",
                        kpi.eventId(),
                        kpi.cellId(),
                        result.getRecordMetadata().topic(),
                        result.getRecordMetadata().partition()
                ));
    }
}
