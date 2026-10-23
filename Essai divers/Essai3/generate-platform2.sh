
#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# RAN Congestion Control Platform
# Partie 1/8 : initialisation et fichiers racine
# Ce script génère des fichiers. Il ne démarre aucun service.
# ============================================================

ROOT="ran-congestion-control-platform"


# ============================================================
# PARTIE 6A/8 — RAN CONTROL SERVICE
# Moteur de décision et producteur Kafka
# ============================================================

set -eu

BASE="ran-control-service"
PKG="$BASE/src/main/java/org/example/ran/control"

mkdir -p \
  "$PKG/policy" \
  "$PKG/producer" \
  "$PKG/consumer" \
  "$PKG/config" \
  "$BASE/src/main/resources"

# ------------------------------------------------------------
# 1. ControlLoopEngine.java
# ------------------------------------------------------------

cat > "$PKG/policy/ControlLoopEngine.java" <<'EOF'
package org.example.ran.control.policy;

import org.onap.policy.ran.common.ActionEvent;
import org.onap.policy.ran.common.CongestionEvent;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class ControlLoopEngine {

    private final boolean simulationMode;
    private final double steeringThreshold;
    private final double scaleOutThreshold;
    private final double criticalThreshold;
    private final Duration cooldown;
    private final Duration actionTtl;
    private final Clock clock;

    private final Map<String, Instant> lastActionByCell =
            new ConcurrentHashMap<>();

    public ControlLoopEngine(
            @Value("${ran.control.simulation-mode:true}")
            boolean simulationMode,
            @Value("${ran.control.thresholds.steering-prb:75.0}")
            double steeringThreshold,
            @Value("${ran.control.thresholds.scale-out-prb:90.0}")
            double scaleOutThreshold,
            @Value("${ran.control.thresholds.critical-prb:97.0}")
            double criticalThreshold,
            @Value("${ran.control.cooldown-seconds:30}")
            long cooldownSeconds,
            @Value("${ran.control.action-ttl-seconds:60}")
            long actionTtlSeconds) {

        this(
                simulationMode,
                steeringThreshold,
                scaleOutThreshold,
                criticalThreshold,
                cooldownSeconds,
                actionTtlSeconds,
                Clock.systemUTC()
        );
    }

    ControlLoopEngine(
            boolean simulationMode,
            double steeringThreshold,
            double scaleOutThreshold,
            double criticalThreshold,
            long cooldownSeconds,
            long actionTtlSeconds,
            Clock clock) {

        if (!Double.isFinite(steeringThreshold)
                || steeringThreshold < 0
                || steeringThreshold > 100) {
            throw new IllegalArgumentException(
                    "steeringThreshold must be between 0 and 100");
        }

        if (!Double.isFinite(scaleOutThreshold)
                || scaleOutThreshold < steeringThreshold
                || scaleOutThreshold > 100) {
            throw new IllegalArgumentException(
                    "scaleOutThreshold must be >= steeringThreshold and <= 100");
        }

        if (!Double.isFinite(criticalThreshold)
                || criticalThreshold < scaleOutThreshold
                || criticalThreshold > 100) {
            throw new IllegalArgumentException(
                    "criticalThreshold must be >= scaleOutThreshold and <= 100");
        }

        if (cooldownSeconds < 0 || actionTtlSeconds <= 0) {
            throw new IllegalArgumentException(
                    "Invalid cooldown or action TTL");
        }

        this.simulationMode = simulationMode;
        this.steeringThreshold = steeringThreshold;
        this.scaleOutThreshold = scaleOutThreshold;
        this.criticalThreshold = criticalThreshold;
        this.cooldown = Duration.ofSeconds(cooldownSeconds);
        this.actionTtl = Duration.ofSeconds(actionTtlSeconds);
        this.clock = clock;
    }

    public ActionEvent evaluate(CongestionEvent event) {
        if (event == null) {
            throw new IllegalArgumentException(
                    "Congestion event must not be null");
        }

        Instant now = clock.instant();

        String cellKey = event.ranNodeId() + "/" + event.cellId();

        if (event.level() == CongestionEvent.CongestionLevel.NORMAL
                || event.type() == CongestionEvent.CongestionType.CLEARED) {
            return noOp(event, now, "Congestion absente ou résolue");
        }

        if (event.level() == CongestionEvent.CongestionLevel.LOW
                || event.level() == CongestionEvent.CongestionLevel.MEDIUM) {
            return noOp(event, now, "Niveau de congestion insuffisant");
        }

        if (!Double.isFinite(event.confidence())
                || event.confidence() < 0.50
                || event.confidence() > 1.0) {
            return noOp(event, now, "Confiance insuffisante ou invalide");
        }

        Instant lastAction = lastActionByCell.get(cellKey);

        if (lastAction != null
                && now.isBefore(lastAction.plus(cooldown))) {
            return noOp(event, now, "Période de cooldown active");
        }

        ActionEvent action = selectAction(event, now);

        if (action.actionType() != ActionEvent.ActionType.NO_OP) {
            lastActionByCell.put(cellKey, now);
        }

        return action;
    }

    private ActionEvent selectAction(
            CongestionEvent event,
            Instant now) {

        double prb = event.prbUtilizationPercent();

        ActionEvent.ActionType actionType;
        ActionEvent.ActionTarget target;
        Map<String, String> parameters;
        String reason;

        if (event.level() == CongestionEvent.CongestionLevel.CRITICAL
                || prb >= criticalThreshold) {

            actionType = ActionEvent.ActionType.TRAFFIC_STEERING;
            target = ActionEvent.ActionTarget.TRAFFIC_STEERING_PARTICIPANT;

            parameters = Map.of(
                    "mode", "emergency",
                    "sourceCell", event.cellId(),
                    "preserveQos", "true"
            );

            reason = "Congestion critique : délestage prioritaire";

        } else if (prb >= scaleOutThreshold) {

            actionType = ActionEvent.ActionType.SCALE_OUT;
            target = ActionEvent.ActionTarget.SCALING_PARTICIPANT;

            parameters = Map.of(
                    "component", "ran-capacity",
                    "direction", "out",
                    "requestedReplicas", "1"
            );

            reason = "Utilisation PRB élevée : demande de capacité";

        } else if (prb >= steeringThreshold) {

            actionType = ActionEvent.ActionType.TRAFFIC_STEERING;
            target = ActionEvent.ActionTarget.TRAFFIC_STEERING_PARTICIPANT;

            parameters = Map.of(
                    "mode", "balanced",
                    "sourceCell", event.cellId(),
                    "preserveQos", "true"
            );

            reason = "Charge radio élevée : rééquilibrage du trafic";

        } else {
            actionType = ActionEvent.ActionType.NO_OP;
            target = ActionEvent.ActionTarget.SIMULATOR;
            parameters = Map.of();
            reason = "Seuil PRB insuffisant pour une action";
        }

        java.util.Map<String, String> enriched =
                new java.util.HashMap<>(parameters);

        enriched.put(
                "executionMode",
                simulationMode ? "SIMULATION" : "PARTICIPANT"
        );

        return new ActionEvent(
                null,
                event.correlationId(),
                event.eventId(),
                now,
                event.ranNodeId(),
                event.cellId(),
                event.sliceId(),
                actionType,
                ActionEvent.ActionStatus.REQUESTED,
                target,
                Map.copyOf(enriched),
                reason,
                "ran-control-service",
                now.plus(actionTtl)
        );
    }

    private ActionEvent noOp(
            CongestionEvent event,
            Instant now,
            String reason) {

        return new ActionEvent(
                null,
                event.correlationId(),
                event.eventId(),
                now,
                event.ranNodeId(),
                event.cellId(),
                event.sliceId(),
                ActionEvent.ActionType.NO_OP,
                ActionEvent.ActionStatus.REQUESTED,
                ActionEvent.ActionTarget.SIMULATOR,
                Map.of("executionMode", "SIMULATION"),
                reason,
                "ran-control-service",
                now.plus(actionTtl)
        );
    }
}
EOF

# ------------------------------------------------------------
# 2. ActionProducer.java
# ------------------------------------------------------------

cat > "$PKG/producer/ActionProducer.java" <<'EOF'
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
EOF

echo "Partie 6A/8 générée : ControlLoopEngine et ActionProducer."



# ============================================================
# PARTIE 6B/8 — RAN CONTROL SERVICE
# Consommateur Kafka, configuration, application et documentation
# Génération des fichiers uniquement.
# ============================================================

set -eu

BASE="ran-control-service"
PKG="$BASE/src/main/java/org/example/ran/control"

mkdir -p \
  "$PKG/consumer" \
  "$PKG/config" \
  "$BASE/src/main/resources"

