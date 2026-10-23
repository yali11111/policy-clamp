
#!/bin/sh
# ============================================================
# CLAMP-ACM-CI
# INSTALLATION PAR GENERATION DE FICHIERS
# PARTIE 1/4 : SOCLE MAVEN ET EVENEMENTS PARTAGES
#
# Aucune installation npm, Maven ou Python.
# Aucun démarrage Docker, Kafka ou Spring Boot.
# ============================================================

set -eu

ROOT="clamp-acm-ci"

echo "=========================================="
echo "CLAMP ACM CI - Partie 1/4"
echo "Generation du socle et des contrats"
echo "=========================================="

mkdir -p \
  "$ROOT/shared-events/src/main/java/com/clamp/acm/events" \
  "$ROOT/shared-events/src/main/resources/schema" \
  "$ROOT/monitoring-service/src/main/java/com/clamp/acm/monitoring/config" \
  "$ROOT/policy-engine-service/src/main/java/com/clamp/acm/policy/config" \
  "$ROOT/automation-controller-service/src/main/java/com/clamp/acm/automation/model" \
  "$ROOT/automation-controller-service/src/main/java/com/clamp/acm/automation/service" \
  "$ROOT/automation-controller-service/src/main/java/com/clamp/acm/automation/controller" \
  "$ROOT/kafka-config" \
  "$ROOT/tosca/policy-types" \
  "$ROOT/tosca/node-types" \
  "$ROOT/tosca/compositions" \
  "$ROOT/xtesting/smoke" \
  "$ROOT/scripts" \
  "$ROOT/docker" \
  "$ROOT/.github/workflows" \
  "$ROOT/helm/monitoring/templates" \
  "$ROOT/helm/policy-engine/templates" \
  "$ROOT/helm/automation-controller/templates"

# ------------------------------------------------------------
# 1. POM RACINE
# ------------------------------------------------------------

cat > "$ROOT/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <groupId>com.clamp.acm</groupId>
    <artifactId>clamp-acm-ci</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging>

    <name>CLAMP ACM CI</name>
    <description>
        Monitoring, policy evaluation and automation orchestration
        for ONAP CLAMP ACM integration.
    </description>

    <modules>
        <module>shared-events</module>
        <module>monitoring-service</module>
        <module>policy-engine-service</module>
        <module>automation-controller-service</module>
    </modules>

    <properties>
        <java.version>21</java.version>
        <maven.compiler.release>${java.version}</maven.compiler.release>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <spring-boot.version>3.4.5</spring-boot.version>
        <spring-kafka.version>3.3.5</spring-kafka.version>
        <kafka.version>3.9.0</kafka.version>
    </properties>

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
                <groupId>org.apache.kafka</groupId>
                <artifactId>kafka-streams</artifactId>
                <version>${kafka.version}</version>
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
# 2. MODULE EVENEMENTS PARTAGES
# ------------------------------------------------------------

cat > "$ROOT/shared-events/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.clamp.acm</groupId>
        <artifactId>clamp-acm-ci</artifactId>
        <version>1.0.0</version>
        <relativePath>../pom.xml</relativePath>
    </parent>

    <artifactId>shared-events</artifactId>
    <packaging>jar</packaging>
</project>
EOF

# ------------------------------------------------------------
# 3. EVENEMENT DE METRIQUES
# ------------------------------------------------------------

cat > "$ROOT/shared-events/src/main/java/com/clamp/acm/events/MetricsEvent.java" <<'EOF'
package com.clamp.acm.events;

import java.time.Instant;
import java.util.Map;
import java.util.Objects;

public record MetricsEvent(
        String eventId,
        String source,
        String target,
        Instant timestamp,
        Map<String, Double> metrics,
        Map<String, String> attributes
) {
    public MetricsEvent {
        Objects.requireNonNull(eventId, "eventId is required");
        Objects.requireNonNull(source, "source is required");
        Objects.requireNonNull(target, "target is required");
        Objects.requireNonNull(timestamp, "timestamp is required");
        Objects.requireNonNull(metrics, "metrics is required");

        if (eventId.isBlank() || source.isBlank() || target.isBlank()) {
            throw new IllegalArgumentException(
                    "Identifiers must not be blank");
        }

        metrics = Map.copyOf(metrics);
        attributes = attributes == null
                ? Map.of()
                : Map.copyOf(attributes);

        metrics.forEach((name, value) -> {
            if (name == null || name.isBlank()
                    || value == null || !Double.isFinite(value)) {
                throw new IllegalArgumentException(
                        "Metric names and finite values are required");
            }
        });
    }
}
EOF

# ------------------------------------------------------------
# 4. EVENEMENT DE DECISION DE POLITIQUE
# ------------------------------------------------------------

cat > "$ROOT/shared-events/src/main/java/com/clamp/acm/events/PolicyDecisionEvent.java" <<'EOF'
package com.clamp.acm.events;

import java.time.Instant;
import java.util.Map;
import java.util.Objects;

public record PolicyDecisionEvent(
        String decisionId,
        String sourceEventId,
        String policyId,
        String target,
        Decision decision,
        String reason,
        Instant timestamp,
        Map<String, String> parameters
) {
    public enum Decision {
        NO_ACTION,
        SCALE_OUT,
        SCALE_IN,
        TRAFFIC_STEERING,
        CONFIGURATION_CHANGE,
        MANUAL_REVIEW
    }

    public PolicyDecisionEvent {
        Objects.requireNonNull(decisionId, "decisionId is required");
        Objects.requireNonNull(sourceEventId, "sourceEventId is required");
        Objects.requireNonNull(policyId, "policyId is required");
        Objects.requireNonNull(target, "target is required");
        Objects.requireNonNull(decision, "decision is required");
        Objects.requireNonNull(timestamp, "timestamp is required");

        if (decisionId.isBlank()
                || sourceEventId.isBlank()
                || policyId.isBlank()
                || target.isBlank()) {
            throw new IllegalArgumentException(
                    "Decision identifiers must not be blank");
        }

        reason = reason == null ? "" : reason;
        parameters = parameters == null
                ? Map.of()
                : Map.copyOf(parameters);
    }
}
EOF

# ------------------------------------------------------------
# 5. SCHEMA JSON : METRICS
# ------------------------------------------------------------

cat > "$ROOT/shared-events/src/main/resources/schema/metrics-event.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "MetricsEvent",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "eventId",
    "source",
    "target",
    "timestamp",
    "metrics"
  ],
  "properties": {
    "eventId": {
      "type": "string",
      "minLength": 1
    },
    "source": {
      "type": "string",
      "minLength": 1
    },
    "target": {
      "type": "string",
      "minLength": 1
    },
    "timestamp": {
      "type": "string",
      "format": "date-time"
    },
    "metrics": {
      "type": "object",
      "additionalProperties": {
        "type": "number"
      }
    },
    "attributes": {
      "type": "object",
      "additionalProperties": {
        "type": "string"
      }
    }
  }
}
EOF

# ------------------------------------------------------------
# 6. SCHEMA JSON : DECISION
# ------------------------------------------------------------

