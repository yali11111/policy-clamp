package org.example.ran.control.producer;

import org.onap.policy.ran.common.ActionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.concurrent.CompletableFuture;

@Component
public class ActionProducer {

    private static final Logger LOG =
            LoggerFactory.getLogger(ActionProducer.class);

    private final KafkaTemplate<String, Object> kafkaTemplate;
    private final String topic;

    public ActionProducer(
            KafkaTemplate<String, Object> kafkaTemplate,
            @Value("${ran.kafka.topics.action:ran.action}")
            String topic) {

        this.kafkaTemplate = kafkaTemplate;
        this.topic = topic;
    }

    public CompletableFuture<Void> publish(ActionEvent event) {
        return kafkaTemplate.send(
                topic,
                event.cellId(),
                event
        ).thenAccept(result -> LOG.info(
                "Action published: cell={}, type={}, partition={}",
                event.cellId(),
                event.actionType(),
                result.getRecordMetadata().partition()
        ));
    }
}
