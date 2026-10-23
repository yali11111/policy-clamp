package org.example.ran.predictor.consumer;

import org.example.ran.predictor.producer.CongestionProducer;
import org.example.ran.predictor.service.CongestionPredictorService;
import org.onap.policy.ran.common.CongestionEvent;
import org.onap.policy.ran.common.RanKpi;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class KpiConsumer {

    private static final Logger LOG =
            LoggerFactory.getLogger(KpiConsumer.class);

    private final CongestionPredictorService predictor;
    private final CongestionProducer producer;

    public KpiConsumer(
            CongestionPredictorService predictor,
            CongestionProducer producer) {
        this.predictor = predictor;
        this.producer = producer;
    }

    @KafkaListener(
            topics = "${ran.kafka.topics.kpi:ran.kpi}",
            groupId = "${spring.kafka.consumer.group-id:ran-predictor-group}"
    )
    public void consume(RanKpi kpi) {
        CongestionEvent event = predictor.evaluate(kpi);

        producer.publish(event).whenComplete((ignored, error) -> {
            if (error != null) {
                LOG.error(
                        "Failed to publish congestion event for cell {}",
                        kpi.cellId(),
                        error
                );
            }
        });
    }
}