# ------------------------------------------------------------
# 3. CongestionConsumer.java
# ------------------------------------------------------------

cat > "$PKG/consumer/CongestionConsumer.java" <<'EOF'
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
EOF

# ------------------------------------------------------------
# 4. KafkaConfig.java
# ------------------------------------------------------------

cat > "$PKG/config/KafkaConfig.java" <<'EOF'
package org.example.ran.control.config;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.onap.policy.ran.common.CongestionEvent;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.kafka.support.serializer.JsonDeserializer;
import org.springframework.kafka.support.serializer.JsonSerializer;
import org.springframework.util.backoff.FixedBackOff;

import java.util.HashMap;
import java.util.Map;

@Configuration
@EnableKafka
public class KafkaConfig {

    @Bean
    public ConsumerFactory<String, CongestionEvent> consumerFactory(
            @Value("${spring.kafka.bootstrap-servers:localhost:9092}")
            String bootstrapServers,
            @Value("${spring.kafka.consumer.group-id:ran-control-group}")
            String groupId) {

        Map<String, Object> props = new HashMap<>();

        props.put(
                ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG,
                bootstrapServers
        );

        props.put(
                ConsumerConfig.GROUP_ID_CONFIG,
                groupId
        );

        props.put(
                ConsumerConfig.AUTO_OFFSET_RESET_CONFIG,
                "earliest"
        );

        props.put(
                ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG,
                false
        );

        JsonDeserializer<CongestionEvent> deserializer =
                new JsonDeserializer<>(CongestionEvent.class, false);

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
    public ConcurrentKafkaListenerContainerFactory<String, CongestionEvent>
    kafkaListenerContainerFactory(
            ConsumerFactory<String, CongestionEvent> consumerFactory) {

        ConcurrentKafkaListenerContainerFactory<String, CongestionEvent>
                factory = new ConcurrentKafkaListenerContainerFactory<>();

        factory.setConsumerFactory(consumerFactory);

        factory.setCommonErrorHandler(
                new DefaultErrorHandler(
                        new FixedBackOff(1000L, 3L)
                )
        );

        return factory;
    }

    @Bean
    public ProducerFactory<String, Object> producerFactory(
            @Value("${spring.kafka.bootstrap-servers:localhost:9092}")
            String bootstrapServers) {

        Map<String, Object> props = new HashMap<>();

        props.put(
                ProducerConfig.BOOTSTRAP_SERVERS_CONFIG,
                bootstrapServers
        );

        props.put(ProducerConfig.ACKS_CONFIG, "all");

        props.put(
                ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG,
                true
        );

        return new DefaultKafkaProducerFactory<>(
                props,
                new StringSerializer(),
                new JsonSerializer<>()
        );
    }

    @Bean
    public KafkaTemplate<String, Object> kafkaTemplate(
            ProducerFactory<String, Object> producerFactory) {

        return new KafkaTemplate<>(producerFactory);
    }
}
EOF

# ------------------------------------------------------------
# 5. RanControlApplication.java
# ------------------------------------------------------------

cat > "$PKG/RanControlApplication.java" <<'EOF'
package org.example.ran.control;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(
        scanBasePackages = {
                "org.example.ran.control",
                "org.onap.policy.ran.common"
        }
)
public class RanControlApplication {

    public static void main(String[] args) {
        SpringApplication.run(
                RanControlApplication.class,
                args
        );
    }
}
EOF

# ------------------------------------------------------------
# 6. application.yml
# ------------------------------------------------------------

cat > "$BASE/src/main/resources/application.yml" <<'EOF'
spring:
  application:
    name: ran-control-service

  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}
    consumer:
      group-id: ${KAFKA_CONSUMER_GROUP:ran-control-group}
      auto-offset-reset: earliest
      enable-auto-commit: false

server:
  port: ${SERVER_PORT:8082}

management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus
  endpoint:
    health:
      probes:
        enabled: true

ran:
  kafka:
    topics:
      congestion: ${RAN_CONGESTION_TOPIC:ran.congestion}
      action: ${RAN_ACTION_TOPIC:ran.action}

  control:
    simulation-mode: ${RAN_CONTROL_SIMULATION_MODE:true}
    thresholds:
      steering-prb: ${RAN_STEERING_PRB_THRESHOLD:75.0}
      scale-out-prb: ${RAN_SCALE_OUT_PRB_THRESHOLD:90.0}
      critical-prb: ${RAN_CRITICAL_PRB_THRESHOLD:97.0}
    cooldown-seconds: ${RAN_CONTROL_COOLDOWN_SECONDS:30}
    action-ttl-seconds: ${RAN_CONTROL_ACTION_TTL_SECONDS:60}

logging:
  level:
    root: INFO
    org.example.ran.control: INFO
EOF

# ------------------------------------------------------------
# 7. pom.xml
# ------------------------------------------------------------

cat > "$BASE/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.example.ran</groupId>
        <artifactId>ran-congestion-control-platform</artifactId>
        <version>1.0.0-SNAPSHOT</version>
        <relativePath>../pom.xml</relativePath>
    </parent>

    <artifactId>ran-control-service</artifactId>
    <name>RAN Control Service</name>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>org.example.ran</groupId>
            <artifactId>ran-common</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.kafka</groupId>
            <artifactId>spring-kafka</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-registry-prometheus</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
EOF

# ------------------------------------------------------------
# 8. README.md
# ------------------------------------------------------------

cat > "$BASE/README.md" <<'EOF'
# RAN Control Service

## Responsabilités

Le service consomme les événements du topic `ran.congestion`,
évalue les règles de contrôle et publie les commandes sur
`ran.action`.

## Politique de contrôle

- NORMAL : aucune action.
- LOW et MEDIUM : observation, aucune action.
- Confiance inférieure à 0,50 : aucune action.
- PRB supérieur ou égal au seuil de steering : traffic steering.
- PRB supérieur ou égal au seuil de scale-out : demande de capacité.
- PRB supérieur ou égal au seuil critique : traffic steering prioritaire.
- Cooldown actif : aucune nouvelle action.

Les seuils sont configurables. Ils doivent être calibrés avec
les données réelles du réseau et les contraintes de QoS.

## Configuration

| Variable | Valeur par défaut |
|---|---|
| KAFKA_BOOTSTRAP_SERVERS | localhost:9092 |
| KAFKA_CONSUMER_GROUP | ran-control-group |
| RAN_CONGESTION_TOPIC | ran.congestion |
| RAN_ACTION_TOPIC | ran.action |
| RAN_CONTROL_SIMULATION_MODE | true |
| RAN_STEERING_PRB_THRESHOLD | 75.0 |
| RAN_SCALE_OUT_PRB_THRESHOLD | 90.0 |
| RAN_CRITICAL_PRB_THRESHOLD | 97.0 |
| RAN_CONTROL_COOLDOWN_SECONDS | 30 |
| RAN_CONTROL_ACTION_TTL_SECONDS | 60 |
| SERVER_PORT | 8082 |

Les seuils doivent respecter :
steering <= scale-out <= critical.

## Sécurité

Le mode simulation est activé par défaut.

Le mode PARTICIPANT ne garantit pas, à lui seul, la sécurité
d'une action réelle. Chaque participant doit contrôler les
autorisations, la cible, les paramètres, les limites opérationnelles
et l'expiration de la commande.

## Fiabilité et limites

Le cooldown est conservé en mémoire et n'est pas partagé entre
plusieurs instances.

La publication Kafka est asynchrone. Pour un déploiement de
production, prévoir une gestion durable des erreurs, une dead-letter
topic, l'idempotence métier et une coordination fiable entre
publication et validation des offsets.

## Observabilité

Les endpoints Actuator configurés sont :

- `/actuator/health`
- `/actuator/info`
- `/actuator/prometheus`
EOF

echo "PARTIE 6B/8 : ran-control-service généré."
echo "Aucune compilation ou activation de service exécutée."


#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# RAN Congestion Control Platform
# Partie 7A/8 — 1re moitié sur 2
# Service d'exécution des actions RAN
#
# Génération de fichiers uniquement.
# Aucun service n'est démarré.
# ============================================================

BASE="ran-action-service"
PKG="$BASE/src/main/java/org/example/ran/action"

mkdir -p \
  "$PKG/consumer" \
  "$PKG/service" \
  "$PKG/participant" \
  "$PKG/config" \
  "$BASE/src/main/resources" \
  "$BASE/src/test/java/org/example/ran/action/service"

# ------------------------------------------------------------
# 1. ActionExecutionResult.java
# ------------------------------------------------------------

