package com.clamp.acm.monitoring;

import com.clamp.acm.events.MetricsEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

@Service
public class MonitoringProducer {

    private static final Logger log =
            LoggerFactory.getLogger(MonitoringProducer.class);

    private final KafkaTemplate<String, MetricsEvent> kafkaTemplate;
    private final String topic;

    public MonitoringProducer(
            KafkaTemplate<String, MetricsEvent> kafkaTemplate,
            @Value("${acm.kafka.metrics-topic:acm.metrics}")
            String topic) {
        this.kafkaTemplate = kafkaTemplate;
        this.topic = topic;
    }

    public CompletableFuture<?> publish(
            String target,
            Map<String, Double> metrics) {

        MetricsEvent event = new MetricsEvent(
                UUID.randomUUID().toString(),
                "monitoring-service",
                target,
                Instant.now(),
                metrics,
                Map.of("origin", "scheduled-monitoring")
        );

        return kafkaTemplate.send(topic, target, event)
                .whenComplete((result, error) -> {
                    if (error != null) {
                        log.error(
                                "Publication Kafka impossible pour {}",
                                target,
                                error);
                    } else {
                        log.debug(
                                "Evenement {} publie sur {}",
                                event.eventId(),
                                topic);
                    }
                });
    }
}