cat > "$ROOT/shared-events/src/main/resources/schema/policy-decision-event.schema.json" <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "PolicyDecisionEvent",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "decisionId",
    "sourceEventId",
    "policyId",
    "target",
    "decision",
    "timestamp"
  ],
  "properties": {
    "decisionId": {
      "type": "string",
      "minLength": 1
    },
    "sourceEventId": {
      "type": "string",
      "minLength": 1
    },
    "policyId": {
      "type": "string",
      "minLength": 1
    },
    "target": {
      "type": "string",
      "minLength": 1
    },
    "decision": {
      "type": "string",
      "enum": [
        "NO_ACTION",
        "SCALE_OUT",
        "SCALE_IN",
        "TRAFFIC_STEERING",
        "CONFIGURATION_CHANGE",
        "MANUAL_REVIEW"
      ]
    },
    "reason": {
      "type": "string"
    },
    "timestamp": {
      "type": "string",
      "format": "date-time"
    },
    "parameters": {
      "type": "object",
      "additionalProperties": {
        "type": "string"
      }
    }
  }
}
EOF

# ------------------------------------------------------------
# 7. CONTRATS ET FLUX
# ------------------------------------------------------------

cat > "$ROOT/shared-events/EventSchemas.md" <<'EOF'
# Contrats d'événements

Les messages sont encodés en JSON UTF-8.

## Topics

| Topic | Producteur | Consommateur |
|---|---|---|
| acm.metrics | monitoring-service | policy-engine-service |
| acm.policy-decisions | policy-engine-service | automation-controller-service |
| acm.automation-results | automation-controller-service | observabilité |

## MetricsEvent

Champs obligatoires :
- eventId : identifiant unique de l'événement.
- source : nom du producteur.
- target : cible de la mesure.
- timestamp : date ISO-8601.
- metrics : valeurs numériques finies.
- attributes : métadonnées textuelles facultatives.

Les unités doivent être indiquées dans les noms des métriques,
par exemple latencyMs ou cpuUtilizationPct.

## PolicyDecisionEvent

Champs obligatoires :
- decisionId
- sourceEventId
- policyId
- target
- decision
- timestamp

Les décisions possibles sont :
NO_ACTION, SCALE_OUT, SCALE_IN, TRAFFIC_STEERING,
CONFIGURATION_CHANGE et MANUAL_REVIEW.

Une décision n'autorise pas automatiquement une action réelle.
Le contrôleur doit vérifier les politiques de sécurité,
les autorisations et les limites opérationnelles.

## Compatibilité

Toute modification des contrats doit être coordonnée entre
producteurs et consommateurs. Les secrets ne doivent jamais
être transmis dans les événements.
EOF

# ------------------------------------------------------------
# 8. README INITIAL
# ------------------------------------------------------------

cat > "$ROOT/README.md" <<'EOF'
# CLAMP ACM CI

Projet de référence pour la supervision, les décisions de
politiques et l'orchestration contrôlée d'automatisations.

## Modules

- shared-events : contrats d'événements communs.
- monitoring-service : collecte et publication des métriques.
- policy-engine-service : traitement Kafka Streams.
- automation-controller-service : validation et orchestration.
- kafka-config : configuration des topics Kafka.
- tosca : types et compositions ACM.
- xtesting : tests de fumée.
- docker : définitions de conteneurs.
- helm : déploiement Kubernetes.
- .github/workflows : pipelines CI/CD.

## Flux

1. Monitoring publie les métriques.
2. Le moteur de politiques analyse les événements.
3. Une décision est publiée sur Kafka.
4. Le contrôleur valide la demande.
5. Une action autorisée est transmise à l'adaptateur concerné.
6. Le résultat est enregistré pour assurer la traçabilité.

## ONAP et CLAMP

Les fichiers TOSCA devront être adaptés à la version ONAP/ACM
réellement installée. La présence des fichiers ne garantit pas
leur acceptation par le contrôleur ACM.

## Sécurité

- Ne pas exposer Kafka directement aux interfaces utilisateur.
- Configurer TLS et les ACL Kafka.
- Valider les paramètres des actions.
- Utiliser des identifiants idempotents.
- Prévoir des contrôles d'autorisation et une piste d'audit.
- Exiger une validation appropriée pour les actions sensibles.

## Génération

Le script crée des fichiers uniquement.
Il n'installe aucune dépendance et ne démarre aucun service.
EOF

# ------------------------------------------------------------
# 9. VERIFICATIONS STATIQUES
# ------------------------------------------------------------

echo ""
echo "Verification de la partie 1/4"

for FILE in \
  "$ROOT/pom.xml" \
  "$ROOT/shared-events/pom.xml" \
  "$ROOT/shared-events/src/main/java/com/clamp/acm/events/MetricsEvent.java" \
  "$ROOT/shared-events/src/main/java/com/clamp/acm/events/PolicyDecisionEvent.java" \
  "$ROOT/shared-events/src/main/resources/schema/metrics-event.schema.json" \
  "$ROOT/shared-events/src/main/resources/schema/policy-decision-event.schema.json" \
  "$ROOT/shared-events/EventSchemas.md" \
  "$ROOT/README.md"
do
  if [ -f "$FILE" ]; then
    echo "OK : $FILE"
  else
    echo "ERREUR : $FILE"
    exit 1
  fi
done

echo ""
echo "Partie 1/4 terminee."
echo "Aucune dependance installee."
echo "Aucune compilation executee."
echo "Aucun service demarre."


# ============================================================
# CLAMP ACM CI - PARTIE 2/4 - SOUS-PARTIE 1/4
# Module partage : contrats d'evenements Kafka
# ============================================================

set -eu

ROOT="clamp-acm-ci"
SHARED="$ROOT/shared-events"

echo "[1/4] Creation des contrats d'evenements partages"

mkdir -p "$SHARED/src/main/java/com/clamp/acm/events"

# ------------------------------------------------------------
# 1. POM DU MODULE SHARED-EVENTS
# ------------------------------------------------------------

cat > "$SHARED/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.clamp.acm</groupId>
        <artifactId>clamp-acm-ci</artifactId>
        <version>1.0.0</version>
        <relativePath>../pom.xml</relativePath>
    </parent>

    <artifactId>shared-events</artifactId>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-annotations</artifactId>
        </dependency>
    </dependencies>
</project>
EOF

# ------------------------------------------------------------
# 2. EVENEMENT DE METRIQUES
# ------------------------------------------------------------

cat > "$SHARED/src/main/java/com/clamp/acm/events/MetricsEvent.java" <<'EOF'
package com.clamp.acm.events;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.Instant;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;

/**
 * Evenement de metriques publie par le service de monitoring.
 *
 * Les valeurs sont numeriques et exprimees dans les unites
 * definies par le contrat EventSchemas.md.
 */
public record MetricsEvent(
        String eventId,
        String source,
        String target,
        Instant timestamp,
        Map<String, Double> metrics,
        Map<String, String> attributes) {

    @JsonCreator
    public MetricsEvent(
            @JsonProperty("eventId") String eventId,
            @JsonProperty("source") String source,
            @JsonProperty("target") String target,
            @JsonProperty("timestamp") Instant timestamp,
            @JsonProperty("metrics") Map<String, Double> metrics,
            @JsonProperty("attributes") Map<String, String> attributes) {

        this.eventId = requireText(eventId, "eventId");
        this.source = requireText(source, "source");
        this.target = requireText(target, "target");
        this.timestamp = Objects.requireNonNull(
                timestamp, "timestamp is required");

        this.metrics = immutableMetrics(metrics);
        this.attributes = immutableAttributes(attributes);
    }

    private static String requireText(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    name + " must not be blank");
        }
        return value;
    }

    private static Map<String, Double> immutableMetrics(
            Map<String, Double> input) {

        Map<String, Double> copy = new LinkedHashMap<>();

        if (input != null) {
            input.forEach((key, value) -> {
                if (key == null || key.isBlank()) {
                    throw new IllegalArgumentException(
                            "Metric name must not be blank");
                }
                if (value == null || !Double.isFinite(value)) {
                    throw new IllegalArgumentException(
                            "Metric value must be finite: " + key);
                }
                copy.put(key, value);
            });
        }

        return Collections.unmodifiableMap(copy);
    }

    private static Map<String, String> immutableAttributes(
            Map<String, String> input) {

        Map<String, String> copy = new LinkedHashMap<>();

        if (input != null) {
            input.forEach((key, value) -> {
                if (key == null || key.isBlank() || value == null) {
                    throw new IllegalArgumentException(
                            "Invalid attribute");
                }
                copy.put(key, value);
            });
        }

        return Collections.unmodifiableMap(copy);
    }
}
EOF