cat > "$PKG/service/ActionExecutionResult.java" <<'EOF'
package org.example.ran.action.service;

import java.time.Instant;
import java.util.Objects;

/**
 * Résultat de l'exécution ou du rejet d'une action.
 */
public record ActionExecutionResult(
        String actionId,
        String status,
        String message,
        Instant timestamp,
        boolean simulated
) {
    public ActionExecutionResult {
        if (actionId == null || actionId.isBlank()) {
            throw new IllegalArgumentException(
                    "actionId must not be blank");
        }

        if (status == null || status.isBlank()) {
            throw new IllegalArgumentException(
                    "status must not be blank");
        }

        message = Objects.requireNonNullElse(message, "");
        timestamp = Objects.requireNonNullElseGet(
                timestamp, Instant::now);
    }

    public static ActionExecutionResult success(
            String actionId,
            String message,
            boolean simulated) {

        return new ActionExecutionResult(
                actionId,
                "SUCCEEDED",
                message,
                Instant.now(),
                simulated
        );
    }

    public static ActionExecutionResult rejected(
            String actionId,
            String message) {

        return new ActionExecutionResult(
                actionId,
                "REJECTED",
                message,
                Instant.now(),
                true
        );
    }

    public static ActionExecutionResult expired(String actionId) {
        return new ActionExecutionResult(
                actionId,
                "EXPIRED",
                "Action expirée avant son exécution",
                Instant.now(),
                true
        );
    }
}
EOF

# ------------------------------------------------------------
# 2. ActionParticipant.java
# ------------------------------------------------------------

cat > "$PKG/participant/ActionParticipant.java" <<'EOF'
package org.example.ran.action.participant;

import org.onap.policy.ran.common.ActionEvent;
import org.example.ran.action.service.ActionExecutionResult;

/**
 * Interface d'intégration des exécutants d'actions.
 *
 * Chaque participant doit vérifier les paramètres et les
 * autorisations avant toute opération externe.
 */
public interface ActionParticipant {

    boolean supports(ActionEvent action);

    ActionExecutionResult execute(ActionEvent action);
}
EOF

# ------------------------------------------------------------
# 3. SimulatedActionParticipant.java
# ------------------------------------------------------------

cat > "$PKG/participant/SimulatedActionParticipant.java" <<'EOF'
package org.example.ran.action.participant;

import org.example.ran.action.service.ActionExecutionResult;
import org.onap.policy.ran.common.ActionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.Set;

/**
 * Participant de démonstration.
 *
 * Il journalise la commande sans contacter un réseau réel,
 * Kubernetes, un contrôleur O-RAN ou un équipement RAN.
 */
@Component
@ConditionalOnProperty(
        name = "ran.action.simulation-mode",
        havingValue = "true",
        matchIfMissing = true
)
public class SimulatedActionParticipant implements ActionParticipant {

    private static final Logger LOG =
            LoggerFactory.getLogger(SimulatedActionParticipant.class);

    private static final Set<ActionEvent.ActionType> SUPPORTED =
            Set.of(
                    ActionEvent.ActionType.TRAFFIC_STEERING,
                    ActionEvent.ActionType.SCALE_OUT,
                    ActionEvent.ActionType.SCALE_IN,
                    ActionEvent.ActionType.NETWORK_CONFIGURATION,
                    ActionEvent.ActionType.NO_OP
            );

    @Override
    public boolean supports(ActionEvent action) {
        return action != null
                && SUPPORTED.contains(action.actionType());
    }

    @Override
    public ActionExecutionResult execute(ActionEvent action) {
        if (!supports(action)) {
            return ActionExecutionResult.rejected(
                    action == null ? "unknown" : action.actionId(),
                    "Type d'action non pris en charge"
            );
        }

        if (action.actionType() == ActionEvent.ActionType.NO_OP) {
            LOG.info(
                    "Simulation NO_OP: actionId={}, cell={}, reason={}",
                    action.actionId(),
                    action.cellId(),
                    action.reason()
            );

            return ActionExecutionResult.success(
                    action.actionId(),
                    "Aucune modification réseau demandée",
                    true
            );
        }

        LOG.info(
                "SIMULATION ONLY: actionId={}, type={}, node={}, cell={}, parameters={}",
                action.actionId(),
                action.actionType(),
                action.ranNodeId(),
                action.cellId(),
                action.parameters()
        );

        return ActionExecutionResult.success(
                action.actionId(),
                "Action simulée ; aucune modification réseau effectuée",
                true
        );
    }
}
EOF

# ------------------------------------------------------------
# 4. ActionExecutionService.java
# ------------------------------------------------------------

cat > "$PKG/service/ActionExecutionService.java" <<'EOF'
package org.example.ran.action;

import org.example.ran.action.participant.ActionParticipant;
import org.onap.policy.ran.common.ActionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Valide et distribue les commandes aux participants.
 *
 * Le registre d'idempotence est en mémoire. Il convient à une
 * démonstration mono-instance, mais doit être remplacé par un
 * stockage durable pour un environnement de production.
 */
@Service
public class ActionExecutionService {

    private static final Logger LOG =
            LoggerFactory.getLogger(ActionExecutionService.class);

    private final List<ActionParticipant> participants;
    private final boolean simulationMode;
    private final Clock clock;

    private final Set<String> processedActionIds =
            ConcurrentHashMap.newKeySet();

    public ActionExecutionService(
            List<ActionParticipant> participants,
            @Value("${ran.action.simulation-mode:true}")
            boolean simulationMode) {

        this(participants, simulationMode, Clock.systemUTC());
    }

    ActionExecutionService(
            List<ActionParticipant> participants,
            boolean simulationMode,
            Clock clock) {

        this.participants = List.copyOf(
                Objects.requireNonNull(participants, "participants"));

        this.simulationMode = simulationMode;
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    public ActionExecutionResult execute(ActionEvent action) {
        if (action == null) {
            throw new IllegalArgumentException(
                    "Action must not be null");
        }

        Instant now = clock.instant();

        if (action.actionId().isBlank()) {
            return ActionExecutionResult.rejected(
                    "unknown",
                    "Identifiant d'action absent"
            );
        }

        if (action.isTerminal()) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "L'action possède déjà un statut terminal"
            );
        }

        if (action.isExpired(now)) {
            return ActionExecutionResult.expired(action.actionId());
        }

        if (!processedActionIds.add(action.actionId())) {
            LOG.warn(
                    "Duplicate action ignored: actionId={}",
                    action.actionId()
            );

            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "Action déjà traitée par cette instance"
            );
        }

        if (action.actionType() == ActionEvent.ActionType.NO_OP) {
            return ActionExecutionResult.success(
                    action.actionId(),
                    "Aucune action opérationnelle requise",
                    true
            );
        }

        /*
         * Aucune intégration réelle n'est fournie dans cette partie.
         * Le mode simulation est obligatoire tant qu'un adaptateur
         * réseau contrôlé n'a pas été explicitement développé.
         */
        if (!simulationMode) {
            LOG.error(
                    "Real execution requested but no production adapter is configured: actionId={}",
                    action.actionId()
            );

            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "Exécution réelle indisponible : aucun adaptateur de production configuré"
            );
        }

        for (ActionParticipant participant : participants) {
            if (participant.supports(action)) {
                try {
                    return participant.execute(action);
                } catch (RuntimeException exception) {
                    LOG.error(
                            "Participant failed: actionId={}",
                            action.actionId(),
                            exception
                    );

                    return new ActionExecutionResult(
                            action.actionId(),
                            "FAILED",
                            "Échec du participant : "
                                    + exception.getClass().getSimpleName(),
                            clock.instant(),
                            true
                    );
                }
            }
        }

        LOG.warn(
                "No participant supports action type {}",
                action.actionType()
        );

        return ActionExecutionResult.rejected(
                action.actionId(),
                "Aucun participant compatible avec ce type d'action"
        );
    }
}
EOF

echo "PARTIE 7A/8 — première moitié générée."


# ============================================================
# RAN Congestion Control Platform
# Partie 7A/8 — 2e moitié sur 2
# Complément du ran-action-service
#
# Génération de fichiers uniquement.
# Aucun service n'est démarré.
# ============================================================

BASE="ran-action-service"
PKG="$BASE/src/main/java/org/example/ran/action"

mkdir -p \
  "$PKG/consumer" \
  "$PKG/config" \
  "$BASE/src/main/resources" \
  "$BASE/src/test/java/org/example/ran/action/service"

# ------------------------------------------------------------
# 5. ActionConsumer.java
# ------------------------------------------------------------

cat > "$PKG/consumer/ActionConsumer.java" <<'EOF'
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
EOF

