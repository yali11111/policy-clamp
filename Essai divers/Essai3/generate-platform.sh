
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