# ------------------------------------------------------------
# 3. EVENEMENT DE DECISION DE POLITIQUE
# ------------------------------------------------------------

cat > "$SHARED/src/main/java/com/clamp/acm/events/PolicyDecisionEvent.java" <<'EOF'
package com.clamp.acm.events;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.Instant;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;

/**
 * Decision publiee par le moteur de politiques.
 *
 * Une decision n'autorise pas automatiquement une operation
 * destructive : le controleur doit appliquer ses propres
 * validations, limites et controles de securite.
 */
public record PolicyDecisionEvent(
        String decisionId,
        String sourceEventId,
        String policyId,
        String target,
        Decision decision,
        String reason,
        Instant timestamp,
        Map<String, String> evidence) {

    public enum Decision {
        NO_ACTION,
        MANUAL_REVIEW,
        SCALE_OUT_REQUESTED,
        SCALE_IN_REQUESTED,
        TRAFFIC_STEERING_REQUESTED
    }

    @JsonCreator
    public PolicyDecisionEvent(
            @JsonProperty("decisionId") String decisionId,
            @JsonProperty("sourceEventId") String sourceEventId,
            @JsonProperty("policyId") String policyId,
            @JsonProperty("target") String target,
            @JsonProperty("decision") Decision decision,
            @JsonProperty("reason") String reason,
            @JsonProperty("timestamp") Instant timestamp,
            @JsonProperty("evidence") Map<String, String> evidence) {

        this.decisionId = requireText(decisionId, "decisionId");
        this.sourceEventId = requireText(
                sourceEventId, "sourceEventId");
        this.policyId = requireText(policyId, "policyId");
        this.target = requireText(target, "target");
        this.decision = Objects.requireNonNull(
                decision, "decision is required");
        this.reason = requireText(reason, "reason");
        this.timestamp = Objects.requireNonNull(
                timestamp, "timestamp is required");

        Map<String, String> copy = new LinkedHashMap<>();

        if (evidence != null) {
            evidence.forEach((key, value) -> {
                if (key == null || key.isBlank() || value == null) {
                    throw new IllegalArgumentException(
                            "Invalid evidence entry");
                }
                copy.put(key, value);
            });
        }

        this.evidence = Collections.unmodifiableMap(copy);
    }

    private static String requireText(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    name + " must not be blank");
        }
        return value;
    }
}
EOF

# ------------------------------------------------------------
# 4. DOCUMENTATION DES CONTRATS KAFKA
# ------------------------------------------------------------

cat > "$SHARED/EventSchemas.md" <<'EOF'
# Contrats d'evenements CLAMP ACM CI

## Convention generale

- Format : JSON UTF-8.
- Horodatage : ISO-8601 UTC.
- Les identifiants d'evenements doivent etre uniques.
- Les consommateurs doivent tolerer les champs optionnels inconnus.
- Les producteurs ne doivent pas publier de secrets ou de donnees
  personnelles dans les attributs.
- Toute evolution incompatible necessite une strategie de migration.

## Topic acm.metrics

Cle Kafka recommandee : target.

Exemple :

{
  "eventId": "evt-001",
  "source": "monitoring-service",
  "target": "demo-cell-001",
  "timestamp": "2026-01-01T12:00:00Z",
  "metrics": {
    "cpuUtilizationPct": 65.0,
    "latencyMs": 20.0,
    "throughputMbps": 100.0
  },
  "attributes": {
    "origin": "scheduled-monitoring"
  }
}

Unites :

- cpuUtilizationPct : pourcentage, de 0 a 100.
- latencyMs : millisecondes.
- throughputMbps : megabits par seconde.

Les noms des metriques sont sensibles a la casse.

## Topic acm.policy-decisions

Cle Kafka recommandee : target.

Exemple :

{
  "decisionId": "decision-001",
  "sourceEventId": "evt-001",
  "policyId": "default-observation",
  "target": "demo-cell-001",
  "decision": "NO_ACTION",
  "reason": "Metrics are within configured thresholds",
  "timestamp": "2026-01-01T12:00:01Z",
  "evidence": {
    "cpuUtilizationPct": "65.0",
    "latencyMs": "20.0"
  }
}

Valeurs possibles de decision :

- NO_ACTION
- MANUAL_REVIEW
- SCALE_OUT_REQUESTED
- SCALE_IN_REQUESTED
- TRAFFIC_STEERING_REQUESTED

## Securite des decisions

Une decision Kafka est une demande ou une recommandation,
pas une preuve d'autorisation.

Avant toute action, le service d'automatisation doit :

1. Valider la decision et la cible.
2. Appliquer une liste d'actions autorisees.
3. Verifier les limites operationnelles.
4. Refuser les commandes inconnues ou mal formees.
5. Enregistrer le resultat et l'identifiant de correlation.

Les actions sur une infrastructure ONAP reelle doivent etre
protegees par une authentification, des autorisations et une
validation operationnelle explicites.
EOF

# ------------------------------------------------------------
# 5. VERIFICATION LOCALE
# ------------------------------------------------------------

for FILE in \
  "$SHARED/pom.xml" \
  "$SHARED/src/main/java/com/clamp/acm/events/MetricsEvent.java" \
  "$SHARED/src/main/java/com/clamp/acm/events/PolicyDecisionEvent.java" \
  "$SHARED/EventSchemas.md"
do
    if [ ! -s "$FILE" ]; then
        echo "ERREUR : fichier absent ou vide : $FILE"
        exit 1
    fi
done

echo "[1/4] Contrats partages crees."
echo "Aucune dependance installee."
echo "Aucune commande npm, Maven ou Docker executee."


# ============================================================
# CLAMP ACM CI - PARTIE 2/4 - SOUS-PARTIE 2/4
# Service de monitoring Spring Boot + Kafka
# ============================================================

set -eu

ROOT="clamp-acm-ci"
MON="$ROOT/monitoring-service"

echo "[2/4] Creation du monitoring-service"

mkdir -p \
  "$MON/src/main/java/com/clamp/acm/monitoring/config" \
  "$MON/src/main/resources"

# ------------------------------------------------------------
# 1. POM DU SERVICE
# ------------------------------------------------------------

cat > "$MON/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.clamp.acm</groupId>
        <artifactId>clamp-acm-ci</artifactId>
        <version>1.0.0</version>
        <relativePath>../pom.xml</relativePath>
    </parent>

    <artifactId>monitoring-service</artifactId>

    <dependencies>
        <dependency>
            <groupId>com.clamp.acm</groupId>
            <artifactId>shared-events</artifactId>
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
    </dependencies>
</project>
EOF

# ------------------------------------------------------------
# 2. CLASSE PRINCIPALE
# ------------------------------------------------------------

