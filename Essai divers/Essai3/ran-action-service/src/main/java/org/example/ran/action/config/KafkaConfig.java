package org.example.ran.action.config;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.onap.policy.ran.common.ActionEvent;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.kafka.support.serializer.JsonDeserializer;
import org.springframework.util.backoff.FixedBackOff;

import java.util.HashMap;
import java.util.Map;

@Configuration
@EnableKafka
public class KafkaConfig {

    @Bean
    public ConsumerFactory<String, ActionEvent> consumerFactory(
            @Value("${spring.kafka.bootstrap-servers:localhost:9092}")
            String bootstrapServers,
            @Value("${spring.kafka.consumer.group-id:ran-action-group}")
            String groupId) {

        Map<String, Object> props = new HashMap<>();

        props.put(
                ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG,
                bootstrapServers
        );

        props.put(
                ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG,
                false
        );

        JsonDeserializer<ActionEvent> deserializer =
                new JsonDeserializer<>(ActionEvent.class, false);

        deserializer.addTrustedPackages(
                "org.onap.policy.ran.common"
        );

        return new DefaultKafkaConsumerFactory<>(
                props,
                new StringDeserializer(),
                deserializer
        );
    }

    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, ActionEvent>
    kafkaListenerContainerFactory(
            ConsumerFactory<String, ActionEvent> consumerFactory) {

        ConcurrentKafkaListenerContainerFactory<String, ActionEvent>
                factory = new ConcurrentKafkaListenerContainerFactory<>();

        factory.setConsumerFactory(consumerFactory);

        factory.setCommonErrorHandler(
                new DefaultErrorHandler(
                        new FixedBackOff(1000L, 3L)
                )
        );

        return factory;
    }
}