# ------------------------------------------------------------
# 6. KafkaConfig.java
# ------------------------------------------------------------

cat > "$PKG/config/KafkaConfig.java" <<'EOF'
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
EOF

# ------------------------------------------------------------
# 7. RanActionApplication.java
# ------------------------------------------------------------

cat > "$PKG/RanActionApplication.java" <<'EOF'
package org.example.ran.action;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(
        scanBasePackages = {
                "org.example.ran.action",
                "org.onap.policy.ran.common"
        }
)
public class RanActionApplication {

    public static void main(String[] args) {
        SpringApplication.run(
                RanActionApplication.class,
                args
        );
    }
}
EOF

# ------------------------------------------------------------
# 8. application.yml
# ------------------------------------------------------------

cat > "$BASE/src/main/resources/application.yml" <<'EOF'
spring:
  application:
    name: ran-action-service

  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}
    consumer:
      group-id: ${KAFKA_CONSUMER_GROUP:ran-action-group}
      auto-offset-reset: earliest
      enable-auto-commit: false

server:
  port: ${SERVER_PORT:8083}

management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus
  endpoint:
    health:
      probes:
        enabled: true

ran:
  kafka:
    topics:
      action: ${RAN_ACTION_TOPIC:ran.action}

  action:
    simulation-mode: ${RAN_ACTION_SIMULATION_MODE:true}

logging:
  level:
    root: INFO
    org.example.ran.action: INFO
EOF

# ------------------------------------------------------------
# 9. pom.xml
# ------------------------------------------------------------

cat > "$BASE/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.example.ran</groupId>
        <artifactId>ran-congestion-control-platform</artifactId>
        <version>1.0.0-SNAPSHOT</version>
        <relativePath>../pom.xml</relativePath>
    </parent>

    <artifactId>ran-action-service</artifactId>
    <name>RAN Action Service</name>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>org.example.ran</groupId>
            <artifactId>ran-common</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.kafka</groupId>
            <artifactId>spring-kafka</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-registry-prometheus</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
EOF

# ------------------------------------------------------------
# 10. ActionExecutionServiceTest.java
# ------------------------------------------------------------

cat > "$BASE/src/test/java/org/example/ran/action/service/ActionExecutionServiceTest.java" <<'EOF'
package org.example.ran.action.service;

import org.example.ran.action.participant.ActionParticipant;
import org.onap.policy.ran.common.ActionEvent;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class ActionExecutionServiceTest {

    private static final Instant NOW =
            Instant.parse("2026-01-01T12:00:00Z");

    private static ActionEvent createAction(
            ActionEvent.ActionType type,
            Instant expiresAt) {

        return new ActionEvent(
                "action-001",
                "correlation-001",
                "congestion-001",
                NOW,
                "gnb-001",
                "cell-001",
                "default",
                type,
                ActionEvent.ActionStatus.REQUESTED,
                ActionEvent.ActionTarget.SIMULATOR,
                Map.of("mode", "balanced"),
                "test action",
                "unit-test",
                expiresAt
        );
    }

    @Test
    void shouldExecuteActionWithSimulator() {
        ActionParticipant participant = new ActionParticipant() {
            @Override
            public boolean supports(ActionEvent action) {
                return action.actionType()
                        == ActionEvent.ActionType.TRAFFIC_STEERING;
            }

            @Override
            public ActionExecutionResult execute(ActionEvent action) {
                return ActionExecutionResult.success(
                        action.actionId(),
                        "simulated",
                        true
                );
            }
        };

        ActionExecutionService service =
                new ActionExecutionService(
                        List.of(participant),
                        true,
                        Clock.fixed(NOW, ZoneOffset.UTC)
                );

        ActionEvent action = createAction(
                ActionEvent.ActionType.TRAFFIC_STEERING,
                NOW.plusSeconds(60)
        );

        ActionExecutionResult result = service.execute(action);

        assertEquals("SUCCEEDED", result.status());
        assertTrue(result.simulated());
    }

    @Test
    void shouldRejectExpiredAction() {
        ActionExecutionService service =
                new ActionExecutionService(
                        List.of(),
                        true,
                        Clock.fixed(NOW, ZoneOffset.UTC)
                );

        ActionEvent action = createAction(
                ActionEvent.ActionType.TRAFFIC_STEERING,
                NOW.minusSeconds(1)
        );

        ActionExecutionResult result = service.execute(action);

        assertEquals("EXPIRED", result.status());
    }

    @Test
    void shouldIgnoreDuplicateActionId() {
        ActionParticipant participant = new ActionParticipant() {
            @Override
            public boolean supports(ActionEvent action) {
                return action.actionType()
                        == ActionEvent.ActionType.TRAFFIC_STEERING;
            }

            @Override
            public ActionExecutionResult execute(ActionEvent action) {
                return ActionExecutionResult.success(
                        action.actionId(),
                        "simulated",
                        true
                );
            }
        };

        ActionExecutionService service =
                new ActionExecutionService(
                        List.of(participant),
                        true,
                        Clock.fixed(NOW, ZoneOffset.UTC)
                );

        ActionEvent action = createAction(
                ActionEvent.ActionType.TRAFFIC_STEERING,
                NOW.plusSeconds(60)
        );

        ActionExecutionResult first = service.execute(action);
        ActionExecutionResult second = service.execute(action);

        assertEquals("SUCCEEDED", first.status());
        assertEquals("REJECTED", second.status());
    }

    @Test
    void shouldRejectRealExecutionWithoutAdapter() {
        ActionExecutionService service =
                new ActionExecutionService(
                        List.of(),
                        false,
                        Clock.fixed(NOW, ZoneOffset.UTC)
                );

        ActionEvent action = createAction(
                ActionEvent.ActionType.TRAFFIC_STEERING,
                NOW.plusSeconds(60)
        );

        ActionExecutionResult result = service.execute(action);

        assertEquals("REJECTED", result.status());
        assertTrue(result.message().contains("adaptateur"));
    }

    @Test
    void shouldAcceptNoOpWithoutParticipant() {
        ActionExecutionService service =
                new ActionExecutionService(
                        List.of(),
                        true,
                        Clock.fixed(NOW, ZoneOffset.UTC)
                );

        ActionEvent action = createAction(
                ActionEvent.ActionType.NO_OP,
                NOW.plusSeconds(60)
        );

        ActionExecutionResult result = service.execute(action);

        assertEquals("SUCCEEDED", result.status());
        assertTrue(result.simulated());
    }
}
EOF

# ------------------------------------------------------------
# 11. README.md
# ------------------------------------------------------------

cat > "$BASE/README.md" <<'EOF'
# RAN Action Service

## Responsabilités

Le service consomme les commandes Kafka du topic `ran.action`,
valide leur expiration et leur statut, puis les transmet à un
participant compatible.

## Flux

1. Réception d'un ActionEvent.
2. Vérification de l'expiration.
3. Vérification du statut de l'action.
4. Détection d'un identifiant déjà traité par l'instance.
5. Traitement direct des commandes NO_OP.
6. Exécution par un participant en mode simulation.
7. Journalisation du résultat.

## Configuration

| Variable | Valeur par défaut |
|---|---|
| KAFKA_BOOTSTRAP_SERVERS | localhost:9092 |
| KAFKA_CONSUMER_GROUP | ran-action-group |
| RAN_ACTION_TOPIC | ran.action |
| RAN_ACTION_SIMULATION_MODE | true |
| SERVER_PORT | 8083 |

## Sécurité

Le mode simulation est activé par défaut.

Aucun adaptateur d'exécution réelle n'est fourni. Lorsque le mode
simulation est désactivé, les actions opérationnelles sont rejetées
tant qu'aucun adaptateur de production n'est implémenté.

Un adaptateur réel devra au minimum vérifier :

- les autorisations du demandeur ;
- l'identité et le périmètre de la cible ;
- le type d'action autorisé ;
- les paramètres et les limites opérationnelles ;
- l'expiration de la commande ;
- les règles de QoS et les mécanismes de retour arrière.

## Idempotence et erreurs

La déduplication est conservée en mémoire et ne résiste pas à un
redémarrage. Une implémentation de production devra utiliser un
registre durable, par exemple une base de données avec contrainte
d'unicité sur actionId.

Le consommateur Kafka utilise une reprise avec délai fixe. Une
dead-letter topic et une stratégie de gestion des erreurs
permanentes devront être ajoutées avant un déploiement critique.

La publication d'un résultat vers un topic Kafka n'est pas encore
implémentée dans cette version : les résultats sont journalisés.

ChatGPT est une IA, et peut se tromper.




Aucun fichier n’a été sélectionnéAucun fichier n’a été sélectionnéAucun fichier n’a été sélectionné
Discussion avec ChatGPT
EOF