cat > "$MON/src/main/java/com/clamp/acm/monitoring/MonitoringApplication.java" <<'EOF'
package com.clamp.acm.monitoring;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class MonitoringApplication {

    public static void main(String[] args) {
        SpringApplication.run(MonitoringApplication.class, args);
    }
}
EOF

# ------------------------------------------------------------
# 3. CONFIGURATION DU PRODUCTEUR KAFKA
# ------------------------------------------------------------

cat > "$MON/src/main/java/com/clamp/acm/monitoring/config/KafkaConfig.java" <<'EOF'
package com.clamp.acm.monitoring.config;

import com.clamp.acm.events.MetricsEvent;
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
    public ProducerFactory<String, MetricsEvent> metricsProducerFactory(
            @Value("${spring.kafka.bootstrap-servers:localhost:9092}")
            String bootstrapServers) {

        Map<String, Object> properties = new HashMap<>();

        properties.put(
                ProducerConfig.BOOTSTRAP_SERVERS_CONFIG,
                bootstrapServers);
        properties.put(
                ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG,
                StringSerializer.class);
        properties.put(
                ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG,
                JsonSerializer.class);
        properties.put(ProducerConfig.ACKS_CONFIG, "all");
        properties.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);
        properties.put(ProducerConfig.RETRIES_CONFIG, 10);

        return new DefaultKafkaProducerFactory<>(properties);
    }

    @Bean
    public KafkaTemplate<String, MetricsEvent> metricsKafkaTemplate(
            ProducerFactory<String, MetricsEvent> metricsProducerFactory) {

        return new KafkaTemplate<>(metricsProducerFactory);
    }
}
EOF

# ------------------------------------------------------------
# 4. PRODUCTEUR DE METRIQUES
# ------------------------------------------------------------

cat > "$MON/src/main/java/com/clamp/acm/monitoring/MonitoringProducer.java" <<'EOF'
package com.clamp.acm.monitoring;

import com.clamp.acm.events.MetricsEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

@Service
public class MonitoringProducer {

    private static final Logger log =
            LoggerFactory.getLogger(MonitoringProducer.class);

    private final KafkaTemplate<String, MetricsEvent> kafkaTemplate;
    private final String topic;

    public MonitoringProducer(
            KafkaTemplate<String, MetricsEvent> kafkaTemplate,
            @Value("${acm.kafka.metrics-topic:acm.metrics}")
            String topic) {
        this.kafkaTemplate = kafkaTemplate;
        this.topic = topic;
    }

    public CompletableFuture<?> publish(
            String target,
            Map<String, Double> metrics) {

        MetricsEvent event = new MetricsEvent(
                UUID.randomUUID().toString(),
                "monitoring-service",
                target,
                Instant.now(),
                metrics,
                Map.of("origin", "scheduled-monitoring")
        );

        return kafkaTemplate.send(topic, target, event)
                .whenComplete((result, error) -> {
                    if (error != null) {
                        log.error(
                                "Publication Kafka impossible pour {}",
                                target,
                                error);
                    } else {
                        log.debug(
                                "Evenement {} publie sur {}",
                                event.eventId(),
                                topic);
                    }
                });
    }
}
EOF

# ------------------------------------------------------------
# 5. COLLECTEUR DE METRIQUES
# ------------------------------------------------------------

cat > "$MON/src/main/java/com/clamp/acm/monitoring/MonitoringScheduler.java" <<'EOF'
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
EOF

# ------------------------------------------------------------
# 6. CONFIGURATION SPRING BOOT
# ------------------------------------------------------------

cat > "$MON/src/main/resources/application.yml" <<'EOF'
spring:
  application:
    name: monitoring-service

  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}

acm:
  kafka:
    metrics-topic: ${ACM_METRICS_TOPIC:acm.metrics}

  monitoring:
    target: ${ACM_MONITORING_TARGET:demo-cell-001}
    interval-ms: ${ACM_MONITORING_INTERVAL_MS:10000}

management:
  endpoints:
    web:
      exposure:
        include: health,info

  endpoint:
    health:
      show-details: never
EOF

# ------------------------------------------------------------
# 7. VERIFICATION DES FICHIERS
# ------------------------------------------------------------

for FILE in \
  "$MON/pom.xml" \
  "$MON/src/main/java/com/clamp/acm/monitoring/MonitoringApplication.java" \
  "$MON/src/main/java/com/clamp/acm/monitoring/MonitoringProducer.java" \
  "$MON/src/main/java/com/clamp/acm/monitoring/MonitoringScheduler.java" \
  "$MON/src/main/java/com/clamp/acm/monitoring/config/KafkaConfig.java" \
  "$MON/src/main/resources/application.yml"
do
    if [ ! -s "$FILE" ]; then
        echo "ERREUR : fichier absent ou vide : $FILE"
        exit 1
    fi
done

echo "[2/4] monitoring-service cree."
echo "Aucune compilation, installation ou execution effectuee."


# ============================================================
# CLAMP ACM CI - PARTIE 2/4 - SOUS-PARTIE 3/4
# Policy Engine Spring Boot + Kafka Streams
# ============================================================

set -eu

ROOT="clamp-acm-ci"
POLICY="$ROOT/policy-engine-service"

echo "[3/4] Creation du policy-engine-service"

mkdir -p \
  "$POLICY/src/main/java/com/clamp/acm/policy/config" \
  "$POLICY/src/main/resources"

# ------------------------------------------------------------
# 1. POM DU SERVICE
# ------------------------------------------------------------

cat > "$POLICY/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.clamp.acm</groupId>
        <artifactId>clamp-acm-ci</artifactId>
        <version>1.0.0</version>
        <relativePath>../pom.xml</relativePath>
    </parent>

    <artifactId>policy-engine-service</artifactId>

    <dependencies>
        <dependency>
            <groupId>com.clamp.acm</groupId>
            <artifactId>shared-events</artifactId>
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
            <groupId>org.apache.kafka</groupId>
            <artifactId>kafka-streams</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
    </dependencies>
</project>
EOF

# ------------------------------------------------------------
# 2. CLASSE PRINCIPALE
# ------------------------------------------------------------

cat > "$POLICY/src/main/java/com/clamp/acm/policy/PolicyApplication.java" <<'EOF'
package com.clamp.acm.policy;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class PolicyApplication {

    public static void main(String[] args) {
        SpringApplication.run(PolicyApplication.class, args);
    }
}
EOF

# ------------------------------------------------------------
# 3. CONFIGURATION KAFKA STREAMS
# ------------------------------------------------------------

cat > "$POLICY/src/main/java/com/clamp/acm/policy/config/KafkaStreamsConfig.java" <<'EOF'
package com.clamp.acm.policy.config;

import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.StreamsConfig;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafkaStreams;
import org.springframework.kafka.config.KafkaStreamsConfiguration;

import java.util.HashMap;
import java.util.Map;

@Configuration
@EnableKafkaStreams
public class KafkaStreamsConfig {

    @Bean(name = "defaultKafkaStreamsConfig")
    public KafkaStreamsConfiguration kafkaStreamsConfiguration(
            @Value("${spring.kafka.bootstrap-servers:localhost:9092}")
            String bootstrapServers,
            @Value("${spring.kafka.streams.application-id:acm-policy-engine}")
            String applicationId) {

        Map<String, Object> properties = new HashMap<>();

        properties.put(
                StreamsConfig.APPLICATION_ID_CONFIG,
                applicationId);
        properties.put(
                StreamsConfig.BOOTSTRAP_SERVERS_CONFIG,
                bootstrapServers);
        properties.put(
                StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG,
                Serdes.StringSerde.class);
        properties.put(
                StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG,
                Serdes.StringSerde.class);
        properties.put(
                StreamsConfig.PROCESSING_GUARANTEE_CONFIG,
                StreamsConfig.AT_LEAST_ONCE);

        return new KafkaStreamsConfiguration(properties);
    }
}
EOF

