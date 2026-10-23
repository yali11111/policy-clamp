
#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# RAN Congestion Control Platform
# Partie 1/8 : initialisation et fichiers racine
# Ce script génère des fichiers. Il ne démarre aucun service.
# ============================================================

ROOT="ran-congestion-control-platform"

mkdir -p "$ROOT"

cd "$ROOT"

# ------------------------------------------------------------
# 1. Arborescence complète
# ------------------------------------------------------------

mkdir -p \
  infrastructure/kafka \
  infrastructure/prometheus \
  infrastructure/grafana/dashboards \
  infrastructure/loki \
  infrastructure/jaeger \
  ran-common/src/main/java/org/onap/policy/ran/common \
  ran-kpi-service/src/main/java/org/example/ran/kpi/producer \
  ran-kpi-service/src/main/java/org/example/ran/kpi/simulator \
  ran-kpi-service/src/main/java/org/example/ran/kpi/config \
  ran-predictor-service/src/main/java/org/example/ran/predictor/consumer \
  ran-predictor-service/src/main/java/org/example/ran/predictor/service \
  ran-predictor-service/src/main/java/org/example/ran/predictor/producer \
  ran-control-service/src/main/java/org/example/ran/control/consumer \
  ran-control-service/src/main/java/org/example/ran/control/policy \
  ran-control-service/src/main/java/org/example/ran/control/producer \
  ran-clamp-participant-service/src/main/java/org/onap/policy/ran/participant/main/handler \
  ran-clamp-participant-service/src/main/java/org/onap/policy/ran/participant/service \
  ran-clamp-participant-service/src/main/java/org/onap/policy/ran/participant/config \
  ran-participants/traffic-steering-participant \
  ran-participants/scaling-participant \
  ran-participants/network-config-participant \
  ran-observability-service/src/main/java/org/example/ran/observability/consumer \
  ran-observability-service/src/main/java/org/example/ran/observability/metrics \
  ran-observability-service/src/main/java/org/example/ran/observability/tracing \
  shared-kafka-config/src/main/java/org/example/ran/kafka \
  docs

# ------------------------------------------------------------
# 2. README.md
# ------------------------------------------------------------

cat > README.md <<'EOF'
# RAN Congestion Control Platform

Plateforme de référence pour simuler, détecter et traiter la
congestion d'un réseau d'accès radio (RAN), avec une architecture
orientée événements.

## Objectifs

- Simuler des KPI RAN et O-RAN.
- Transporter les événements avec Apache Kafka.
- Détecter des situations de congestion.
- Appliquer des règles de contrôle explicites.
- Représenter les actions sous forme d'événements.
- Préparer une intégration avec ONAP Policy-CLAMP et ACM.
- Exposer des métriques et préparer la collecte des journaux
  et des traces distribuées.

## Architecture

1. ran-common : modèles de données partagés.
2. ran-kpi-service : génération des KPI.
3. ran-predictor-service : analyse des KPI et détection.
4. ran-control-service : décision et émission d'actions.
5. ran-clamp-participant-service : adaptateur destiné à
   l'intégration ONAP ACM.
6. ran-participants : composants de contrôle RAN simulés.
7. ran-observability-service : consommation des événements
   et exposition des indicateurs.
8. shared-kafka-config : configuration Kafka réutilisable.

## Chaîne fonctionnelle

KPI RAN
  -> Kafka
  -> prédiction de congestion
  -> Kafka
  -> moteur de contrôle
  -> événement d'action
  -> participant RAN ou adaptateur ACM

Les actions générées par défaut doivent rester simulées tant
qu'une intégration réelle avec le réseau n'a pas été configurée,
sécurisée et validée.

## Technologies ciblées

- Java et Spring Boot
- Apache Kafka
- ONAP Policy-CLAMP / Automation Composition Management (ACM)
- Prometheus et Grafana
- Loki
- Jaeger et OpenTelemetry
- Kubernetes pour un déploiement ultérieur éventuel

Les versions exactes devront être vérifiées avec les versions
des dépendances ONAP réellement utilisées.

## Génération du projet

Le script generate-platform.sh crée les fichiers du dépôt.

La génération ne lance ni Maven, ni Java, ni Docker, ni
Kubernetes. Elle ne télécharge aucune dépendance et ne démarre
aucun service.

## Configuration

Les paramètres de connexion devront être fournis par variables
d'environnement ou par les fichiers de configuration du service.
Ne pas enregistrer de secrets réels dans le dépôt.

## Limites de cette plateforme

Le simulateur, les règles de congestion et les participants
servent de base de développement. Ils ne constituent pas, à eux
seuls, un contrôleur de réseau de production.

Avant un déploiement réel, prévoir notamment :
- authentification et autorisation ;
- chiffrement des communications ;
- validation des actions et mécanisme de retour arrière ;
- gestion des erreurs et des messages répétés ;
- tests de charge, tests d'intégration et tests de résilience ;
- validation de compatibilité avec ONAP ACM et les API RAN.

Consulter docs/ pour la documentation technique.
EOF

# ------------------------------------------------------------
# 3. pom.xml parent
# ------------------------------------------------------------

