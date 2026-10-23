package com.example.orchestrator.kafka;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class KpiConsumer {

    @KafkaListener(topics = "kpi-topic", groupId = "beam-group")
    public void consume(String message) {

        System.out.println("--------------------------------");
        System.out.println("KPI reçu :");
        System.out.println(message);
        System.out.println("--------------------------------");

    }

}
