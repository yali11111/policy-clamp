package com.clamp.acm.monitoring;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class MonitoringScheduler {

    private static final Logger log =
            LoggerFactory.getLogger(MonitoringScheduler.class);

    private final MonitoringProducer producer;
    private final String target;

    public MonitoringScheduler(
            MonitoringProducer producer,
            @Value("${acm.monitoring.target:demo-cell-001}")
            String target) {
        this.producer = producer;
        this.target = target;
    }

    /*
     * Collecte de demonstration uniquement.
     *
     * Remplacer cette methode par un adaptateur vers les sources
     * reelles : API RAN, compteurs O-RAN, Prometheus ou collecteur.
     */
    @Scheduled(
            fixedDelayString = "${acm.monitoring.interval-ms:10000}")
    public void collectAndPublish() {

        Map<String, Double> metrics = Map.of(
                "cpuUtilizationPct", 65.0,
                "latencyMs", 20.0,
                "throughputMbps", 100.0
        );

        producer.publish(target, metrics)
                .whenComplete((result, error) -> {
                    if (error != null) {
                        log.warn(
                                "Echec de collecte/publication pour {}",
                                target);
                    } else {
                        log.debug(
                                "Collecte publiee pour {}",
                                target);
                    }
                });
    }
}