# ============================================================
# RAN Congestion Control Platform
# PARTIE 7B/8 — 1/3
# traffic-steering-participant
#
# Génération de fichiers uniquement.
# Aucun service n'est démarré.
# Aucune commande réseau réelle n'est exécutée.
# ============================================================

ROOT="ran-congestion-control-platform"
BASE="$ROOT/traffic-steering-participant"
PKG="$BASE/src/main/java/org/example/ran/action/participant/steering"
TEST="$BASE/src/test/java/org/example/ran/action/participant/steering"

mkdir -p "$PKG" "$TEST"

# ------------------------------------------------------------
# 1. TrafficSteeringParticipant.java
# ------------------------------------------------------------

cat > "$PKG/TrafficSteeringParticipant.java" <<'EOF'
package org.example.ran.action.participant.steering;

import org.example.ran.action.participant.ActionParticipant;
import org.example.ran.action.service.ActionExecutionResult;
import org.onap.policy.ran.common.ActionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.Set;

/**
 * Participant spécialisé dans la simulation du traffic steering.
 *
 * Aucune connexion à un contrôleur RAN n'est effectuée.
 */
@Component
public class TrafficSteeringParticipant implements ActionParticipant {

    private static final Logger LOG =
            LoggerFactory.getLogger(TrafficSteeringParticipant.class);

    private static final Set<String> ALLOWED_MODES =
            Set.of("balanced", "emergency");

    private final Clock clock;

    public TrafficSteeringParticipant() {
        this(Clock.systemUTC());
    }

    TrafficSteeringParticipant(Clock clock) {
        this.clock = clock;
    }

    @Override
    public boolean supports(ActionEvent action) {
        return action != null
                && action.actionType()
                == ActionEvent.ActionType.TRAFFIC_STEERING;
    }

    @Override
    public ActionExecutionResult execute(ActionEvent action) {
        if (!supports(action)) {
            return reject(action, "Type TRAFFIC_STEERING requis");
        }

        if (action.actionId() == null || action.actionId().isBlank()) {
            return reject(action, "Identifiant d'action absent");
        }

        if (action.isTerminal()) {
            return reject(action, "Action déjà dans un état terminal");
        }

        Instant now = clock.instant();

        if (action.isExpired(now)) {
            return ActionExecutionResult.expired(action.actionId());
        }

        Map<String, String> parameters = action.parameters();

        if (parameters == null || parameters.isEmpty()) {
            return reject(action, "Paramètres de steering absents");
        }

        String mode = parameters.get("mode");
        String sourceCell = parameters.get("sourceCell");
        String preserveQos = parameters.get("preserveQos");
        String executionMode = parameters.get("executionMode");

        if (mode == null || !ALLOWED_MODES.contains(mode)) {
            return reject(action, "Mode de steering non autorisé");
        }

        if (action.cellId() == null
                || action.cellId().isBlank()
                || sourceCell == null
                || !sourceCell.equals(action.cellId())) {
            return reject(action, "Cellule source absente ou incohérente");
        }

        if (!"true".equalsIgnoreCase(preserveQos)) {
            return reject(action, "La préservation de la QoS est obligatoire");
        }

        /*
         * Ce participant ne réalise que des simulations.
         * Un mode PARTICIPANT ne doit jamais déclencher une
         * opération réseau depuis cette implémentation.
         */
        if (!"SIMULATION".equals(executionMode)) {
            return reject(
                    action,
                    "Exécution réelle non prise en charge par ce participant"
            );
        }

        LOG.info(
                "TRAFFIC STEERING SIMULÉ : actionId={}, node={}, cell={}, mode={}, preserveQos={}",
                action.actionId(),
                action.ranNodeId(),
                action.cellId(),
                mode,
                preserveQos
        );

        return ActionExecutionResult.success(
                action.actionId(),
                "Rééquilibrage simulé ; aucune modification réseau effectuée",
                true
        );
    }

    private ActionExecutionResult reject(
            ActionEvent action,
            String message) {

        String actionId = action == null
                || action.actionId() == null
                || action.actionId().isBlank()
                ? "unknown"
                : action.actionId();

        LOG.warn(
                "Traffic steering rejeté : actionId={}, raison={}",
                actionId,
                message
        );

        return ActionExecutionResult.rejected(actionId, message);
    }
}
EOF

# ------------------------------------------------------------
# 2. TrafficSteeringParticipantTest.java
# ------------------------------------------------------------

cat > "$TEST/TrafficSteeringParticipantTest.java" <<'EOF'
package org.example.ran.action.participant.steering;