cat > pom.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <groupId>org.example.ran</groupId>
    <artifactId>ran-congestion-control-platform</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>pom</packaging>

    <name>RAN Congestion Control Platform</name>
    <description>
        Event-driven platform for RAN congestion detection,
        control actions and observability.
    </description>

    <properties>
        <java.version>17</java.version>
        <maven.compiler.release>${java.version}</maven.compiler.release>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <spring-boot.version>3.3.5</spring-boot.version>
        <spring-kafka.version>3.2.4</spring-kafka.version>
        <micrometer.version>1.13.6</micrometer.version>
        <opentelemetry.version>1.43.0</opentelemetry.version>
    </properties>

    <modules>
        <module>ran-common</module>
        <module>shared-kafka-config</module>
        <module>ran-kpi-service</module>
        <module>ran-predictor-service</module>
        <module>ran-control-service</module>
        <module>ran-clamp-participant-service</module>
        <module>ran-observability-service</module>
    </modules>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-dependencies</artifactId>
                <version>${spring-boot.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>

            <dependency>
                <groupId>org.springframework.kafka</groupId>
                <artifactId>spring-kafka</artifactId>
                <version>${spring-kafka.version}</version>
            </dependency>

            <dependency>
                <groupId>io.micrometer</groupId>
                <artifactId>micrometer-registry-prometheus</artifactId>
                <version>${micrometer.version}</version>
            </dependency>

            <dependency>
                <groupId>io.opentelemetry</groupId>
                <artifactId>opentelemetry-api</artifactId>
                <version>${opentelemetry.version}</version>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <build>
        <pluginManagement>
            <plugins>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-compiler-plugin</artifactId>
                    <version>3.13.0</version>
                    <configuration>
                        <release>${maven.compiler.release}</release>
                    </configuration>
                </plugin>

                <plugin>
                    <groupId>org.springframework.boot</groupId>
                    <artifactId>spring-boot-maven-plugin</artifactId>
                    <version>${spring-boot.version}</version>
                </plugin>
            </plugins>
        </pluginManagement>
    </build>

</project>
EOF

# ------------------------------------------------------------
# 4. docker-compose.yml
# Fichier de configuration uniquement : aucun démarrage.
# ------------------------------------------------------------

cat > docker-compose.yml <<'EOF'
services:
  kafka:
    image: apache/kafka:3.9.0
    hostname: kafka
    ports:
      - "9092:9092"
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_LISTENERS: PLAINTEXT://:9092,CONTROLLER://:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
    volumes:
      - kafka-data:/var/lib/kafka/data

  prometheus:
    image: prom/prometheus:v2.55.1
    ports:
      - "9090:9090"
    volumes:
      - ./infrastructure/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    depends_on:
      - kafka

  grafana:
    image: grafana/grafana:11.3.0
    ports:
      - "3000:3000"
    volumes:
      - ./infrastructure/grafana/dashboards:/var/lib/grafana/dashboards:ro
    depends_on:
      - prometheus

  loki:
    image: grafana/loki:3.2.1
    ports:
      - "3100:3100"

  jaeger:
    image: jaegertracing/all-in-one:1.63.0
    ports:
      - "16686:16686"
      - "4317:4317"
      - "4318:4318"

volumes:
  kafka-data:
EOF

# ------------------------------------------------------------
# 5. Fichiers de documentation initiaux
# ------------------------------------------------------------

cat > docs/architecture.md <<'EOF'
# Architecture

La plateforme sépare la production des KPI, l'analyse de la
congestion, la décision de contrôle et l'exécution des actions.

Kafka assure le transport asynchrone entre ces composants.
Les événements doivent être corrélables à l'aide d'identifiants,
d'horodatages et d'identifiants de cellule ou de secteur.

Le participant ONAP ACM est un adaptateur distinct : son
implémentation finale doit utiliser les contrats et interfaces
de la version ONAP sélectionnée.

Les actions réseau sont simulées par défaut.
EOF

cat > docs/kafka-topics.md <<'EOF'
# Kafka topics

Topics proposés :

- ran.kpi
- ran.congestion
- ran.action
- ran.action.result

Les noms définitifs, le nombre de partitions, la réplication,
la rétention et les stratégies de reprise doivent être définis
pour l'environnement cible.

En production, configurer l'authentification, les ACL et le
chiffrement Kafka.
EOF

cat > docs/clamp-participant-flow.md <<'EOF'
# Flux du participant CLAMP / ACM

1. Une composition d'automatisation est définie dans ONAP ACM.
2. Les éléments de composition représentent les actions RAN.
3. L'adaptateur reçoit les commandes selon le contrat ACM retenu.
4. Le service d'action valide les paramètres.
5. Le participant simulé exécute ou rejette l'action.
6. Le résultat est communiqué au mécanisme de supervision.

Ce document décrit le flux cible ; les interfaces concrètes
doivent être alignées sur la version ONAP installée.
EOF

cat > docs/ran-o-ran-mapping.md <<'EOF'
# Correspondance RAN / O-RAN

Les KPI simulés peuvent représenter notamment :

- utilisation des ressources radio ;
- débit montant et descendant ;
- latence ;
- perte de paquets ;
- nombre d'utilisateurs actifs ;
- charge d'une cellule.

Les actions de démonstration peuvent représenter :

- traffic steering ;
- demande de mise à l'échelle d'un composant ;
- changement de paramètres réseau.

Ces modèles ne remplacent pas les schémas, interfaces ou
procédures normalisés applicables au RAN/O-RAN.
EOF

echo "Partie 1/8 générée dans : $(pwd)"
echo "Aucun outil de build ou service n'a été lancé."


# ============================================================
# PARTIE 2/8 : INFRASTRUCTURE ET OBSERVABILITE
# ============================================================

mkdir -p \
  infrastructure/kafka \
  infrastructure/prometheus \
  infrastructure/grafana/dashboards \
  infrastructure/grafana/provisioning/datasources \
  infrastructure/grafana/provisioning/dashboards \
  infrastructure/loki \
  infrastructure/jaeger

# ------------------------------------------------------------
# 1. Configuration Kafka
# ------------------------------------------------------------

cat > infrastructure/kafka/kafka-compose.yml <<'EOF'
services:
  kafka:
    image: apache/kafka:3.9.0
    hostname: kafka
    ports:
      - "9092:9092"
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_LISTENERS: PLAINTEXT://:9092,CONTROLLER://:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
    volumes:
      - kafka-data:/var/lib/kafka/data

volumes:
  kafka-data:
EOF

# ------------------------------------------------------------
# 2. Configuration Prometheus
# ------------------------------------------------------------

cat > infrastructure/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

  external_labels:
    platform: ran-congestion-control
    environment: local

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets:
          - localhost:9090

  - job_name: ran-kpi-service
    metrics_path: /actuator/prometheus
    static_configs:
      - targets:
          - ran-kpi-service:8080

  - job_name: ran-predictor-service
    metrics_path: /actuator/prometheus
    static_configs:
      - targets:
          - ran-predictor-service:8081

  - job_name: ran-control-service
    metrics_path: /actuator/prometheus
    static_configs:
      - targets:
          - ran-control-service:8082

  - job_name: ran-clamp-participant-service
    metrics_path: /actuator/prometheus
    static_configs:
      - targets:
          - ran-clamp-participant-service:8083

  - job_name: ran-observability-service
    metrics_path: /actuator/prometheus
    static_configs:
      - targets:
          - ran-observability-service:8084
EOF

# ------------------------------------------------------------
# 3. Configuration Loki
# ------------------------------------------------------------

cat > infrastructure/loki/loki-config.yml <<'EOF'
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  path_prefix: /loki
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules

schema_config:
  configs:
    - from: "2024-01-01"
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  allow_structured_metadata: true
  retention_period: 168h

compactor:
  working_directory: /loki/compactor
  retention_enabled: true
  delete_request_store: filesystem
EOF

# ------------------------------------------------------------
# 4. Configuration Jaeger
# ------------------------------------------------------------

cat > infrastructure/jaeger/README.md <<'EOF'
# Jaeger

Le service Jaeger est prévu pour recevoir les traces distribuées
émises par les services de la plateforme.

Ports prévus dans le docker-compose racine :

- 16686 : interface Web de Jaeger.
- 4317 : réception OTLP sur gRPC.
- 4318 : réception OTLP sur HTTP.

Les services applicatifs devront être configurés pour exporter
les traces vers le collecteur approprié.

Dans un déploiement conteneurisé, utiliser le nom DNS du service
Jaeger et non localhost depuis les conteneurs applicatifs.

La configuration actuelle vise un environnement de démonstration.
Elle ne définit pas de stockage durable de production.
EOF

# ------------------------------------------------------------
# 5. Source de données Grafana : Prometheus
# ------------------------------------------------------------

cat > infrastructure/grafana/provisioning/datasources/prometheus.yml <<'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    uid: prometheus-ran
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

# ------------------------------------------------------------
# 6. Source de données Grafana : Loki
# ------------------------------------------------------------

cat > infrastructure/grafana/provisioning/datasources/loki.yml <<'EOF'
apiVersion: 1

datasources:
  - name: Loki
    uid: loki-ran
    type: loki
    access: proxy
    url: http://loki:3100
    editable: true
EOF

# ------------------------------------------------------------
# 7. Provisioning des tableaux de bord Grafana
# ------------------------------------------------------------

cat > infrastructure/grafana/provisioning/dashboards/dashboards.yml <<'EOF'
apiVersion: 1

providers:
  - name: RAN dashboards
    orgId: 1
    folder: RAN Congestion Control
    type: file
    disableDeletion: true
    editable: true
    options:
      path: /var/lib/grafana/dashboards
EOF

# ------------------------------------------------------------
# 8. Tableau de bord de supervision RAN
# ------------------------------------------------------------

cat > infrastructure/grafana/dashboards/ran-congestion-overview.json <<'EOF'
{
  "uid": "ran-congestion-overview",
  "title": "RAN Congestion Control Overview",
  "tags": [
    "RAN",
    "O-RAN",
    "congestion",
    "Kafka"
  ],
  "timezone": "browser",
  "schemaVersion": 39,
  "version": 1,
  "refresh": "15s",
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "panels": [
    {
      "id": 1,
      "title": "CPU / process metrics placeholder",
      "type": "timeseries",
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus-ran"
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "targets": [
        {
          "refId": "A",
          "expr": "up",
          "legendFormat": "{{job}}"
        }
      ]
    },
    {
      "id": 2,
      "title": "Available service endpoints",
      "type": "stat",
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus-ran"
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 0
      },
      "targets": [
        {
          "refId": "A",
          "expr": "sum(up)",
          "legendFormat": "Services up"
        }
      ]
    },
    {
      "id": 3,
      "title": "Application logs",
      "type": "logs",
      "datasource": {
        "type": "loki",
        "uid": "loki-ran"
      },
      "gridPos": {
        "h": 8,
        "w": 24,
        "x": 0,
        "y": 8
      },
      "targets": [
        {
          "refId": "A",
          "expr": "{service=~\"ran-.*\"}"
        }
      ]
    }
  ]
}
EOF