# ------------------------------------------------------------
# 4. MOTEUR DE DECISION
# ------------------------------------------------------------

cat > "$POLICY/src/main/java/com/clamp/acm/policy/PolicyStreamProcessor.java" <<'EOF'
package com.clamp.acm.policy;

import com.clamp.acm.events.MetricsEvent;
import com.clamp.acm.events.PolicyDecisionEvent;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Component
public class PolicyStreamProcessor {

    private final double cpuThreshold;
    private final double latencyThresholdMs;

    public PolicyStreamProcessor(
            @Value("${acm.policy.cpu-threshold:80.0}")
            double cpuThreshold,
            @Value("${acm.policy.latency-threshold-ms:100.0}")
            double latencyThresholdMs) {

        if (cpuThreshold < 0 || cpuThreshold > 100) {
            throw new IllegalArgumentException(
                    "CPU threshold must be between 0 and 100");
        }

        if (latencyThresholdMs < 0) {
            throw new IllegalArgumentException(
                    "Latency threshold must not be negative");
        }

        this.cpuThreshold = cpuThreshold;
        this.latencyThresholdMs = latencyThresholdMs;
    }

    public PolicyDecisionEvent evaluate(MetricsEvent event) {
        if (event == null) {
            return null;
        }

        double cpu = event.metrics()
                .getOrDefault("cpuUtilizationPct", 0.0);

        double latency = event.metrics()
                .getOrDefault("latencyMs", 0.0);

        PolicyDecisionEvent.Decision decision;
        String policyId;
        String reason;

        if (cpu >= cpuThreshold) {
            decision =
                    PolicyDecisionEvent.Decision.MANUAL_REVIEW;
            policyId = "high-cpu-review";
            reason =
                    "CPU threshold exceeded; manual review required";
        } else if (latency >= latencyThresholdMs) {
            decision =
                    PolicyDecisionEvent.Decision.MANUAL_REVIEW;
            policyId = "high-latency-review";
            reason =
                    "Latency threshold exceeded; manual review required";
        } else {
            decision = PolicyDecisionEvent.Decision.NO_ACTION;
            policyId = "default-observation";
            reason =
                    "Metrics are within configured thresholds";
        }

        return new PolicyDecisionEvent(
                UUID.randomUUID().toString(),
                event.eventId(),
                policyId,
                event.target(),
                decision,
                reason,
                Instant.now(),
                Map.of(
                        "cpuUtilizationPct", Double.toString(cpu),
                        "latencyMs", Double.toString(latency)
                )
        );
    }
}
EOF

# ------------------------------------------------------------
# 5. TOPOLOGIE KAFKA STREAMS
# ------------------------------------------------------------

cat > "$POLICY/src/main/java/com/clamp/acm/policy/PolicyTopology.java" <<'EOF'
package com.clamp.acm.policy;

import com.clamp.acm.events.MetricsEvent;
import com.clamp.acm.events.PolicyDecisionEvent;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.Produced;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.support.serializer.JsonSerde;

@Configuration
public class PolicyTopology {

    @Bean
    public Topology policyStreamTopology(
            StreamsBuilder builder,
            PolicyStreamProcessor processor,
            @Value("${acm.kafka.metrics-topic:acm.metrics}")
            String metricsTopic,
            @Value("${acm.kafka.decisions-topic:acm.policy-decisions}")
            String decisionsTopic) {

        JsonSerde<MetricsEvent> metricsSerde =
                new JsonSerde<>(MetricsEvent.class);

        JsonSerde<PolicyDecisionEvent> decisionSerde =
                new JsonSerde<>(PolicyDecisionEvent.class);

        builder.stream(
                    metricsTopic,
                    Consumed.with(Serdes.String(), metricsSerde))
                .mapValues(processor::evaluate)
                .filter((key, decision) -> decision != null)
                .to(
                    decisionsTopic,
                    Produced.with(Serdes.String(), decisionSerde));

        return builder.build();
    }
}
EOF

# ------------------------------------------------------------
# 6. CONFIGURATION DU SERVICE
# ------------------------------------------------------------

cat > "$POLICY/src/main/resources/application.yml" <<'EOF'
spring:
  application:
    name: policy-engine-service

  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}

    streams:
      application-id: ${KAFKA_STREAMS_APPLICATION_ID:acm-policy-engine}

acm:
  kafka:
    metrics-topic: ${ACM_METRICS_TOPIC:acm.metrics}
    decisions-topic: ${ACM_DECISIONS_TOPIC:acm.policy-decisions}

  policy:
    cpu-threshold: ${ACM_POLICY_CPU_THRESHOLD:80.0}
    latency-threshold-ms: ${ACM_POLICY_LATENCY_THRESHOLD_MS:100.0}

management:
  endpoints:
    web:
      exposure:
        include: health,info

  endpoint:
    health:
      show-details: never
EOF

# ------------------------------------------------------------
# 7. VERIFICATION DES FICHIERS
# ------------------------------------------------------------

for FILE in \
  "$POLICY/pom.xml" \
  "$POLICY/src/main/java/com/clamp/acm/policy/PolicyApplication.java" \
  "$POLICY/src/main/java/com/clamp/acm/policy/PolicyStreamProcessor.java" \
  "$POLICY/src/main/java/com/clamp/acm/policy/PolicyTopology.java" \
  "$POLICY/src/main/java/com/clamp/acm/policy/config/KafkaStreamsConfig.java" \
  "$POLICY/src/main/resources/application.yml"
do
    if [ ! -s "$FILE" ]; then
        echo "ERREUR : fichier absent ou vide : $FILE"
        exit 1
    fi
done

echo "[3/4] policy-engine-service cree."
echo "Aucune compilation ni installation effectuee."
EOF


# ============================================================
# CLAMP ACM CI - PARTIE 2/4 - SOUS-PARTIE 4/4
# Controleur d'automatisation Spring Boot + Kafka + REST
# ============================================================

set -eu

ROOT="clamp-acm-ci"
AUTO="$ROOT/automation-controller-service"

echo "[4/4] Creation de automation-controller-service"

mkdir -p \
  "$AUTO/src/main/java/com/clamp/acm/automation/model" \
  "$AUTO/src/main/java/com/clamp/acm/automation/service" \
  "$AUTO/src/main/java/com/clamp/acm/automation/controller" \
  "$AUTO/src/main/resources"

# ------------------------------------------------------------
# 1. POM DU SERVICE
# ------------------------------------------------------------

cat > "$AUTO/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.clamp.acm</groupId>
        <artifactId>clamp-acm-ci</artifactId>
        <version>1.0.0</version>
        <relativePath>../pom.xml</relativePath>
    </parent>

    <artifactId>automation-controller-service</artifactId>

    <dependencies>
        <dependency>
            <groupId>com.clamp.acm</groupId>
            <artifactId>shared-events</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.kafka</groupId>
            <artifactId>spring-kafka</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
    </dependencies>
</project>
EOF

# ------------------------------------------------------------
# 2. CLASSE PRINCIPALE
# ------------------------------------------------------------

cat > "$AUTO/src/main/java/com/clamp/acm/automation/AutomationApplication.java" <<'EOF'
package com.clamp.acm.automation;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class AutomationApplication {

    public static void main(String[] args) {
        SpringApplication.run(AutomationApplication.class, args);
    }
}
EOF