import org.example.ran.action.service.ActionExecutionResult;
import org.junit.jupiter.api.Test;
import org.onap.policy.ran.common.ActionEvent;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class TrafficSteeringParticipantTest {

    private static final Instant NOW =
            Instant.parse("2026-01-01T12:00:00Z");

    private TrafficSteeringParticipant participant() {
        return new TrafficSteeringParticipant(
                Clock.fixed(NOW, ZoneOffset.UTC)
        );
    }

    private ActionEvent action(
            Map<String, String> parameters,
            Instant expiresAt) {

        return new ActionEvent(
                "steering-001",
                "correlation-001",
                "congestion-001",
                NOW,
                "gnb-001",
                "cell-001",
                "default",
                ActionEvent.ActionType.TRAFFIC_STEERING,
                ActionEvent.ActionStatus.REQUESTED,
                ActionEvent.ActionTarget.TRAFFIC_STEERING_PARTICIPANT,
                parameters,
                "Test de steering",
                "ran-control-service",
                expiresAt
        );
    }

    @Test
    void shouldSupportOnlyTrafficSteering() {
        TrafficSteeringParticipant participant = participant();

        ActionEvent action = action(
                Map.of(),
                NOW.plusSeconds(60)
        );

        assertTrue(participant.supports(action));
        assertFalse(participant.supports(null));
    }

    @Test
    void shouldSimulateValidBalancedSteering() {
        TrafficSteeringParticipant participant = participant();

        ActionEvent action = action(
                Map.of(
                        "mode", "balanced",
                        "sourceCell", "cell-001",
                        "preserveQos", "true",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        ActionExecutionResult result = participant.execute(action);

        assertEquals("SUCCEEDED", result.status());
        assertTrue(result.simulated());
    }

    @Test
    void shouldRejectInvalidMode() {
        TrafficSteeringParticipant participant = participant();

        ActionEvent action = action(
                Map.of(
                        "mode", "unrestricted",
                        "sourceCell", "cell-001",
                        "preserveQos", "true",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        assertEquals(
                "REJECTED",
                participant.execute(action).status()
        );
    }

    @Test
    void shouldRejectInconsistentSourceCell() {
        TrafficSteeringParticipant participant = participant();

        ActionEvent action = action(
                Map.of(
                        "mode", "balanced",
                        "sourceCell", "cell-999",
                        "preserveQos", "true",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        assertEquals(
                "REJECTED",
                participant.execute(action).status()
        );
    }

    @Test
    void shouldRejectRealExecutionMode() {
        TrafficSteeringParticipant participant = participant();

        ActionEvent action = action(
                Map.of(
                        "mode", "emergency",
                        "sourceCell", "cell-001",
                        "preserveQos", "true",
                        "executionMode", "PARTICIPANT"
                ),
                NOW.plusSeconds(60)
        );

        ActionExecutionResult result = participant.execute(action);

        assertEquals("REJECTED", result.status());
        assertTrue(result.simulated());
    }

    @Test
    void shouldRejectExpiredAction() {
        TrafficSteeringParticipant participant = participant();

        ActionEvent action = action(
                Map.of(
                        "mode", "balanced",
                        "sourceCell", "cell-001",
                        "preserveQos", "true",
                        "executionMode", "SIMULATION"
                ),
                NOW.minusSeconds(1)
        );

        assertEquals(
                "EXPIRED",
                participant.execute(action).status()
        );
    }
}
EOF

# ------------------------------------------------------------
# 3. pom.xml
# ------------------------------------------------------------

cat > "$BASE/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.example.ran</groupId>
        <artifactId>ran-congestion-control-platform</artifactId>
        <version>1.0.0-SNAPSHOT</version>
        <relativePath>../pom.xml</relativePath>
    </parent>

    <artifactId>traffic-steering-participant</artifactId>
    <name>Traffic Steering Participant</name>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>org.example.ran</groupId>
            <artifactId>ran-action-service</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-context</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

</project>
EOF

# ------------------------------------------------------------
# 4. README.md
# ------------------------------------------------------------

cat > "$BASE/README.md" <<'EOF'
# Traffic Steering Participant

## Responsabilités

Ce module implémente l'interface `ActionParticipant` du
`ran-action-service` pour traiter les commandes
`TRAFFIC_STEERING`.

## Validations

- Type d'action compatible.
- Identifiant d'action présent.
- Action non terminale et non expirée.
- Mode `balanced` ou `emergency`.
- Cellule source cohérente avec la commande.
- Paramètre `preserveQos=true`.
- Mode d'exécution `SIMULATION`.

## Sécurité

Ce participant ne contacte aucun contrôleur réseau et ne modifie
aucune configuration RAN. Les commandes en mode `PARTICIPANT`
sont rejetées.

## Intégration

Le module dépend de `ran-action-service` pour réutiliser
`ActionParticipant` et `ActionExecutionResult`.

Le package Java appartient à `org.example.ran.action` afin
de rester dans le périmètre de scan Spring Boot de
`RanActionApplication`.

Le module doit être déclaré dans le POM parent. Il doit également
être présent dans le classpath de `ran-action-service` pour que
Spring puisse découvrir ce participant.

## Tests

Les tests couvrent le type d'action, la simulation valide,
les paramètres incorrects, la cellule incohérente, le refus
du mode réel et l'expiration.
EOF

echo "PARTIE 7B/8 — 1/3 générée : traffic-steering-participant."
echo "Aucune compilation ni activation de service exécutée."

# ============================================================
# RAN Congestion Control Platform
# PARTIE 7B/8 — 2/3A
# Moteur du scaling participant
#
# Génération de fichiers uniquement.
# Aucune mise à l'échelle réelle.
# ============================================================

ROOT="ran-congestion-control-platform"
BASE="$ROOT/scaling-participant"
PKG="$BASE/src/main/java/org/example/ran/action/participant/scaling"

mkdir -p "$PKG"

# ------------------------------------------------------------
# 1. ScalingPolicy.java
# ------------------------------------------------------------

cat > "$PKG/ScalingPolicy.java" <<'EOF'
package org.example.ran.action.participant.scaling;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class ScalingPolicy {

    private final int minimumReplicas;
    private final int maximumReplicas;
    private final int maximumStep;

    public ScalingPolicy(
            @Value("${ran.scaling.minimum-replicas:1}")
            int minimumReplicas,
            @Value("${ran.scaling.maximum-replicas:10}")
            int maximumReplicas,
            @Value("${ran.scaling.maximum-step:2}")
            int maximumStep) {

        if (minimumReplicas < 0) {
            throw new IllegalArgumentException(
                    "minimumReplicas must be >= 0");
        }

        if (maximumReplicas < 1
                || maximumReplicas < minimumReplicas) {
            throw new IllegalArgumentException(
                    "Invalid replica limits");
        }

        if (maximumStep < 1) {
            throw new IllegalArgumentException(
                    "maximumStep must be >= 1");
        }

        this.minimumReplicas = minimumReplicas;
        this.maximumReplicas = maximumReplicas;
        this.maximumStep = maximumStep;
    }

    public int minimumReplicas() {
        return minimumReplicas;
    }

    public int maximumReplicas() {
        return maximumReplicas;
    }

    public int maximumStep() {
        return maximumStep;
    }

    public boolean isValidTarget(int replicas) {
        return replicas >= minimumReplicas
                && replicas <= maximumReplicas;
    }

    public boolean isValidStep(int step) {
        return step >= 1 && step <= maximumStep;
    }
}
EOF

# ------------------------------------------------------------
# 2. ScalingParticipant.java
# ------------------------------------------------------------

cat > "$PKG/ScalingParticipant.java" <<'EOF'
package org.example.ran.action.participant.scaling;

import org.example.ran.action.participant.ActionParticipant;
import org.example.ran.action.service.ActionExecutionResult;
import org.onap.policy.ran.common.ActionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.Objects;

@Component
public class ScalingParticipant implements ActionParticipant {

    private static final Logger LOG =
            LoggerFactory.getLogger(ScalingParticipant.class);

    private final ScalingPolicy policy;
    private final boolean simulationMode;
    private final Clock clock;

    public ScalingParticipant(
            ScalingPolicy policy,
            @Value("${ran.scaling.simulation-mode:true}")
            boolean simulationMode) {

        this(policy, simulationMode, Clock.systemUTC());
    }

    ScalingParticipant(
            ScalingPolicy policy,
            boolean simulationMode,
            Clock clock) {

        this.policy = Objects.requireNonNull(policy, "policy");
        this.simulationMode = simulationMode;
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    @Override
    public boolean supports(ActionEvent action) {
        return action != null
                && (action.actionType()
                    == ActionEvent.ActionType.SCALE_OUT
                    || action.actionType()
                    == ActionEvent.ActionType.SCALE_IN);
    }

    @Override
    public ActionExecutionResult execute(ActionEvent action) {
        if (!supports(action)) {
            return reject(action, "Type SCALE_OUT ou SCALE_IN requis");
        }

        if (action.actionId() == null || action.actionId().isBlank()) {
            return reject(action, "Identifiant d'action absent");
        }

        if (action.isTerminal()) {
            return reject(action, "Action déjà terminale");
        }

        Instant now = clock.instant();

        if (action.isExpired(now)) {
            return ActionExecutionResult.expired(action.actionId());
        }

        if (!simulationMode) {
            return reject(
                    action,
                    "Exécution réelle indisponible : aucun adaptateur configuré"
            );
        }

        Map<String, String> parameters = action.parameters();

        if (parameters == null || parameters.isEmpty()) {
            return reject(action, "Paramètres de scaling absents");
        }

        if (!"SIMULATION".equals(parameters.get("executionMode"))) {
            return reject(action, "Le mode SIMULATION est obligatoire");
        }

        String component = parameters.get("component");

        if (component == null || component.isBlank()) {
            return reject(action, "Composant cible absent");
        }

        String expectedDirection =
                action.actionType() == ActionEvent.ActionType.SCALE_OUT
                        ? "out"
                        : "in";

        if (!expectedDirection.equals(parameters.get("direction"))) {
            return reject(action, "Direction incompatible avec l'action");
        }

        final int requestedReplicas;

        try {
            requestedReplicas = Integer.parseInt(
                    parameters.getOrDefault("requestedReplicas", "")
            );
        } catch (NumberFormatException exception) {
            return reject(action, "requestedReplicas doit être un entier");
        }

        if (!policy.isValidTarget(requestedReplicas)) {
            return reject(
                    action,
                    "Nombre de réplicas hors des limites configurées"
            );
        }

        LOG.info(
                "SCALING SIMULÉ : actionId={}, component={}, direction={}, targetReplicas={}",
                action.actionId(),
                component,
                expectedDirection,
                requestedReplicas
        );

        return ActionExecutionResult.success(
                action.actionId(),
                "Mise à l'échelle simulée vers "
                        + requestedReplicas
                        + " réplicas pour "
                        + component
                        + " ; aucune modification réelle effectuée",
                true
        );
    }

    private ActionExecutionResult reject(
            ActionEvent action,
            String message) {

        String actionId = action == null
                || action.actionId() == null
                || action.actionId().isBlank()
                ? "unknown"
                : action.actionId();

        LOG.warn(
                "Scaling rejeté : actionId={}, raison={}",
                actionId,
                message
        );

        return ActionExecutionResult.rejected(actionId, message);
    }
}
EOF

echo "PARTIE 7B/8 — 2/3A générée : moteur de scaling."
echo "Aucune compilation ni mise à l'échelle réelle exécutée."

# ============================================================
# PARTIE 7B/8 — 2/3B
# Configuration, tests et documentation du moteur de scaling
# ============================================================

# ============================================================
# RAN Congestion Control Platform
# PARTIE 7B/8 — 2/3B
# Configuration, tests et documentation
# ============================================================

ROOT="ran-congestion-control-platform"
BASE="$ROOT/scaling-participant"
PKG="$BASE/src/main/java/org/example/ran/action/participant/scaling"
TEST="$BASE/src/test/java/org/example/ran/action/participant/scaling"

mkdir -p "$PKG" "$TEST" "$BASE/src/main/resources"

# ------------------------------------------------------------
# 3. application.yml
# ------------------------------------------------------------

cat > "$BASE/src/main/resources/application.yml" <<'EOF'
spring:
  application:
    name: scaling-participant

ran:
  scaling:
    simulation-mode: ${RAN_SCALING_SIMULATION_MODE:true}
    minimum-replicas: ${RAN_SCALING_MINIMUM_REPLICAS:1}
    maximum-replicas: ${RAN_SCALING_MAXIMUM_REPLICAS:10}
    maximum-step: ${RAN_SCALING_MAXIMUM_STEP:2}
EOF

# ------------------------------------------------------------
# 4. ScalingParticipantTest.java
# ------------------------------------------------------------

cat > "$TEST/ScalingParticipantTest.java" <<'EOF'
package org.example.ran.action.participant.scaling;

import org.example.ran.action.service.ActionExecutionResult;
import org.junit.jupiter.api.Test;
import org.onap.policy.ran.common.ActionEvent;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class ScalingParticipantTest {

    private static final Instant NOW =
            Instant.parse("2026-01-01T12:00:00Z");

    private ScalingPolicy policy() {
        return new ScalingPolicy(1, 10, 2);
    }

    private ScalingParticipant participant() {
        return new ScalingParticipant(
                policy(),
                true,
                Clock.fixed(NOW, ZoneOffset.UTC)
        );
    }

    private ActionEvent action(
            ActionEvent.ActionType type,
            Map<String, String> parameters,
            Instant expiresAt) {

        return new ActionEvent(
                "scaling-001",
                "correlation-001",
                "congestion-001",
                NOW,
                "gnb-001",
                "cell-001",
                "default",
                type,
                ActionEvent.ActionStatus.REQUESTED,
                ActionEvent.ActionTarget.SCALING_PARTICIPANT,
                parameters,
                "Test de scaling",
                "ran-control-service",
                expiresAt
        );
    }

    @Test
    void shouldSupportScaleOutAndScaleIn() {
        ScalingParticipant participant = participant();

        assertTrue(participant.supports(action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(),
                NOW.plusSeconds(60)
        )));

        assertTrue(participant.supports(action(
                ActionEvent.ActionType.SCALE_IN,
                Map.of(),
                NOW.plusSeconds(60)
        )));

        assertFalse(participant.supports(null));
    }

    @Test
    void shouldSimulateScaleOut() {
        ActionEvent action = action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "component", "ran-capacity",
                        "direction", "out",
                        "requestedReplicas", "3",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        ActionExecutionResult result = participant().execute(action);

        assertEquals("SUCCEEDED", result.status());
        assertTrue(result.simulated());
    }

    @Test
    void shouldRejectTargetAboveMaximum() {
        ActionEvent action = action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "component", "ran-capacity",
                        "direction", "out",
                        "requestedReplicas", "11",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        assertEquals(
                "REJECTED",
                participant().execute(action).status()
        );
    }

    @Test
    void shouldRejectInconsistentDirection() {
        ActionEvent action = action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "component", "ran-capacity",
                        "direction", "in",
                        "requestedReplicas", "3",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        assertEquals(
                "REJECTED",
                participant().execute(action).status()
        );
    }

    @Test
    void shouldRejectMalformedReplicaCount() {
        ActionEvent action = action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "component", "ran-capacity",
                        "direction", "out",
                        "requestedReplicas", "three",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        assertEquals(
                "REJECTED",
                participant().execute(action).status()
        );
    }

    @Test
    void shouldRejectExpiredAction() {
        ActionEvent action = action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "component", "ran-capacity",
                        "direction", "out",
                        "requestedReplicas", "3",
                        "executionMode", "SIMULATION"
                ),
                NOW.minusSeconds(1)
        );

        assertEquals(
                "EXPIRED",
                participant().execute(action).status()
        );
    }

    @Test
    void shouldRejectRealExecution() {
        ScalingParticipant realModeParticipant =
                new ScalingParticipant(
                        policy(),
                        false,
                        Clock.fixed(NOW, ZoneOffset.UTC)
                );

        ActionEvent action = action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "component", "ran-capacity",
                        "direction", "out",
                        "requestedReplicas", "3",
                        "executionMode", "SIMULATION"
                ),
                NOW.plusSeconds(60)
        );

        assertEquals(
                "REJECTED",
                realModeParticipant.execute(action).status()
        );
    }

    @Test
    void shouldValidatePolicyLimits() {
        assertThrows(
                IllegalArgumentException.class,
                () -> new ScalingPolicy(1, 0, 2)
        );

        assertThrows(
                IllegalArgumentException.class,
                () -> new ScalingPolicy(1, 10, 0)
        );

        assertTrue(policy().isValidTarget(1));
        assertTrue(policy().isValidTarget(10));
        assertFalse(policy().isValidTarget(11));

        assertTrue(policy().isValidStep(2));
        assertFalse(policy().isValidStep(3));
    }
}
EOF

# ------------------------------------------------------------
# 5. pom.xml
# ------------------------------------------------------------

cat > "$BASE/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.example.ran</groupId>
        <artifactId>ran-congestion-control-platform</artifactId>
        <version>1.0.0-SNAPSHOT</version>
        <relativePath>../pom.xml</relativePath>
    </parent>

    <artifactId>scaling-participant</artifactId>
    <name>Scaling Participant</name>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>org.example.ran</groupId>
            <artifactId>ran-action-service</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-context</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
EOF

# ------------------------------------------------------------
# 6. README.md
# ------------------------------------------------------------

cat > "$BASE/README.md" <<'EOF'
# Scaling Participant

## Responsabilités

Le module implémente ActionParticipant pour les commandes
SCALE_OUT et SCALE_IN.

Il simule une demande de capacité et ne contacte aucun
orchestrateur ou cluster.

## Validations

- Type SCALE_OUT ou SCALE_IN.
- Identifiant présent et action non terminale.
- Expiration de la commande.
- Mode SIMULATION obligatoire.
- Composant cible présent.
- Direction cohérente avec le type d'action.
- Nombre de réplicas entier et dans les limites configurées.

## Configuration

| Variable | Défaut |
|---|---:|
| RAN_SCALING_SIMULATION_MODE | true |
| RAN_SCALING_MINIMUM_REPLICAS | 1 |
| RAN_SCALING_MAXIMUM_REPLICAS | 10 |
| RAN_SCALING_MAXIMUM_STEP | 2 |

## Limites

Le nombre de réplicas demandé est une cible absolue.
Le participant ne connaît pas la capacité actuelle et ne
calcule donc pas le delta réellement appliqué.

maximum-step est validé par ScalingPolicy mais n'est pas
appliqué à une variation réelle, faute d'état de capacité courant.

Le mode réel est rejeté tant qu'un adaptateur de production
n'a pas été développé et sécurisé.

## Intégration

Le module dépend de ran-action-service pour réutiliser
ActionParticipant et ActionExecutionResult.

Le JAR doit être présent dans le classpath de
ran-action-service pour que Spring découvre le participant.
Le module doit également être déclaré dans le POM parent.
EOF

echo "PARTIE 7B/8 — 2/3B générée : configuration, tests et documentation."
echo "Aucune compilation ni activation de service exécutée."

# ============================================================
# RAN Congestion Control Platform
# Partie 7B/8 — 2/3B
# Scaling Participant
#
# Génération de fichiers uniquement.
# Aucun service n'est démarré.
# ============================================================

BASE="scaling-participant"
PKG="$BASE/src/main/java/org/example/ran/scaling"
TEST="$BASE/src/test/java/org/example/ran/scaling"

mkdir -p \
  "$PKG/participant" \
  "$PKG/config" \
  "$TEST/participant" \
  "$BASE/src/main/resources"

# ------------------------------------------------------------
# 1. ScalingParticipant.java
# ------------------------------------------------------------

cat > "$PKG/participant/ScalingParticipant.java" <<'EOF'
package org.example.ran.scaling.participant;

import org.example.ran.action.participant.ActionParticipant;
import org.example.ran.action.service.ActionExecutionResult;
import org.onap.policy.ran.common.ActionEvent;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Set;

/**
 * Participant de mise à l'échelle simulée.
 *
 * Aucune API Kubernetes ou infrastructure réelle n'est appelée.
 */
@Component
public class ScalingParticipant implements ActionParticipant {

    private static final Set<ActionEvent.ActionType> SUPPORTED =
            Set.of(
                    ActionEvent.ActionType.SCALE_OUT,
                    ActionEvent.ActionType.SCALE_IN
            );

    private final boolean simulationMode;
    private final int minReplicas;
    private final int maxReplicas;

    public ScalingParticipant(
            @Value("${ran.scaling.simulation-mode:true}")
            boolean simulationMode,
            @Value("${ran.scaling.min-replicas:1}")
            int minReplicas,
            @Value("${ran.scaling.max-replicas:10}")
            int maxReplicas) {

        if (minReplicas < 1 || maxReplicas < minReplicas) {
            throw new IllegalArgumentException(
                    "Invalid scaling replica limits");
        }

        this.simulationMode = simulationMode;
        this.minReplicas = minReplicas;
        this.maxReplicas = maxReplicas;
    }

    @Override
    public boolean supports(ActionEvent action) {
        return action != null
                && SUPPORTED.contains(action.actionType());
    }

    @Override
    public ActionExecutionResult execute(ActionEvent action) {
        if (!supports(action)) {
            return ActionExecutionResult.rejected(
                    action == null ? "unknown" : action.actionId(),
                    "Type d'action incompatible avec ScalingParticipant"
            );
        }

        if (!simulationMode) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "Exécution réelle indisponible : aucun adaptateur de scaling configuré"
            );
        }

        Map<String, String> parameters = action.parameters();

        String direction = action.actionType()
                == ActionEvent.ActionType.SCALE_OUT ? "out" : "in";

        String configuredDirection = parameters.get("direction");

        if (configuredDirection != null
                && !configuredDirection.equalsIgnoreCase(direction)) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "La direction demandée ne correspond pas au type d'action"
            );
        }

        int requestedReplicas;

        try {
            requestedReplicas = Integer.parseInt(
                    parameters.getOrDefault("requestedReplicas", "1")
            );
        } catch (NumberFormatException exception) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "requestedReplicas doit être un entier"
            );
        }

        if (requestedReplicas < minReplicas
                || requestedReplicas > maxReplicas) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "Nombre de réplicas hors des limites autorisées"
            );
        }

        String component = parameters.getOrDefault(
                "component", "ran-capacity");

        if (component.isBlank()) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "Le composant cible ne peut pas être vide"
            );
        }

        return ActionExecutionResult.success(
                action.actionId(),
                "Mise à l'échelle simulée : direction="
                        + direction
                        + ", component="
                        + component
                        + ", requestedReplicas="
                        + requestedReplicas
                        + ", limites=["
                        + minReplicas
                        + ","
                        + maxReplicas
                        + "] ; aucune infrastructure modifiée",
                true
        );
    }
}
EOF