# ------------------------------------------------------------
# 9. Documentation infrastructure
# ------------------------------------------------------------

cat > infrastructure/README.md <<'EOF'
# Infrastructure

Ce répertoire contient les fichiers de configuration de
l'infrastructure locale de démonstration.

Composants :
- Kafka : transport des événements.
- Prometheus : collecte des métriques.
- Grafana : tableaux de bord.
- Loki : centralisation des journaux.
- Jaeger : visualisation des traces distribuées.

Les configurations Prometheus supposent que les applications
exposeront leurs métriques sur /actuator/prometheus.

Les noms DNS définis pour les services applicatifs devront
correspondre aux noms des services du futur déploiement.

Aucun composant n'est démarré par le générateur de fichiers.
EOF

echo "Partie 2/8 : configurations d'infrastructure générées."


# ============================================================
# PARTIE 3/8 : MODULE COMMUN RAN-COMMON
# ============================================================

COMMON="ran-common/src/main/java/org/onap/policy/ran/common"

mkdir -p "$COMMON"

# ------------------------------------------------------------
# 1. RanKpi.java
# ------------------------------------------------------------

cat > "$COMMON/RanKpi.java" <<'EOF'
package org.onap.policy.ran.common;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * KPI radio observé sur une cellule RAN.
 *
 * Les valeurs sont normalisées afin de faciliter leur traitement
 * par les services de prédiction et de contrôle.
 *
 * Les pourcentages sont exprimés entre 0 et 100.
 * Le débit est exprimé en Mbps, la latence en millisecondes.
 */