# ------------------------------------------------------------
# 3. MODELE DE REQUETE
# ------------------------------------------------------------

cat > "$AUTO/src/main/java/com/clamp/acm/automation/model/AutomationRequest.java" <<'EOF'
package com.clamp.acm.automation.model;

import java.util.Objects;

public record AutomationRequest(
        String target,
        String actionType,
        String requestedBy,
        String reason) {

    public AutomationRequest {
        target = requireText(target, "target");
        actionType = requireText(actionType, "actionType");
        requestedBy = requireText(requestedBy, "requestedBy");
        reason = requireText(reason, "reason");

        if (target.length() > 200) {
            throw new IllegalArgumentException("target is too long");
        }

        if (reason.length() > 1000) {
            throw new IllegalArgumentException("reason is too long");
        }

        if (!Objects.equals(actionType, actionType.toUpperCase())) {
            throw new IllegalArgumentException(
                    "actionType must use uppercase characters");
        }
    }

    private static String requireText(String value, String field) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    field + " must not be blank");
        }
        return value.trim();
    }
}
EOF

# ------------------------------------------------------------
# 4. MODELE DE REPONSE
# ------------------------------------------------------------

cat > "$AUTO/src/main/java/com/clamp/acm/automation/model/AutomationResponse.java" <<'EOF'
package com.clamp.acm.automation.model;

import java.time.Instant;

public record AutomationResponse(
        String requestId,
        String target,
        String actionType,
        String status,
        String message,
        Instant createdAt) {
}
EOF

# ------------------------------------------------------------
# 5. SERVICE D'AUTOMATISATION
# ------------------------------------------------------------

cat > "$AUTO/src/main/java/com/clamp/acm/automation/service/AutomationService.java" <<'EOF'
package com.clamp.acm.automation.service;

import com.clamp.acm.automation.model.AutomationRequest;
import com.clamp.acm.automation.model.AutomationResponse;
import com.clamp.acm.events.PolicyDecisionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class AutomationService {

    private static final Logger log =
            LoggerFactory.getLogger(AutomationService.class);

    private static final List<String> ALLOWED_ACTIONS = List.of(
            "SCALE_OUT",
            "SCALE_IN",
            "TRAFFIC_STEERING",
            "NETWORK_CONFIG"
    );

    private final Map<String, AutomationResponse> requests =
            new ConcurrentHashMap<>();

    private final boolean executionEnabled;

    public AutomationService(
            @Value("${acm.automation.execution-enabled:false}")
            boolean executionEnabled) {
        this.executionEnabled = executionEnabled;
    }

    public AutomationResponse submit(AutomationRequest request) {
        if (!ALLOWED_ACTIONS.contains(request.actionType())) {
            throw new IllegalArgumentException(
                    "Action not allowed: " + request.actionType());
        }

        String id = UUID.randomUUID().toString();
        Instant now = Instant.now();

        String status = executionEnabled
                ? "ACCEPTED"
                : "SIMULATION_ONLY";

        String message = executionEnabled
                ? "Request accepted; execution adapter must validate target."
                : "Simulation only; no network operation was executed.";

        AutomationResponse response = new AutomationResponse(
                id,
                request.target(),
                request.actionType(),
                status,
                message,
                now
        );

        requests.put(id, response);

        log.info(
                "Automation request recorded: id={}, target={}, action={}, status={}",
                id,
                request.target(),
                request.actionType(),
                status
        );

        return response;
    }

    public AutomationResponse handleDecision(
            PolicyDecisionEvent decision) {

        if (decision == null) {
            throw new IllegalArgumentException(
                    "Policy decision is required");
        }

        String actionType = switch (decision.decision()) {
            case SCALE_OUT_REQUESTED -> "SCALE_OUT";
            case SCALE_IN_REQUESTED -> "SCALE_IN";
            case TRAFFIC_STEERING_REQUESTED -> "TRAFFIC_STEERING";
            case NO_ACTION, MANUAL_REVIEW -> null;
        };

        if (actionType == null) {
            log.info(
                    "No automated operation for decision {}: {}",
                    decision.decisionId(),
                    decision.decision()
            );

            return null;
        }

        AutomationRequest request = new AutomationRequest(
                decision.target(),
                actionType,
                "policy-engine-service",
                decision.reason()
        );

        return submit(request);
    }

    public List<AutomationResponse> findAll() {
        return requests.values()
                .stream()
                .sorted((a, b) ->
                        b.createdAt().compareTo(a.createdAt()))
                .toList();
    }

    public AutomationResponse findById(String requestId) {
        return requests.get(requestId);
    }
}
EOF

# ------------------------------------------------------------
# 6. CONSOMMATEUR KAFKA
# ------------------------------------------------------------

cat > "$AUTO/src/main/java/com/clamp/acm/automation/AutomationConsumer.java" <<'EOF'
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
EOF

# ------------------------------------------------------------
# 7. API REST
# ------------------------------------------------------------

cat > "$AUTO/src/main/java/com/clamp/acm/automation/controller/AutomationControllerRest.java" <<'EOF'
package com.clamp.acm.automation.controller;

import com.clamp.acm.automation.model.AutomationRequest;
import com.clamp.acm.automation.model.AutomationResponse;
import com.clamp.acm.automation.service.AutomationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/automation")
public class AutomationControllerRest {

    private final AutomationService automationService;

    public AutomationControllerRest(
            AutomationService automationService) {
        this.automationService = automationService;
    }

    @PostMapping("/requests")
    public ResponseEntity<?> submit(
            @RequestBody AutomationRequest request) {
        try {
            AutomationResponse response =
                    automationService.submit(request);

            return ResponseEntity.accepted().body(response);
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(
                    Map.of("error", ex.getMessage()));
        }
    }

    @GetMapping("/requests")
    public List<AutomationResponse> findAll() {
        return automationService.findAll();
    }

    @GetMapping("/requests/{id}")
    public ResponseEntity<AutomationResponse> findById(
            @PathVariable String id) {

        AutomationResponse response =
                automationService.findById(id);

        if (response == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(response);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleUnexpectedError(
            Exception exception) {

        return ResponseEntity.status(
                        HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of(
                        "error",
                        "Internal server error"));
    }
}
EOF

# ------------------------------------------------------------
# 8. CONFIGURATION SPRING BOOT
# ------------------------------------------------------------

cat > "$AUTO/src/main/resources/application.yml" <<'EOF'
spring:
  application:
    name: automation-controller-service

  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}

    consumer:
      group-id: ${KAFKA_CONSUMER_GROUP:acm-automation-controller}
      auto-offset-reset: earliest
      enable-auto-commit: false
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      properties:
        spring.json.value.default.type: com.clamp.acm.events.PolicyDecisionEvent
        spring.json.trusted.packages: com.clamp.acm.events

server:
  port: ${SERVER_PORT:8083}

acm:
  kafka:
    decisions-topic: ${ACM_DECISIONS_TOPIC:acm.policy-decisions}

  automation:
    execution-enabled: ${ACM_AUTOMATION_EXECUTION_ENABLED:false}

management:
  endpoints:
    web:
      exposure:
        include: health,info

