package org.example.ran.predictor.producer;

import org.onap.policy.ran.common.CongestionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.concurrent.CompletableFuture;

@Component
public class CongestionProducer {

    private static final Logger LOG =
            LoggerFactory.getLogger(CongestionProducer.class);

    private final KafkaTemplate<String, Object> kafkaTemplate;
    private final String topic;

    public CongestionProducer(
            KafkaTemplate<String, Object> kafkaTemplate,
            @Value("${ran.kafka.topics.congestion:ran.congestion}")
            String topic) {

        this.kafkaTemplate = kafkaTemplate;
        this.topic = topic;
    }

    public CompletableFuture<Void> publish(CongestionEvent event) {
        return kafkaTemplate.send(
                topic,
                event.cellId(),
                event
        ).thenAccept(result -> LOG.info(
                "Congestion published: cell={}, level={}, partition={}",
                event.cellId(),
                event.level(),
                result.getRecordMetadata().partition()
        ));
    }
}