public record RanKpi(
        String eventId,
        Instant timestamp,
        String source,
        String plmnId,
        String ranNodeId,
        String cellId,
        String sliceId,
        double prbUtilizationPercent,
        double downlinkThroughputMbps,
        double uplinkThroughputMbps,
        double latencyMs,
        double packetLossPercent,
        int activeUsers,
        double signalQualityDb,
        boolean synthetic
) {

    public RanKpi {
        eventId = requireText(
                eventId == null ? UUID.randomUUID().toString() : eventId,
                "eventId");

        timestamp = Objects.requireNonNullElseGet(
                timestamp, Instant::now);

        source = requireText(source, "source");
        plmnId = requireText(plmnId, "plmnId");
        ranNodeId = requireText(ranNodeId, "ranNodeId");
        cellId = requireText(cellId, "cellId");
        sliceId = normalizeOptional(sliceId);

        requireRange(
                prbUtilizationPercent, 0, 100,
                "prbUtilizationPercent");

        requireNonNegative(
                downlinkThroughputMbps, "downlinkThroughputMbps");

        requireNonNegative(
                uplinkThroughputMbps, "uplinkThroughputMbps");

        requireNonNegative(latencyMs, "latencyMs");

        requireRange(
                packetLossPercent, 0, 100,
                "packetLossPercent");

        if (activeUsers < 0) {
            throw new IllegalArgumentException(
                    "activeUsers must be >= 0");
        }

        if (!Double.isFinite(signalQualityDb)) {
            throw new IllegalArgumentException(
                    "signalQualityDb must be finite");
        }
    }

    public static RanKpi create(
            String ranNodeId,
            String cellId,
            double prbUtilizationPercent,
            double downlinkThroughputMbps,
            double uplinkThroughputMbps,
            double latencyMs,
            double packetLossPercent,
            int activeUsers) {

        return new RanKpi(
                UUID.randomUUID().toString(),
                Instant.now(),
                "ran-kpi-service",
                "00101",
                ranNodeId,
                cellId,
                "default",
                prbUtilizationPercent,
                downlinkThroughputMbps,
                uplinkThroughputMbps,
                latencyMs,
                packetLossPercent,
                activeUsers,
                0.0,
                true
        );
    }

    public boolean indicatesHighRadioLoad() {
        return prbUtilizationPercent >= 80.0;
    }

    private static String requireText(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    name + " must not be blank");
        }
        return value.trim();
    }

    private static String normalizeOptional(String value) {
        return value == null || value.isBlank()
                ? "default"
                : value.trim();
    }

    private static void requireNonNegative(
            double value, String name) {

        if (!Double.isFinite(value) || value < 0) {
            throw new IllegalArgumentException(
                    name + " must be finite and >= 0");
        }
    }

    private static void requireRange(
            double value,
            double minimum,
            double maximum,
            String name) {

        if (!Double.isFinite(value)
                || value < minimum
                || value > maximum) {

            throw new IllegalArgumentException(
                    name + " must be between "
                            + minimum + " and " + maximum);
        }
    }
}
EOF

# ------------------------------------------------------------
# 2. CongestionEvent.java
# ------------------------------------------------------------

cat > "$COMMON/CongestionEvent.java" <<'EOF'
package org.onap.policy.ran.common;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Événement décrivant une congestion détectée ou anticipée.
 *
 * confidence est comprise entre 0 et 1.
 * predictedHorizonSeconds indique l'horizon de prédiction.
 */
public record CongestionEvent(
        String eventId,
        String correlationId,
        Instant timestamp,
        String ranNodeId,
        String cellId,
        String sliceId,
        CongestionLevel level,
        CongestionType type,
        double confidence,
        double prbUtilizationPercent,
        double latencyMs,
        double packetLossPercent,
        int activeUsers,
        int predictedHorizonSeconds,
        String reason
) {

    public enum CongestionLevel {
        NORMAL,
        LOW,
        MEDIUM,
        HIGH,
        CRITICAL
    }

    public enum CongestionType {
        DETECTED,
        PREDICTED,
        CLEARED
    }

    public CongestionEvent {
        eventId = requireText(
                eventId == null ? UUID.randomUUID().toString() : eventId,
                "eventId");

        correlationId = requireText(
                correlationId == null
                        ? eventId
                        : correlationId,
                "correlationId");

        timestamp = Objects.requireNonNullElseGet(
                timestamp, Instant::now);

        ranNodeId = requireText(ranNodeId, "ranNodeId");
        cellId = requireText(cellId, "cellId");

        sliceId = sliceId == null || sliceId.isBlank()
                ? "default"
                : sliceId.trim();

        level = Objects.requireNonNull(level, "level");
        type = Objects.requireNonNull(type, "type");

        requireRange(confidence, 0, 1, "confidence");

        requireRange(
                prbUtilizationPercent, 0, 100,
                "prbUtilizationPercent");

        requireNonNegative(latencyMs, "latencyMs");

        requireRange(
                packetLossPercent, 0, 100,
                "packetLossPercent");

        if (activeUsers < 0) {
            throw new IllegalArgumentException(
                    "activeUsers must be >= 0");
        }

        if (predictedHorizonSeconds < 0) {
            throw new IllegalArgumentException(
                    "predictedHorizonSeconds must be >= 0");
        }

        reason = reason == null ? "" : reason.trim();
    }

    public boolean requiresControlAction() {
        return level == CongestionLevel.HIGH
                || level == CongestionLevel.CRITICAL;
    }

    public boolean isPrediction() {
        return type == CongestionType.PREDICTED;
    }

    private static String requireText(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    name + " must not be blank");
        }
        return value.trim();
    }

    private static void requireNonNegative(
            double value, String name) {

        if (!Double.isFinite(value) || value < 0) {
            throw new IllegalArgumentException(
                    name + " must be finite and >= 0");
        }
    }

    private static void requireRange(
            double value,
            double minimum,
            double maximum,
            String name) {

        if (!Double.isFinite(value)
                || value < minimum
                || value > maximum) {

            throw new IllegalArgumentException(
                    name + " must be between "
                            + minimum + " and " + maximum);
        }
    }
}
EOF

# ------------------------------------------------------------
# 3. ActionEvent.java
# ------------------------------------------------------------

cat > "$COMMON/ActionEvent.java" <<'EOF'
package org.onap.policy.ran.common;

import java.time.Instant;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * Commande de contrôle produite par le moteur de politique.
 *
 * Les participants peuvent simuler ces actions ou les transmettre
 * à une intégration réseau explicitement configurée.
 */