# ------------------------------------------------------------
# 2. ScalingParticipantApplication.java
# ------------------------------------------------------------

cat > "$PKG/ScalingParticipantApplication.java" <<'EOF'
package org.example.ran.scaling;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(
        scanBasePackages = {
                "org.example.ran.scaling"
        }
)
public class ScalingParticipantApplication {

    public static void main(String[] args) {
        SpringApplication.run(
                ScalingParticipantApplication.class,
                args
        );
    }
}
EOF

# ------------------------------------------------------------
# 3. application.yml
# ------------------------------------------------------------

cat > "$BASE/src/main/resources/application.yml" <<'EOF'
spring:
  application:
    name: scaling-participant

server:
  port: ${SERVER_PORT:8085}

management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus
  endpoint:
    health:
      probes:
        enabled: true

ran:
  scaling:
    simulation-mode: ${RAN_SCALING_SIMULATION_MODE:true}
    min-replicas: ${RAN_SCALING_MIN_REPLICAS:1}
    max-replicas: ${RAN_SCALING_MAX_REPLICAS:10}

logging:
  level:
    root: INFO
    org.example.ran.scaling: INFO
EOF

# ------------------------------------------------------------
# 4. pom.xml
# ------------------------------------------------------------

cat > "$BASE/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.example.ran</groupId>
        <artifactId>ran-congestion-control-platform</artifactId>
        <version>1.0.0-SNAPSHOT</version>
        <relativePath>../pom.xml</relativePath>
    </parent>

    <artifactId>scaling-participant</artifactId>
    <name>Scaling Participant</name>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>org.example.ran</groupId>
            <artifactId>ran-common</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.example.ran</groupId>
            <artifactId>ran-action-service</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-configuration-processor</artifactId>
            <optional>true</optional>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
