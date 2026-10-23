package com.clamp.acm.automation;

import com.clamp.acm.automation.service.AutomationService;
import com.clamp.acm.events.PolicyDecisionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class AutomationConsumer {

    private static final Logger log =
            LoggerFactory.getLogger(AutomationConsumer.class);

    private final AutomationService automationService;

    public AutomationConsumer(AutomationService automationService) {
        this.automationService = automationService;
    }

    @KafkaListener(
            topics = "${acm.kafka.decisions-topic:acm.policy-decisions}",
            groupId = "${spring.kafka.consumer.group-id:acm-automation-controller}")
    public void consume(PolicyDecisionEvent event) {
        if (event == null) {
            log.warn("Decision Kafka vide ignoree");
            return;
        }

        try {
            automationService.handleDecision(event);
        } catch (IllegalArgumentException ex) {
            log.error(
                    "Decision invalide rejetee: {}",
                    ex.getMessage());
        }
    }
}