public record ActionEvent(
        String actionId,
        String correlationId,
        String congestionEventId,
        Instant timestamp,
        String ranNodeId,
        String cellId,
        String sliceId,
        ActionType actionType,
        ActionStatus status,
        ActionTarget target,
        Map<String, String> parameters,
        String reason,
        String requestedBy,
        Instant expiresAt
) {

    public enum ActionType {
        TRAFFIC_STEERING,
        SCALE_OUT,
        SCALE_IN,
        NETWORK_CONFIGURATION,
        NO_OP
    }

    public enum ActionStatus {
        REQUESTED,
        ACCEPTED,
        REJECTED,
        EXECUTING,
        SUCCEEDED,
        FAILED,
        EXPIRED,
        ROLLED_BACK
    }

    public enum ActionTarget {
        TRAFFIC_STEERING_PARTICIPANT,
        SCALING_PARTICIPANT,
        NETWORK_CONFIG_PARTICIPANT,
        SIMULATOR
    }

    public ActionEvent {
        actionId = requireText(
                actionId == null ? UUID.randomUUID().toString() : actionId,
                "actionId");

        correlationId = requireText(
                correlationId == null ? actionId : correlationId,
                "correlationId");

        congestionEventId = congestionEventId == null
                ? ""
                : congestionEventId.trim();

        timestamp = Objects.requireNonNullElseGet(
                timestamp, Instant::now);

        ranNodeId = requireText(ranNodeId, "ranNodeId");
        cellId = requireText(cellId, "cellId");

        sliceId = sliceId == null || sliceId.isBlank()
                ? "default"
                : sliceId.trim();

        actionType = Objects.requireNonNull(
                actionType, "actionType");

        status = Objects.requireNonNull(status, "status");

        target = Objects.requireNonNull(target, "target");

        parameters = parameters == null
                ? Map.of()
                : Map.copyOf(parameters);

        reason = reason == null ? "" : reason.trim();

        requestedBy = requestedBy == null || requestedBy.isBlank()
                ? "ran-control-service"
                : requestedBy.trim();

        if (expiresAt != null && expiresAt.isBefore(timestamp)) {
            throw new IllegalArgumentException(
                    "expiresAt must not be before timestamp");
        }
    }

    public boolean isTerminal() {
        return switch (status) {
            case REJECTED, SUCCEEDED, FAILED, EXPIRED, ROLLED_BACK -> true;
            default -> false;
        };
    }

    public boolean isExpired(Instant now) {
        return expiresAt != null && !now.isBefore(expiresAt);
    }

    public ActionEvent withStatus(ActionStatus newStatus) {
        return new ActionEvent(
                actionId,
                correlationId,
                congestionEventId,
                timestamp,
                ranNodeId,
                cellId,
                sliceId,
                actionType,
                newStatus,
                target,
                parameters,
                reason,
                requestedBy,
                expiresAt
        );
    }

    public static ActionEvent noOp(
            String ranNodeId,
            String cellId,
            String reason) {

        Instant now = Instant.now();

        return new ActionEvent(
                UUID.randomUUID().toString(),
                UUID.randomUUID().toString(),
                "",
                now,
                ranNodeId,
                cellId,
                "default",
                ActionType.NO_OP,
                ActionStatus.REQUESTED,
                ActionTarget.SIMULATOR,
                Map.of(),
                reason,
                "ran-control-service",
                null
        );
    }

    private static String requireText(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    name + " must not be blank");
        }
        return value.trim();
    }
}
EOF

# ------------------------------------------------------------
# 4. Documentation du contrat commun
# ------------------------------------------------------------

cat > ran-common/README.md <<'EOF'
# ran-common

Module contenant les contrats de données partagés par les
services de la plateforme.

## Classes

- RanKpi : observation des KPI radio.
- CongestionEvent : événement de congestion.
- ActionEvent : commande et état d'une action de contrôle.

## Conventions

- Horodatages : java.time.Instant, en UTC.
- Pourcentages : nombres compris entre 0 et 100.
- Confiance de prédiction : nombre compris entre 0 et 1.
- Identifiants : chaînes non vides.
- Paramètres d'action : Map<String, String>.
- Événements synthétiques : synthetic=true.

## Sérialisation

Ces modèles ne dépendent pas directement de Jackson. Les services
qui les échangent sur Kafka devront configurer explicitement leur
sérialiseur JSON et la désérialisation des types.

Le contrat JSON doit être conservé de manière compatible lors
des évolutions du schéma.

## Sécurité

Ne pas placer de données personnelles, secrets, identifiants
d'abonnés ou informations sensibles dans les événements.
EOF

echo "Partie 3/8 : modèles ran-common générés."


# ============================================================
# PARTIE 4/8 : RAN KPI SERVICE
# ============================================================

KPI="ran-kpi-service/src/main/java/org/example/ran/kpi"

mkdir -p \
  "$KPI/producer" \
  "$KPI/simulator" \
  "$KPI/config" \
  ran-kpi-service/src/main/resources

# ------------------------------------------------------------
# 1. RanKpiProducer.java
# ------------------------------------------------------------

cat > "$KPI/producer/RanKpiProducer.java" <<'EOF'
package org.example.ran.kpi.producer;

import org.onap.policy.ran.common.RanKpi;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.concurrent.CompletableFuture;

/**
 * Publie les KPI RAN dans Kafka.
 */
@Component
public class RanKpiProducer {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(RanKpiProducer.class);

    private final KafkaTemplate<String, Object> kafkaTemplate;
    private final String topic;

    public RanKpiProducer(
            KafkaTemplate<String, Object> kafkaTemplate,
            @Value("${ran.kafka.topics.kpi:ran.kpi}") String topic) {

        this.kafkaTemplate = kafkaTemplate;
        this.topic = topic;
    }

    public CompletableFuture<Void> publish(RanKpi kpi) {
        String key = kpi.cellId();

        return kafkaTemplate.send(topic, key, kpi)
                .thenAccept(result -> LOGGER.debug(
                        "KPI published: eventId={}, cellId={}, topic={}, partition={}",
                        kpi.eventId(),
                        kpi.cellId(),
                        result.getRecordMetadata().topic(),
                        result.getRecordMetadata().partition()
                ));
    }
}
EOF

# ------------------------------------------------------------
# 2. KpiSimulator.java
# ------------------------------------------------------------

cat > "$KPI/simulator/KpiSimulator.java" <<'EOF'
package org.example.ran.kpi.simulator;

import org.example.ran.kpi.producer.RanKpiProducer;
import org.onap.policy.ran.common.RanKpi;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.concurrent.ThreadLocalRandom;

/**
 * Simulate des KPI de plusieurs cellules.
 *
 * Le profil de congestion permet de produire des scénarios
 * normaux, chargés ou critiques.
 */
@Component
@ConditionalOnProperty(
        name = "ran.simulator.enabled",
        havingValue = "true",
        matchIfMissing = true
)
public class KpiSimulator {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(KpiSimulator.class);

    private final RanKpiProducer producer;
    private final String nodeId;
    private final int numberOfCells;
    private final String profile;

    public KpiSimulator(
            RanKpiProducer producer,
            @Value("${ran.simulator.node-id:gnb-001}") String nodeId,
            @Value("${ran.simulator.cells:3}") int numberOfCells,
            @Value("${ran.simulator.profile:random}") String profile) {

        if (numberOfCells < 1 || numberOfCells > 1000) {
            throw new IllegalArgumentException(
                    "ran.simulator.cells must be between 1 and 1000");
        }

        this.producer = producer;
        this.nodeId = nodeId;
        this.numberOfCells = numberOfCells;
        this.profile = profile.toLowerCase();
    }

