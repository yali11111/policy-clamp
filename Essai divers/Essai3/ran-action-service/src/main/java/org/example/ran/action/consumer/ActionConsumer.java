package org.example.ran.action.consumer;

import org.example.ran.action.service.ActionExecutionResult;
import org.example.ran.action.service.ActionExecutionService;
import org.onap.policy.ran.common.ActionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class ActionConsumer {

    private static final Logger LOG =
            LoggerFactory.getLogger(ActionConsumer.class);

    private final ActionExecutionService executionService;

    public ActionConsumer(ActionExecutionService executionService) {
        this.executionService = executionService;
    }

    @KafkaListener(
            topics = "${ran.kafka.topics.action:ran.action}",
            groupId = "${spring.kafka.consumer.group-id:ran-action-group}"
    )
    public void consume(ActionEvent action) {
        if (action == null) {
            throw new IllegalArgumentException(
                    "Action event must not be null");
        }

        LOG.info(
                "Action received: id={}, type={}, status={}, cell={}",
                action.actionId(),
                action.actionType(),
                action.status(),
                action.cellId()
        );

        ActionExecutionResult result =
                executionService.execute(action);

        LOG.info(
                "Action processed: id={}, result={}, simulated={}, message={}",
                result.actionId(),
                result.status(),
                result.simulated(),
                result.message()
        );

        if ("FAILED".equals(result.status())) {
            throw new IllegalStateException(
                    "Action execution failed: " + result.actionId()
            );
        }
    }
}
