package com.example.orchestrator.kafka;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class ResultConsumer {

    @KafkaListener(
            topics = "prediction-topic",
            groupId = "beam-group")
    public void consumePrediction(String prediction) {

        System.out.println("--------------------------------");
        System.out.println("Prédiction ML :");
        System.out.println(prediction);
        System.out.println("--------------------------------");

    }

}