    @Scheduled(
            fixedDelayString = "${ran.simulator.interval-ms:2000}"
    )
    public void generateKpis() {
        for (int i = 1; i <= numberOfCells; i++) {
            try {
                RanKpi kpi = generateForCell(i);

                producer.publish(kpi).whenComplete((ignored, error) -> {
                    if (error != null) {
                        LOGGER.error(
                                "KPI publication failed for cell {}",
                                kpi.cellId(),
                                error
                        );
                    }
                });
            } catch (RuntimeException exception) {
                LOGGER.error(
                        "Could not generate KPI for cell index {}",
                        i,
                        exception
                );
            }
        }
    }

    private RanKpi generateForCell(int index) {
        ThreadLocalRandom random = ThreadLocalRandom.current();

        double prb;
        double latency;
        double loss;

        switch (profile) {
            case "normal" -> {
                prb = random.nextDouble(20.0, 65.0);
                latency = random.nextDouble(5.0, 25.0);
                loss = random.nextDouble(0.0, 0.5);
            }
            case "congested" -> {
                prb = random.nextDouble(82.0, 96.0);
                latency = random.nextDouble(40.0, 100.0);
                loss = random.nextDouble(1.0, 5.0);
            }
            case "critical" -> {
                prb = random.nextDouble(96.0, 100.0);
                latency = random.nextDouble(100.0, 250.0);
                loss = random.nextDouble(5.0, 15.0);
            }
            default -> {
                prb = random.nextDouble(10.0, 100.0);
                latency = random.nextDouble(5.0, 150.0);
                loss = random.nextDouble(0.0, 8.0);
            }
        }

        double downlink = Math.max(
                0.0,
                (100.0 - prb) * random.nextDouble(1.0, 3.0)
        );

        double uplink = Math.max(
                0.0,
                (100.0 - prb) * random.nextDouble(0.3, 1.2)
        );

        int users = random.nextInt(10, 501);

        return new RanKpi(
                null,
                null,
                "ran-kpi-service",
                "00101",
                nodeId,
                "cell-" + index,
                "default",
                prb,
                downlink,
                uplink,
                latency,
                loss,
                users,
                random.nextDouble(-15.0, 30.0),
                true
        );
    }
}
EOF

# ------------------------------------------------------------
# 3. KafkaConfig.java
# ------------------------------------------------------------

cat > "$KPI/config/KafkaConfig.java" <<'EOF'
package org.example.ran.kpi.config;

import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.support.serializer.JsonSerializer;

import java.util.HashMap;
import java.util.Map;

@Configuration
public class KafkaConfig {

    @Bean
    public ProducerFactory<String, Object> producerFactory(
            @Value("${spring.kafka.bootstrap-servers:localhost:9092}")
            String bootstrapServers) {

        Map<String, Object> properties = new HashMap<>();

        properties.put(
                ProducerConfig.BOOTSTRAP_SERVERS_CONFIG,
                bootstrapServers
        );

        properties.put(
                ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG,
                StringSerializer.class
        );

        properties.put(
                ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG,
                JsonSerializer.class
        );

        properties.put(
                ProducerConfig.ACKS_CONFIG,
                "all"
        );

        properties.put(
                ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG,
                true
        );

        properties.put(
                ProducerConfig.RETRIES_CONFIG,
                Integer.MAX_VALUE
        );

        properties.put(
                ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION,
                5
        );

        properties.put(
                ProducerConfig.DELIVERY_TIMEOUT_MS_CONFIG,
                120000
        );

        return new DefaultKafkaProducerFactory<>(properties);
    }

    @Bean
    public KafkaTemplate<String, Object> kafkaTemplate(
            ProducerFactory<String, Object> producerFactory) {

        return new KafkaTemplate<>(producerFactory);
    }
}
EOF

# ------------------------------------------------------------
# 4. RanKpiApplication.java
# ------------------------------------------------------------

cat > "$KPI/RanKpiApplication.java" <<'EOF'
package org.example.ran.kpi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication(scanBasePackages = {
        "org.example.ran.kpi",
        "org.onap.policy.ran.common"
})
@EnableScheduling
public class RanKpiApplication {

    public static void main(String[] args) {
        SpringApplication.run(RanKpiApplication.class, args);
    }
}
EOF

# ------------------------------------------------------------
# 5. application.yml
# ------------------------------------------------------------

cat > ran-kpi-service/src/main/resources/application.yml <<'EOF'
spring:
  application:
    name: ran-kpi-service

  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}

server:
  port: ${SERVER_PORT:8080}

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
      kpi: ${RAN_KPI_TOPIC:ran.kpi}

  simulator:
    enabled: ${RAN_SIMULATOR_ENABLED:true}
    node-id: ${RAN_NODE_ID:gnb-001}
    cells: ${RAN_SIMULATOR_CELLS:3}
    profile: ${RAN_SIMULATOR_PROFILE:random}
    interval-ms: ${RAN_SIMULATOR_INTERVAL_MS:2000}

logging:
  level:
    root: INFO
    org.example.ran: INFO
EOF

# ------------------------------------------------------------
# 6. pom.xml du service
# ------------------------------------------------------------

cat > ran-kpi-service/pom.xml <<'EOF'
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

    <artifactId>ran-kpi-service</artifactId>
    <name>RAN KPI Service</name>

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
# 7. Documentation du service
# ------------------------------------------------------------

cat > ran-kpi-service/README.md <<'EOF'
# RAN KPI Service

Service de simulation et de publication des KPI RAN.

## Configuration

- KAFKA_BOOTSTRAP_SERVERS : adresses des brokers Kafka.
- RAN_KPI_TOPIC : topic des KPI.
- RAN_SIMULATOR_ENABLED : active ou désactive la simulation.
- RAN_SIMULATOR_CELLS : nombre de cellules simulées.
- RAN_SIMULATOR_PROFILE : random, normal, congested ou critical.
- RAN_SIMULATOR_INTERVAL_MS : délai entre deux cycles.

## Profil de simulation

- normal : charge et latence modérées.
- congested : charge radio élevée.
- critical : charge proche de la saturation.
- random : valeurs variables.

Toutes les données générées sont synthétiques.

## Publication

