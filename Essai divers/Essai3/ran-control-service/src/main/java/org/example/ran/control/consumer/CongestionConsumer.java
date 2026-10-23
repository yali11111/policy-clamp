package org.example.ran.control.consumer;

import org.example.ran.control.policy.ControlLoopEngine;
import org.example.ran.control.producer.ActionProducer;
import org.onap.policy.ran.common.ActionEvent;
import org.onap.policy.ran.common.CongestionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class CongestionConsumer {

    private static final Logger LOG =
            LoggerFactory.getLogger(CongestionConsumer.class);

    private final ControlLoopEngine controlLoopEngine;
    private final ActionProducer actionProducer;

    public CongestionConsumer(
            ControlLoopEngine controlLoopEngine,
            ActionProducer actionProducer) {

        this.controlLoopEngine = controlLoopEngine;
        this.actionProducer = actionProducer;
    }

    @KafkaListener(
            topics = "${ran.kafka.topics.congestion:ran.congestion}",
            groupId = "${spring.kafka.consumer.group-id:ran-control-group}"
    )
    public void consume(CongestionEvent event) {
        if (event == null) {
            throw new IllegalArgumentException(
                    "Congestion event must not be null");
        }

        LOG.info(
                "Congestion received: node={}, cell={}, level={}, type={}",
                event.ranNodeId(),
                event.cellId(),
                event.level(),
                event.type()
        );

        ActionEvent action = controlLoopEngine.evaluate(event);

        actionProducer.publish(action).whenComplete((ignored, error) -> {
            if (error != null) {
                LOG.error(
                        "Action publication failed: cell={}, type={}",
                        event.cellId(),
                        action.actionType(),
                        error
                );
            }
        });
    }
}
