package com.example.orchestrator.kafka;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class EventPublisher {

    @Autowired
    private KafkaTemplate<String, Object> kafkaTemplate;

    public void publish(Object event) {

        kafkaTemplate.send(
                "automation-topic",
                event
        );

        System.out.println(
                "Automation event envoyé : "
                        + event
        );

    }

    public void publishPrediction(Object prediction) {

        kafkaTemplate.send(
                "prediction-topic",
                prediction
        );

        System.out.println(
                "Prediction publiée."
        );

    }

    public void publishKpi(Object metric) {

        kafkaTemplate.send(
                "kpi-topic",
                metric
        );

        System.out.println(
                "KPI publié."
        );

    }

}