Les messages sont envoyés vers le topic ran.kpi avec cellId
comme clé Kafka, afin de conserver la cohérence de partition
par cellule.

Le service ne configure pas automatiquement la création du
topic. Celle-ci doit être assurée par l'environnement Kafka.

## Limites

Ce simulateur n'est pas un collecteur de télémétrie O-RAN.
Une intégration réelle doit connecter les mesures aux sources
de données et interfaces autorisées du réseau.
EOF

echo "Partie 4/8 : ran-kpi-service généré."


# ============================================================
# PARTIE 5A/8 — RAN PREDICTOR SERVICE
# Moteur de prédiction, producteur et consommateur Kafka
# ============================================================

set -eu

BASE="ran-predictor-service"
PKG="$BASE/src/main/java/org/example/ran/predictor"

mkdir -p \
  "$PKG/consumer" \
  "$PKG/service" \
  "$PKG/producer" \
  "$PKG/config" \
  "$BASE/src/main/resources"

# ------------------------------------------------------------
# 1. CongestionPredictorService.java
# ------------------------------------------------------------

cat > "$PKG/service/CongestionPredictorService.java" <<'EOF'
package org.example.ran.predictor.service;

import org.onap.policy.ran.common.CongestionEvent;
import org.onap.policy.ran.common.RanKpi;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.UUID;

@Service
public class CongestionPredictorService {

    private final double prbThreshold;
    private final double latencyThreshold;
    private final double packetLossThreshold;
    private final int horizonSeconds;

    public CongestionPredictorService(
            @Value("${ran.predictor.thresholds.prb-percent:80.0}")
            double prbThreshold,
            @Value("${ran.predictor.thresholds.latency-ms:50.0}")
            double latencyThreshold,
            @Value("${ran.predictor.thresholds.packet-loss-percent:1.0}")
            double packetLossThreshold,
            @Value("${ran.predictor.horizon-seconds:30}")
            int horizonSeconds) {

        if (!Double.isFinite(prbThreshold)
                || prbThreshold <= 0 || prbThreshold > 100) {
            throw new IllegalArgumentException("Invalid PRB threshold");
        }

        if (!Double.isFinite(latencyThreshold)
                || latencyThreshold <= 0) {
            throw new IllegalArgumentException("Invalid latency threshold");
        }

        if (!Double.isFinite(packetLossThreshold)
                || packetLossThreshold <= 0
                || packetLossThreshold > 100) {
            throw new IllegalArgumentException(
                    "Invalid packet loss threshold");
        }

        if (horizonSeconds < 0) {
            throw new IllegalArgumentException(
                    "Invalid prediction horizon");
        }

        this.prbThreshold = prbThreshold;
        this.latencyThreshold = latencyThreshold;
        this.packetLossThreshold = packetLossThreshold;
        this.horizonSeconds = horizonSeconds;
    }

    public CongestionEvent evaluate(RanKpi kpi) {
        validateKpi(kpi);

        double score = calculateScore(kpi);

        CongestionEvent.CongestionLevel level;

        if (score >= 0.85) {
            level = CongestionEvent.CongestionLevel.CRITICAL;
        } else if (score >= 0.65) {
            level = CongestionEvent.CongestionLevel.HIGH;
        } else if (score >= 0.40) {
            level = CongestionEvent.CongestionLevel.MEDIUM;
        } else if (score >= 0.20) {
            level = CongestionEvent.CongestionLevel.LOW;
        } else {
            level = CongestionEvent.CongestionLevel.NORMAL;
        }

        CongestionEvent.CongestionType type =
                level == CongestionEvent.CongestionLevel.HIGH
                || level == CongestionEvent.CongestionLevel.CRITICAL
                ? CongestionEvent.CongestionType.DETECTED
                : CongestionEvent.CongestionType.PREDICTED;

        String reason = String.format(
                "score=%.3f; PRB=%.2f%%; latency=%.2fms; loss=%.2f%%",
                score,
                kpi.prbUtilizationPercent(),
                kpi.latencyMs(),
                kpi.packetLossPercent()
        );

        return new CongestionEvent(
                UUID.randomUUID().toString(),
                kpi.eventId(),
                Instant.now(),
                kpi.ranNodeId(),
                kpi.cellId(),
                kpi.sliceId(),
                level,
                type,
                score,
                kpi.prbUtilizationPercent(),
                kpi.latencyMs(),
                kpi.packetLossPercent(),
                kpi.activeUsers(),
                horizonSeconds,
                reason
        );
    }

    public double calculateScore(RanKpi kpi) {
        validateKpi(kpi);

        double prb = normalize(
                kpi.prbUtilizationPercent(), prbThreshold);

        double latency = normalize(
                kpi.latencyMs(), latencyThreshold);

        double loss = normalize(
                kpi.packetLossPercent(), packetLossThreshold);

        return Math.max(0.0, Math.min(1.0,
                0.50 * prb
                + 0.30 * latency
                + 0.20 * loss));
    }

    private double normalize(double value, double threshold) {
        return Math.max(
                0.0,
                Math.min(1.0, value / (2.0 * threshold))
        );
    }

    private void validateKpi(RanKpi kpi) {
        if (kpi == null) {
            throw new IllegalArgumentException("KPI must not be null");
        }

        validateRange(
                kpi.prbUtilizationPercent(), 0, 100, "PRB");

        validateRange(
                kpi.latencyMs(), 0, Double.MAX_VALUE, "Latency");

        validateRange(
                kpi.packetLossPercent(), 0, 100, "Packet loss");

        if (kpi.activeUsers() < 0) {
            throw new IllegalArgumentException(
                    "Active users must be >= 0");
        }
    }

    private void validateRange(
            double value,
            double min,
            double max,
            String field) {

        if (!Double.isFinite(value) || value < min || value > max) {
            throw new IllegalArgumentException(
                    "Invalid KPI field: " + field);
        }
    }
}
EOF

# ------------------------------------------------------------
# 2. CongestionProducer.java
# ------------------------------------------------------------

cat > "$PKG/producer/CongestionProducer.java" <<'EOF'
package org.example.ran.predictor.producer;

import org.onap.policy.ran.common.CongestionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.concurrent.CompletableFuture;

@Component
public class CongestionProducer {

    private static final Logger LOG =
            LoggerFactory.getLogger(CongestionProducer.class);

    private final KafkaTemplate<String, Object> kafkaTemplate;
    private final String topic;