  endpoint:
    health:
      show-details: never
EOF

# ------------------------------------------------------------
# 9. VERIFICATION DES FICHIERS
# ------------------------------------------------------------

for FILE in \
  "$AUTO/pom.xml" \
  "$AUTO/src/main/java/com/clamp/acm/automation/AutomationApplication.java" \
  "$AUTO/src/main/java/com/clamp/acm/automation/AutomationConsumer.java" \
  "$AUTO/src/main/java/com/clamp/acm/automation/service/AutomationService.java" \
  "$AUTO/src/main/java/com/clamp/acm/automation/controller/AutomationControllerRest.java" \
  "$AUTO/src/main/java/com/clamp/acm/automation/model/AutomationRequest.java" \
  "$AUTO/src/main/java/com/clamp/acm/automation/model/AutomationResponse.java" \
  "$AUTO/src/main/resources/application.yml"
do
    if [ ! -s "$FILE" ]; then
        echo "ERREUR : fichier absent ou vide : $FILE"
        exit 1
    fi
done

echo "[4/4] automation-controller-service cree."
echo "Partie 2/4 terminee : les trois microservices sont definis."
echo "Aucune installation, compilation ou execution effectuee."


# ============================================================
# CLAMP-ACM-CI
# PARTIE 3/4 : KAFKA, TOSCA, COMPOSITIONS ET VALIDATION
#
# Sous-partie 1/4 : configuration des topics Kafka
# Sous-partie 2/4 : types de politiques et de noeuds TOSCA
# Sous-partie 3/4 : compositions d'automatisation
# Sous-partie 4/4 : scripts de verification et smoke tests
#
# Ce generateur ne lance aucune installation, compilation,
# connexion Kafka, execution Docker ou application Spring Boot.
# ============================================================

set -eu

ROOT="clamp-acm-ci"

echo "=========================================="
echo "CLAMP ACM CI - Partie 3/4"
echo "Generation Kafka et TOSCA"
echo "=========================================="

if [ ! -f "$ROOT/pom.xml" ]; then
    echo "ERREUR : projet $ROOT introuvable."
    echo "Execute d'abord les scripts des parties precedentes."
    exit 1
fi

mkdir -p \
  "$ROOT/kafka-config" \
  "$ROOT/tosca/policy-types" \
  "$ROOT/tosca/node-types" \
  "$ROOT/tosca/compositions" \
  "$ROOT/scripts" \
  "$ROOT/xtesting/smoke"

# ============================================================
# SOUS-PARTIE 1/4 : CONFIGURATION KAFKA
# ============================================================

echo "[1/4] Generation de la configuration Kafka"

cat > "$ROOT/kafka-config/topics.properties" <<'EOF'
# Configuration declarative des topics Kafka.
# Ces proprietes documentent les parametres souhaites.
# Elles ne creent aucun topic automatiquement.

acm.metrics.partitions=3
acm.metrics.replication-factor=1
acm.metrics.retention-ms=604800000
acm.metrics.cleanup-policy=delete

acm.policy-decisions.partitions=3
acm.policy-decisions.replication-factor=1
acm.policy-decisions.retention-ms=604800000
acm.policy-decisions.cleanup-policy=delete

acm.automation-results.partitions=3
acm.automation-results.replication-factor=1
acm.automation-results.retention-ms=604800000
acm.automation-results.cleanup-policy=delete
EOF

cat > "$ROOT/kafka-config/README.md" <<'EOF'
# Configuration Kafka

## Topics

| Topic | Producteur | Consommateur |
|---|---|---|
| acm.metrics | monitoring-service | policy-engine-service |
| acm.policy-decisions | policy-engine-service | automation-controller-service |
| acm.automation-results | automation-controller-service | observabilite |

## Parametres proposes

- Trois partitions par topic.
- Facteur de replication 1 pour un environnement local.
- Conservation des messages pendant sept jours.
- Nettoyage par suppression des anciens messages.

Le facteur de replication 1 n'est pas recommande pour une
installation de production hautement disponible.

## Securite

En production, configurer TLS, les ACL, l'authentification
et les autorisations de lecture et d'ecriture par service.

Les topics doivent etre crees par un administrateur ou par
un mecanisme de deploiement controle.

Le fichier topics.properties est une documentation declarative ;
il n'est pas directement interprete par Kafka.
EOF

# ============================================================
# SOUS-PARTIE 2/4 : TYPES DE POLITIQUES ET NOEUDS TOSCA
# ============================================================

echo "[2/4] Generation des types TOSCA"

cat > "$ROOT/tosca/policy-types/threshold-policy.yaml" <<'EOF'
# Type de politique de reference pour le projet.
# Adapter la syntaxe et les imports au dialecte TOSCA
# effectivement supporte par la version ONAP/ACM cible.

tosca_definitions_version: tosca_simple_yaml_1_3

metadata:
  template_name: clamp-acm-threshold-policy
  template_version: 1.0.0
  template_author: CLAMP ACM CI

description: >
  Politique de supervision a seuils.
  Le depassement d'un seuil demande une revue explicite ;
  il ne declenche pas directement une action destructive.

policy_types:
  clamp.acm.policies.ThresholdPolicy:
    derived_from: tosca.policies.Root
    description: Evaluation de seuils de metriques.
    properties:
      cpu_threshold_pct:
        type: float
        required: true
        default: 80.0
      latency_threshold_ms:
        type: float
        required: true
        default: 100.0
      require_manual_review:
        type: boolean
        required: true
        default: true
EOF

cat > "$ROOT/tosca/node-types/monitoring-node.yaml" <<'EOF'
tosca_definitions_version: tosca_simple_yaml_1_3

metadata:
  template_name: clamp-acm-monitoring-node
  template_version: 1.0.0
  template_author: CLAMP ACM CI

description: >
  Representation logique du producteur de metriques.
  Ce type descriptif ne configure pas lui-meme une source RAN.

node_types:
  clamp.acm.nodes.Monitoring:
    derived_from: tosca.nodes.Root
    properties:
      service_name:
        type: string
        required: true
        default: monitoring-service
      metrics_topic:
        type: string
        required: true
        default: acm.metrics
      collection_interval_ms:
        type: integer
        required: true
        default: 10000
EOF

cat > "$ROOT/tosca/node-types/policy-engine-node.yaml" <<'EOF'
tosca_definitions_version: tosca_simple_yaml_1_3

metadata:
  template_name: clamp-acm-policy-engine-node
  template_version: 1.0.0
  template_author: CLAMP ACM CI

description: >
  Representation logique du moteur de politiques Kafka Streams.

node_types:
  clamp.acm.nodes.PolicyEngine:
    derived_from: tosca.nodes.Root
    properties:
      service_name:
        type: string
        required: true
        default: policy-engine-service
      input_topic:
        type: string
        required: true
        default: acm.metrics
      output_topic:
        type: string
        required: true
        default: acm.policy-decisions
      application_id:
        type: string
        required: true
        default: acm-policy-engine
EOF

cat > "$ROOT/tosca/node-types/automation-controller-node.yaml" <<'EOF'
tosca_definitions_version: tosca_simple_yaml_1_3

metadata:
  template_name: clamp-acm-automation-controller-node
  template_version: 1.0.0
  template_author: CLAMP ACM CI

description: >
  Representation logique du controleur d'automatisation.
  Toute execution reelle necessite un adaptateur et des controles.

node_types:
  clamp.acm.nodes.AutomationController:
    derived_from: tosca.nodes.Root
    properties:
      service_name:
        type: string
        required: true
        default: automation-controller-service
      input_topic:
        type: string
        required: true
        default: acm.policy-decisions
      execution_enabled:
        type: boolean
        required: true
        default: false
EOF

# ============================================================
# SOUS-PARTIE 3/4 : COMPOSITION D'AUTOMATISATION
# ============================================================

echo "[3/4] Generation de la composition TOSCA"

cat > "$ROOT/tosca/compositions/closed-loop-demo.yaml" <<'EOF'
tosca_definitions_version: tosca_simple_yaml_1_3

metadata:
  template_name: clamp-acm-closed-loop-demo
  template_version: 1.0.0
  template_author: CLAMP ACM CI

description: >
  Composition logique de reference reliant la supervision,
  l'evaluation des politiques et le controleur d'automatisation.
  Cette composition est illustrative et doit etre adaptee
  au modele de composition de la version ONAP/ACM cible.

imports:
  - ../node-types/monitoring-node.yaml
  - ../node-types/policy-engine-node.yaml
  - ../node-types/automation-controller-node.yaml
  - ../policy-types/threshold-policy.yaml

topology_template:
  inputs:
    target_name:
      type: string
      description: Identifiant logique de la cible observee
      default: demo-cell-001