EOF

# ------------------------------------------------------------
# 5. ScalingParticipantTest.java
# ------------------------------------------------------------

cat > "$TEST/participant/ScalingParticipantTest.java" <<'EOF'
package org.example.ran.scaling.participant;

import org.example.ran.action.service.ActionExecutionResult;
import org.onap.policy.ran.common.ActionEvent;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class ScalingParticipantTest {

    private ActionEvent action(
            ActionEvent.ActionType type,
            Map<String, String> parameters) {

        Instant now = Instant.parse("2026-01-01T12:00:00Z");

        return new ActionEvent(
                "action-scale-001",
                "correlation-001",
                "congestion-001",
                now,
                "gnb-001",
                "cell-001",
                "default",
                type,
                ActionEvent.ActionStatus.REQUESTED,
                ActionEvent.ActionTarget.SCALING_PARTICIPANT,
                parameters,
                "test scaling",
                "unit-test",
                now.plusSeconds(60)
        );
    }

    @Test
    void supportsScaleOutAndScaleIn() {
        ScalingParticipant participant =
                new ScalingParticipant(true, 1, 10);

        assertTrue(participant.supports(action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of()
        )));

        assertTrue(participant.supports(action(
                ActionEvent.ActionType.SCALE_IN,
                Map.of()
        )));

        assertFalse(participant.supports(action(
                ActionEvent.ActionType.NO_OP,
                Map.of()
        )));
    }

    @Test
    void simulatesScaleOutWithinConfiguredLimits() {
        ScalingParticipant participant =
                new ScalingParticipant(true, 1, 10);

        ActionExecutionResult result = participant.execute(action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "component", "ran-capacity",
                        "direction", "out",
                        "requestedReplicas", "3"
                )
        ));

        assertEquals("SUCCEEDED", result.status());
        assertTrue(result.simulated());
        assertTrue(result.message().contains("requestedReplicas=3"));
    }

    @Test
    void rejectsReplicaCountOutsideLimits() {
        ScalingParticipant participant =
                new ScalingParticipant(true, 1, 5);

        ActionExecutionResult result = participant.execute(action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of("requestedReplicas", "8")
        ));

        assertEquals("REJECTED", result.status());
    }

    @Test
    void rejectsInvalidReplicaCount() {
        ScalingParticipant participant =
                new ScalingParticipant(true, 1, 10);

        ActionExecutionResult result = participant.execute(action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of("requestedReplicas", "abc")
        ));

        assertEquals("REJECTED", result.status());
    }

    @Test
    void rejectsRealExecutionWithoutAdapter() {
        ScalingParticipant participant =
                new ScalingParticipant(false, 1, 10);

        ActionExecutionResult result = participant.execute(action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of("requestedReplicas", "2")
        ));

        assertEquals("REJECTED", result.status());
        assertFalse(result.message().isBlank());
    }

    @Test
    void rejectsMismatchedDirection() {
        ScalingParticipant participant =
                new ScalingParticipant(true, 1, 10);

        ActionExecutionResult result = participant.execute(action(
                ActionEvent.ActionType.SCALE_OUT,
                Map.of(
                        "direction", "in",
                        "requestedReplicas", "2"
                )
        ));

        assertEquals("REJECTED", result.status());
    }

    @Test
    void rejectsInvalidReplicaLimits() {
        assertThrows(
                IllegalArgumentException.class,
                () -> new ScalingParticipant(true, 5, 2)
        );
    }
}
EOF

# ------------------------------------------------------------
# 6. README.md
# ------------------------------------------------------------

cat > "$BASE/README.md" <<'EOF'
# Scaling Participant

## Responsabilités

Ce module fournit un participant spécialisé dans les demandes
de mise à l'échelle `SCALE_OUT` et `SCALE_IN`.

## Fonctionnement

- Vérification du type d'action.
- Vérification de la direction demandée.
- Validation du nombre de réplicas.
- Application de limites configurables.
- Simulation du résultat sans modifier une infrastructure.

## Configuration

| Variable | Valeur par défaut |
|---|---|
| SERVER_PORT | 8085 |
| RAN_SCALING_SIMULATION_MODE | true |
| RAN_SCALING_MIN_REPLICAS | 1 |
| RAN_SCALING_MAX_REPLICAS | 10 |

## Sécurité

Le mode simulation est activé par défaut.

Désactiver le mode simulation ne déclenche aucune mise à l'échelle
réelle : en l'absence d'un adaptateur de production, la demande
est rejetée.

Une future intégration devra vérifier les autorisations, la cible,
les quotas, la capacité disponible et les contraintes de disponibilité.

## Intégration

Le participant implémente l'interface `ActionParticipant` du module
`ran-action-service` et utilise le contrat `ActionEvent` de `ran-common`.

Il doit être enregistré dans le service d'exécution pour participer
au routage des actions. Le lancement autonome de ce module ne suffit
pas à le connecter automatiquement au consommateur Kafka existant.
EOF

echo "PARTIE 7B/8 — 2/3B générée : scaling-participant."
echo "Aucune compilation ou activation de service exécutée."