    public CongestionProducer(
            KafkaTemplate<String, Object> kafkaTemplate,
            @Value("${ran.kafka.topics.congestion:ran.congestion}")
            String topic) {

        this.kafkaTemplate = kafkaTemplate;
        this.topic = topic;
    }

    public CompletableFuture<Void> publish(CongestionEvent event) {
        return kafkaTemplate.send(
                topic,
                event.cellId(),
                event
        ).thenAccept(result -> LOG.info(
                "Congestion published: cell={}, level={}, partition={}",
                event.cellId(),
                event.level(),
                result.getRecordMetadata().partition()
        ));
    }
}
EOF

# ------------------------------------------------------------
# 3. KpiConsumer.java
# ------------------------------------------------------------

cat > "$PKG/consumer/KpiConsumer.java" <<'EOF'
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
EOF

echo "Partie 5A/8 générée : moteur de prédiction et composants Kafka."


# ============================================================
# PARTIE 5B/8 — RAN PREDICTOR SERVICE
# Configuration Kafka, Spring Boot, POM et documentation
# Génération des fichiers uniquement.
# ============================================================

set -eu

BASE="ran-predictor-service"
PKG="$BASE/src/main/java/org/example/ran/predictor"

mkdir -p \
  "$PKG/config" \
  "$BASE/src/main/resources"

# ------------------------------------------------------------
# 4. KafkaConfig.java
# ------------------------------------------------------------

cat > "$PKG/config/KafkaConfig.java" <<'EOF'
package org.example.ran.predictor.config;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.onap.policy.ran.common.RanKpi;
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
    public ConsumerFactory<String, RanKpi> consumerFactory(
            @Value("${spring.kafka.bootstrap-servers:localhost:9092}")
            String bootstrapServers,
            @Value("${spring.kafka.consumer.group-id:ran-predictor-group}")
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

        JsonDeserializer<RanKpi> deserializer =
                new JsonDeserializer<>(RanKpi.class, false);

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
    public ConcurrentKafkaListenerContainerFactory<String, RanKpi>
    kafkaListenerContainerFactory(
            ConsumerFactory<String, RanKpi> consumerFactory) {

        ConcurrentKafkaListenerContainerFactory<String, RanKpi> factory =
                new ConcurrentKafkaListenerContainerFactory<>();

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
# 5. RanPredictorApplication.java
# ------------------------------------------------------------

cat > "$PKG/RanPredictorApplication.java" <<'EOF'
package org.example.ran.predictor;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(
        scanBasePackages = {
                "org.example.ran.predictor",
                "org.onap.policy.ran.common"
        }
)
public class RanPredictorApplication {

    public static void main(String[] args) {
        SpringApplication.run(
                RanPredictorApplication.class,
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
    name: ran-predictor-service

  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}
    consumer:
      group-id: ${KAFKA_CONSUMER_GROUP:ran-predictor-group}
      auto-offset-reset: earliest
      enable-auto-commit: false

server:
  port: ${SERVER_PORT:8081}

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
      kpi: ${RAN_KPI_TOPIC:ran.kpi}
      congestion: ${RAN_CONGESTION_TOPIC:ran.congestion}

  predictor:
    thresholds:
      prb-percent: ${RAN_PREDICTOR_PRB_THRESHOLD:80.0}
      latency-ms: ${RAN_PREDICTOR_LATENCY_THRESHOLD_MS:50.0}
      packet-loss-percent: ${RAN_PREDICTOR_PACKET_LOSS_THRESHOLD:1.0}
    horizon-seconds: ${RAN_PREDICTOR_HORIZON_SECONDS:30}

logging:
  level:
    root: INFO
    org.example.ran.predictor: INFO
EOF

# ------------------------------------------------------------
# 7. pom.xml du service
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

    <artifactId>ran-predictor-service</artifactId>
    <name>RAN Predictor Service</name>
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
# RAN Predictor Service

## Responsabilités

Le service consomme les KPI RAN depuis le topic Kafka `ran.kpi`,
calcule un score heuristique de congestion et publie un événement
sur le topic `ran.congestion`.

## Algorithme de démonstration

Le score est une combinaison pondérée :

- 50 % : utilisation PRB normalisée ;
- 30 % : latence normalisée ;
- 20 % : pertes de paquets normalisées.

La classification est déterminée par le score :

| Score | Niveau |
|---|---|
| < 0.20 | NORMAL |
| >= 0.20 | LOW |
| >= 0.40 | MEDIUM |
| >= 0.65 | HIGH |
| >= 0.85 | CRITICAL |

Ce score est un indicateur heuristique et non une probabilité
statistique calibrée. Il ne constitue pas un modèle prédictif
entraîné sur des données historiques.

## Configuration

| Variable | Valeur par défaut |
|---|---|
| KAFKA_BOOTSTRAP_SERVERS | localhost:9092 |
| KAFKA_CONSUMER_GROUP | ran-predictor-group |
| RAN_KPI_TOPIC | ran.kpi |
| RAN_CONGESTION_TOPIC | ran.congestion |
| RAN_PREDICTOR_PRB_THRESHOLD | 80.0 |
| RAN_PREDICTOR_LATENCY_THRESHOLD_MS | 50.0 |
| RAN_PREDICTOR_PACKET_LOSS_THRESHOLD | 1.0 |
| RAN_PREDICTOR_HORIZON_SECONDS | 30 |
| SERVER_PORT | 8081 |

## Observabilité

Les endpoints Actuator exposés sont :

- `/actuator/health`
- `/actuator/info`
- `/actuator/prometheus`

## Fiabilité et limites

Le consommateur utilise un mécanisme de reprise avec un délai
fixe. Une version de production devrait ajouter une dead-letter
topic, une gestion explicite des erreurs de publication, des tests
de contrat JSON et une stratégie d'idempotence métier.

La publication Kafka est asynchrone. Il faut coordonner les
offsets du consommateur avec la confirmation de publication pour
éviter de perdre un événement lors de certains incidents.

Le service ne commande pas directement les équipements RAN.
Les décisions sont transmises au service de contrôle.

## Intégration

Le projet dépend du module `ran-common`, qui fournit les classes
`RanKpi` et `CongestionEvent`.

Le POM parent doit définir les versions compatibles de Java,
Spring Boot et Spring Kafka.
EOF

echo "PARTIE 5B/8 : configuration du ran-predictor-service générée."
echo "Aucune compilation ou activation de service exécutée."