    cpu_threshold_pct:
      type: float
      description: Seuil CPU en pourcentage
      default: 80.0

    latency_threshold_ms:
      type: float
      description: Seuil de latence en millisecondes
      default: 100.0

  node_templates:
    monitoring:
      type: clamp.acm.nodes.Monitoring
      properties:
        service_name: monitoring-service
        metrics_topic: acm.metrics
        collection_interval_ms: 10000

    policy_engine:
      type: clamp.acm.nodes.PolicyEngine
      properties:
        service_name: policy-engine-service
        input_topic: acm.metrics
        output_topic: acm.policy-decisions
        application_id: acm-policy-engine

    automation_controller:
      type: clamp.acm.nodes.AutomationController
      properties:
        service_name: automation-controller-service
        input_topic: acm.policy-decisions
        execution_enabled: false

  policies:
    threshold_policy:
      type: clamp.acm.policies.ThresholdPolicy
      properties:
        cpu_threshold_pct: 80.0
        latency_threshold_ms: 100.0
        require_manual_review: true
EOF

cat > "$ROOT/tosca/README.md" <<'EOF'
# Modeles TOSCA

## Organisation

- policy-types/ : definitions des politiques de reference.
- node-types/ : types logiques des trois services.
- compositions/ : exemple de composition de boucle fermee.

## Limites

Ces fichiers constituent un modele de reference generique
en syntaxe TOSCA Simple YAML 1.3.

Ils ne garantissent pas leur acceptation directe par ONAP CLAMP
ou par le moteur ACM installe.

Selon la version cible, il faudra notamment adapter :

- les imports et les types de politiques ;
- les types de noeuds supportes ;
- la structure des compositions ACM ;
- les definitions de participants et de control loops ;
- les proprietes et les contraintes du modele cible.

La composition ne deploie aucun service et ne declenche aucune
action sur une infrastructure reelle.
EOF

# ============================================================
# SOUS-PARTIE 4/4 : VALIDATION STATIQUE ET SMOKE TESTS
# ============================================================

echo "[4/4] Generation des scripts de verification"

cat > "$ROOT/scripts/validate-generated-files.sh" <<'EOF'
#!/bin/sh

set -eu

ROOT="${1:-clamp-acm-ci}"

echo "=========================================="
echo "CLAMP ACM CI - Validation statique"
echo "=========================================="

FILES="
pom.xml
shared-events/pom.xml
monitoring-service/pom.xml
policy-engine-service/pom.xml
automation-controller-service/pom.xml
kafka-config/topics.properties
kafka-config/README.md
tosca/policy-types/threshold-policy.yaml
tosca/node-types/monitoring-node.yaml
tosca/node-types/policy-engine-node.yaml
tosca/node-types/automation-controller-node.yaml
tosca/compositions/closed-loop-demo.yaml
tosca/README.md
"

for RELATIVE_FILE in $FILES; do
    FILE="$ROOT/$RELATIVE_FILE"

    if [ -s "$FILE" ]; then
        echo "OK : $RELATIVE_FILE"
    else
        echo "ERREUR : fichier absent ou vide : $RELATIVE_FILE"
        exit 1
    fi
done

echo ""
echo "Validation statique terminee."
echo "Aucune compilation ou connexion a un service effectuee."
EOF

cat > "$ROOT/xtesting/smoke/README.md" <<'EOF'
# Tests de fumee

Les tests de fumee servent a verifier les points d'entree
HTTP et la disponibilite des services une fois ceux-ci deployes.

Prerequis pour les tests HTTP :
- services demarres ;
- ports accessibles ;
- dependances et configuration correctement installees.

Les controles HTTP ne remplacent ni les tests unitaires,
ni les tests d'integration Kafka, ni la validation ONAP ACM.
EOF

cat > "$ROOT/xtesting/smoke/smoke-test.sh" <<'EOF'
#!/bin/sh

set -eu

BASE_URL="${AUTOMATION_URL:-http://localhost:8083}"
HEALTH_URL="${HEALTH_URL:-http://localhost:8083/actuator/health}"

echo "CLAMP ACM CI - Smoke test HTTP"
echo "URL de sante : $HEALTH_URL"

if ! command -v curl >/dev/null 2>&1; then
    echo "ERREUR : curl doit etre disponible pour lancer ce test."
    exit 1
fi

echo ""
echo "Verification de l'endpoint de sante"

HTTP_CODE=$(
    curl --silent --show-error \
         --output /dev/null \
         --write-out '%{http_code}' \
         "$HEALTH_URL"
) || {
    echo "ERREUR : endpoint de sante inaccessible."
    exit 1
}

if [ "$HTTP_CODE" != "200" ]; then
    echo "ERREUR : statut HTTP inattendu : $HTTP_CODE"
    exit 1
fi

echo "OK : endpoint de sante HTTP 200"

echo ""
echo "Verification de l'API de consultation"

HTTP_CODE=$(
    curl --silent --show-error \
         --output /dev/null \
         --write-out '%{http_code}' \
         "$BASE_URL/api/automation/requests"
) || {
    echo "ERREUR : API d'automatisation inaccessible."
    exit 1
}

if [ "$HTTP_CODE" != "200" ]; then
    echo "ERREUR : statut HTTP inattendu : $HTTP_CODE"
    exit 1
fi

echo "OK : API de consultation HTTP 200"
echo "Smoke tests termines."
EOF

# ============================================================
# CONTROLE DES FICHIERS GENERES
# ============================================================

for FILE in \
  "$ROOT/kafka-config/topics.properties" \
  "$ROOT/kafka-config/README.md" \
  "$ROOT/tosca/policy-types/threshold-policy.yaml" \
  "$ROOT/tosca/node-types/monitoring-node.yaml" \
  "$ROOT/tosca/node-types/policy-engine-node.yaml" \
  "$ROOT/tosca/node-types/automation-controller-node.yaml" \
  "$ROOT/tosca/compositions/closed-loop-demo.yaml" \
  "$ROOT/tosca/README.md" \
  "$ROOT/scripts/validate-generated-files.sh" \
  "$ROOT/xtesting/smoke/README.md" \
  "$ROOT/xtesting/smoke/smoke-test.sh"
do
    if [ ! -s "$FILE" ]; then
        echo "ERREUR : fichier absent ou vide : $FILE"
        exit 1
    fi

    echo "OK : $FILE"
done

echo ""
echo "=========================================="
echo "Partie 3/4 terminee."
echo "Kafka : configuration declarative generee."
echo "TOSCA : types et composition generes."
echo "Tests : scripts generes, non executes."
echo "Aucune dependance installee."
echo "Aucun service demarre."
echo "=========================================="

