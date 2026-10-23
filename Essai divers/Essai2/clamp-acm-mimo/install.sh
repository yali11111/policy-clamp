#!/bin/bash

set -e

PROJECT="clamp-acm-mimo"

echo "=========================================="
echo "Création du projet $PROJECT"
echo "=========================================="

############################
# Création des dossiers
############################

mkdir -p $PROJECT/clamp/tosca/types
mkdir -p $PROJECT/clamp/policies
mkdir -p $PROJECT/clamp/scripts

mkdir -p $PROJECT/analytics/beam-optimizer
mkdir -p $PROJECT/analytics/ml

mkdir -p $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator
mkdir -p $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator/kafka
mkdir -p $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator/clients
mkdir -p $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator/util

mkdir -p $PROJECT/clamping-runtime/src/main/java/org/onap/policy/clamp/acm/runtime/participants
mkdir -p $PROJECT/clamping-runtime/src/main/java/org/onap/policy/clamp/acm/runtime/instantiation
mkdir -p $PROJECT/clamping-runtime/src/main/java/org/onap/policy/clamp/acm/runtime/supervision
mkdir -p $PROJECT/clamping-runtime/src/main/java/org/onap/policy/clamp/acm/runtime/state

mkdir -p $PROJECT/dcae/kpi-simulator
mkdir -p $PROJECT/dcae/ves-config

mkdir -p $PROJECT/ran-control/ric-xapp
mkdir -p $PROJECT/ran-control/a1-policy
mkdir -p $PROJECT/ran-control/vendor-adapter

mkdir -p $PROJECT/kafka/schemas

mkdir -p $PROJECT/k8s/helm/hybrid-pipeline/templates
mkdir -p $PROJECT/k8s/raw

mkdir -p $PROJECT/observability/prometheus

mkdir -p $PROJECT/grafana/dashboards

mkdir -p $PROJECT/logs

mkdir -p $PROJECT/tools

mkdir -p $PROJECT/model-layer/tosca-models

echo "Arborescence créée."

############################################
# automation-composition.yaml
############################################

cat > $PROJECT/clamp/tosca/automation-composition.yaml <<'EOF'
tosca_definitions_version: tosca_simple_yaml_1_3

description: Massive MIMO Beam Optimization

topology_template:

  node_templates:

    monitoring:
      type: org.onap.acm.Monitoring

    policy:
      type: org.onap.acm.PolicyEngine

    automation:
      type: org.onap.acm.AutomationController
EOF

############################################
# beam-optimization-ac.yaml
############################################

cat > $PROJECT/clamp/tosca/beam-optimization-ac.yaml <<'EOF'
topology_template:

  node_templates:

    beamOptimizer:

      type: org.onap.acm.BeamOptimization

      properties:

        model: beam-ai-v2

        objective: maximize-throughput

        confidenceThreshold: 0.95
EOF

############################################
# parameters.yaml
############################################

cat > $PROJECT/clamp/tosca/parameters.yaml <<'EOF'
parameters:

  throughputThreshold:

    type: integer

    default: 500

  sinrThreshold:

    type: integer

    default: 20

  maxPrb:

    type: integer

    default: 80
EOF

############################################
# onap-acm-types.yaml
############################################

cat > $PROJECT/clamp/tosca/types/onap-acm-types.yaml <<'EOF'
node_types:

  org.onap.acm.Monitoring:

    derived_from: tosca.nodes.Root

    properties:

      topic:
        type: string

      interval:
        type: integer
EOF

############################################
# trigger-policy.json
############################################

cat > $PROJECT/clamp/policies/trigger-policy.json <<'EOF'
{
  "policyId": "beam-trigger-policy",
  "name": "Beam Trigger Policy",
  "event": "METRIC_UPDATE",
  "conditions": {
    "throughput": {
      "operator": "<",
      "value": 500
    },
    "sinr": {
      "operator": "<",
      "value": 20
    }
  }
}
EOF

############################################
# guard-policy.json
############################################

cat > $PROJECT/clamp/policies/guard-policy.json <<'EOF'
{
  "policyId": "beam-guard-policy",
  "maxInstances": 5,
  "maxCpu": 85,
  "minConfidence": 0.90
}
EOF

############################################
# action-policy.json
############################################

cat > $PROJECT/clamp/policies/action-policy.json <<'EOF'
{
  "policyId": "beam-action-policy",
  "action": "OPTIMIZE_BEAM",
  "target": "RIC",
  "parameters": {
    "beamId": 12,
    "power": 18
  }
}
EOF

############################################
# create-composition.sh
############################################

cat > $PROJECT/clamp/scripts/create-composition.sh <<'EOF'
#!/bin/bash

curl -X POST \
http://localhost:30258/onap/clamp/acm/v2/compositions \
-H "Content-Type: application/json" \
-d @../tosca/automation-composition.yaml
EOF

############################################
# prime-composition.sh
############################################

cat > $PROJECT/clamp/scripts/prime-composition.sh <<'EOF'
#!/bin/bash

curl -X POST \
http://localhost:30258/onap/clamp/acm/v2/compositions/{id}/prime
EOF

############################################
# deploy-composition.sh
############################################

cat > $PROJECT/clamp/scripts/deploy-composition.sh <<'EOF'
#!/bin/bash

curl -X POST \
http://localhost:30258/onap/clamp/acm/v2/instances
EOF

chmod +x $PROJECT/clamp/scripts/*.sh

echo
echo "Partie 1 terminée avec succès."

############################################
# ANALYTICS / BEAM OPTIMIZER
############################################

echo "Création Beam Optimizer..."

mkdir -p $PROJECT/analytics/beam-optimizer

############################################
# app.py
############################################

cat > $PROJECT/analytics/beam-optimizer/app.py <<'EOF'
from fastapi import FastAPI
from inference import predict

app = FastAPI()

@app.post("/predict")
def prediction(data: dict):
    return predict(data)
EOF

############################################
# inference.py
############################################

cat > $PROJECT/analytics/beam-optimizer/inference.py <<'EOF'
import joblib

model = joblib.load("model.pkl")

def predict(data):

    features = [[
        data["throughput"],
        data["sinr"],
        data["prb"]
    ]]

    prediction = model.predict(features)

    return {
        "beam": int(prediction[0])
    }
EOF

############################################
# train.py
############################################

cat > $PROJECT/analytics/beam-optimizer/train.py <<'EOF'
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
import joblib

dataset = pd.read_csv("dataset.csv")

X = dataset[
    ["throughput", "sinr", "prb"]
]

y = dataset["beam"]

model = RandomForestClassifier()

model.fit(X, y)

joblib.dump(model, "model.pkl")

print("Model saved.")
EOF

############################################
# requirements.txt
############################################

cat > $PROJECT/analytics/beam-optimizer/requirements.txt <<'EOF'
fastapi
uvicorn
numpy
pandas
scikit-learn
joblib
EOF

############################################
# Dockerfile
############################################

cat > $PROJECT/analytics/beam-optimizer/Dockerfile <<'EOF'
FROM python:3.11

WORKDIR /app

COPY . .

RUN pip install -r requirements.txt

CMD [
 "uvicorn",
 "app:app",
 "--host",
 "0.0.0.0",
 "--port",
 "8000"
]
EOF

############################################
# dataset.csv (exemple)
############################################

cat > $PROJECT/analytics/beam-optimizer/dataset.csv <<'EOF'
throughput,sinr,prb,beam
500,22,65,12
480,18,82,8
550,25,60,14
600,28,55,15
430,15,90,5
520,23,70,13
580,27,58,16
460,17,88,7
EOF

############################################
# model.pkl (placeholder)
############################################

touch $PROJECT/analytics/beam-optimizer/model.pkl

echo "Beam Optimizer créé."

echo
echo "Installation Python :"
echo "cd $PROJECT/analytics/beam-optimizer"
echo "pip install -r requirements.txt"

echo
echo "Construction Docker :"
echo "docker build -t beam-optimizer $PROJECT/analytics/beam-optimizer"


############################################
# ANALYTICS / ML
############################################

echo
echo "========================================"
echo "Création Analytics ML..."
echo "========================================"

mkdir -p $PROJECT/analytics/ml

############################################
# train1.py
############################################

cat > $PROJECT/analytics/ml/train1.py <<'EOF'
import pandas as pd
import joblib

from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

# Exemple de données
data = {
    "throughput": [500, 480, 550, 600, 430, 520, 580, 460],
    "sinr":       [22, 18, 25, 28, 15, 23, 27, 17],
    "prb":        [65, 82, 60, 55, 90, 70, 58, 88],
    "beam":       [12, 8, 14, 15, 5, 13, 16, 7]
}

df = pd.DataFrame(data)

X = df[["throughput", "sinr", "prb"]]
y = df["beam"]

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.2,
    random_state=42
)

model = RandomForestClassifier(
    n_estimators=100,
    random_state=42
)

model.fit(X_train, y_train)

prediction = model.predict(X_test)

print("Accuracy :", accuracy_score(y_test, prediction))

joblib.dump(model, "model1.pkl")

print("Model saved as model1.pkl")
EOF

############################################
# requirements.txt
############################################

cat > $PROJECT/analytics/ml/requirements.txt <<'EOF'
pandas
numpy
scikit-learn
joblib
EOF

############################################
# model1.pkl (placeholder)
############################################

touch $PROJECT/analytics/ml/model1.pkl

############################################
# README
############################################

cat > $PROJECT/analytics/ml/README.md <<'EOF'
Analytics ML Module

Installation :

pip install -r requirements.txt

Entraînement :

python3 train1.py

Le fichier model1.pkl sera généré automatiquement.
EOF

############################################
# Génération automatique du modèle
############################################

if command -v python3 >/dev/null 2>&1; then
    echo
    echo "Python détecté."

    if python3 -c "import sklearn,pandas,joblib" >/dev/null 2>&1; then
        echo "Création automatique de model1.pkl..."

        (
            cd $PROJECT/analytics/ml
            python3 train1.py || true
        )
    else
        echo "Les bibliothèques Python ne sont pas installées."
        echo "Exécutez :"
        echo "cd $PROJECT/analytics/ml"
        echo "pip install -r requirements.txt"
        echo "python3 train1.py"
    fi
fi

echo
echo "Analytics ML installé."
echo

############################################
# ORCHESTRATION JAVA - PARTIE 3A
############################################

echo
echo "========================================"
echo "Création Java Orchestrator..."
echo "========================================"

mkdir -p $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator
mkdir -p $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator/kafka
mkdir -p $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator/clients
mkdir -p $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator/util
mkdir -p $PROJECT/orchestration/java-orchestrator/src/main/resources

############################################
# Application.java
############################################

cat > $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator/Application.java <<'EOF'
package com.example.orchestrator;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
EOF

############################################
# KpiController.java
############################################

cat > $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator/KpiController.java <<'EOF'
package com.example.orchestrator;

import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/kpi")
public class KpiController {

    @PostMapping
    public void publish(@RequestBody Object metric) {

        System.out.println("Received KPI : " + metric);

    }

    @GetMapping
    public List<Object> list() {

        return List.of();

    }
}
EOF

############################################
# pom.xml
############################################

cat > $PROJECT/orchestration/java-orchestrator/pom.xml <<'EOF'
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>java-orchestrator</artifactId>
    <version>1.0.0</version>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.0</version>
    </parent>

    <properties>
        <java.version>21</java.version>
    </properties>

    <dependencies>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.kafka</groupId>
            <artifactId>spring-kafka</artifactId>
        </dependency>

    </dependencies>

    <build>

        <plugins>

            <plugin>

                <groupId>org.springframework.boot</groupId>

                <artifactId>spring-boot-maven-plugin</artifactId>

            </plugin>

        </plugins>

    </build>

</project>
EOF

############################################
# Vérification Maven
############################################

if command -v mvn >/dev/null 2>&1; then
    echo
    echo "Maven détecté."
    echo "Compilation possible avec :"
    echo "cd $PROJECT/orchestration/java-orchestrator"
    echo "mvn clean package"
else
    echo
    echo "Maven n'est pas installé."
fi

echo
echo "Partie 3A terminée."

############################################
# ORCHESTRATION JAVA - PARTIE 3B
# Kafka Consumers & Publisher
############################################

echo
echo "========================================"
echo "Création des composants Kafka..."
echo "========================================"

############################################
# KpiConsumer.java
############################################

cat > $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator/kafka/KpiConsumer.java <<'EOF'
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
EOF

############################################
# ResultConsumer.java
############################################

cat > $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator/kafka/ResultConsumer.java <<'EOF'
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
EOF

############################################
# EventPublisher.java
############################################

cat > $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator/kafka/EventPublisher.java <<'EOF'
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
EOF

############################################
# README Kafka
############################################

cat > $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator/kafka/README.md <<'EOF'
Kafka Components

Topics utilisés :

- kpi-topic
- prediction-topic
- automation-topic

Classes :

- KpiConsumer
- ResultConsumer
- EventPublisher

Ces composants assurent la communication entre
le simulateur KPI, le moteur ML et CLAMP.
EOF

echo
echo "Composants Kafka créés."
echo "Partie 3B terminée."

############################################
# ORCHESTRATION JAVA - PARTIE 3C
# Clients, Utils, Docker & Config
############################################

echo
echo "========================================"
echo "Finalisation Java Orchestrator..."
echo "========================================"

############################################
# PythonMlClient.java
############################################

cat > $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator/clients/PythonMlClient.java <<'EOF'
package com.example.orchestrator.clients;

import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class PythonMlClient {

    private final RestTemplate restTemplate = new RestTemplate();

    public String predict(Object metric) {

        String url = "http://beam-optimizer:8000/predict";

        return restTemplate.postForObject(
                url,
                metric,
                String.class
        );
    }
}
EOF

############################################
# AcmThreadFactory.java
############################################

cat > $PROJECT/orchestration/java-orchestrator/src/main/java/com/example/orchestrator/util/AcmThreadFactory.java <<'EOF'
package com.example.orchestrator.util;

import java.util.concurrent.ThreadFactory;

public class AcmThreadFactory implements ThreadFactory {

    @Override
    public Thread newThread(Runnable r) {

        Thread thread = new Thread(r);
        thread.setName("acm-worker-thread");

        return thread;
    }
}
EOF

############################################
# application.yml
############################################

cat > $PROJECT/orchestration/java-orchestrator/src/main/resources/application.yml <<'EOF'
server:
  port: 8085

spring:
  kafka:
    bootstrap-servers: kafka:9092

ml:
  url: http://beam-optimizer:8000
EOF

############################################
# Dockerfile
############################################

cat > $PROJECT/orchestration/java-orchestrator/Dockerfile <<'EOF'
FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY target/java-orchestrator-1.0.0.jar app.jar

EXPOSE 8085

ENTRYPOINT ["java","-jar","app.jar"]
EOF

############################################
# Build helper script
############################################

cat > $PROJECT/orchestration/java-orchestrator/build.sh <<'EOF'
#!/bin/bash

echo "Compilation du projet Java..."

mvn clean package -DskipTests

echo "Build terminé."
echo "Image Docker :"

echo "docker build -t java-orchestrator ."
EOF

chmod +x $PROJECT/orchestration/java-orchestrator/build.sh

############################################
# Résumé module
############################################

cat > $PROJECT/orchestration/java-orchestrator/README.md <<'EOF'
Java Orchestrator - CLAMP ACM MIMO

Composants :

- REST API KPI Controller
- Kafka Consumers (KPI, Prediction)
- Event Publisher
- Client ML Python (FastAPI)
- Thread Factory

Ports :
- 8085 (API)

Dépendances :
- Spring Boot Web
- Spring Kafka

ML Service :
- http://beam-optimizer:8000
EOF

echo
echo "========================================"
echo "Java Orchestrator terminé ✔"
echo "========================================"


############################################
# CLAMP RUNTIME ONAP ACM - PARTIE 4
############################################

echo
echo "========================================"
echo "Création CLAMP Runtime (ONAP ACM)..."
echo "========================================"

BASE=$PROJECT/clamping-runtime/src/main/java/org/onap/policy/clamp/acm/runtime

mkdir -p $BASE/participants
mkdir -p $BASE/instantiation
mkdir -p $BASE/supervision
mkdir -p $BASE/state

############################################
# AcmParticipantProvider.java
############################################

cat > $BASE/participants/AcmParticipantProvider.java <<'EOF'
package org.onap.policy.clamp.acm.runtime.participants;

import java.util.List;

public class AcmParticipantProvider {

    public List<String> getParticipants() {

        return List.of(
                "monitoring-participant",
                "policy-participant",
                "automation-participant"
        );
    }
}
EOF

############################################
# AutomationCompositionInstantiationProvider.java
############################################

cat > $BASE/instantiation/AutomationCompositionInstantiationProvider.java <<'EOF'
package org.onap.policy.clamp.acm.runtime.instantiation;

public class AutomationCompositionInstantiationProvider {

    public void instantiate(String compositionId) {

        System.out.println("================================");
        System.out.println("Instantiation AC : " + compositionId);
        System.out.println("================================");
    }
}
EOF

############################################
# SupervisionAcHandler.java
############################################

cat > $BASE/supervision/SupervisionAcHandler.java <<'EOF'
package org.onap.policy.clamp.acm.runtime.supervision;

public class SupervisionAcHandler {

    public void supervise(String acId) {

        System.out.println("================================");
        System.out.println("Supervision AC : " + acId);
        System.out.println("================================");
    }
}
EOF

############################################
# SupervisionParticipantHandler.java
############################################

cat > $BASE/supervision/SupervisionParticipantHandler.java <<'EOF'
package org.onap.policy.clamp.acm.runtime.supervision;

public class SupervisionParticipantHandler {

    public void checkParticipant(String participant) {

        System.out.println("Participant alive : " + participant);
    }
}
EOF

############################################
# AcInstanceStateResolver.java
############################################

cat > $BASE/state/AcInstanceStateResolver.java <<'EOF'
package org.onap.policy.clamp.acm.runtime.state;

public class AcInstanceStateResolver {

    public String resolve(boolean deployed, boolean running) {

        if (!deployed) {
            return "NOT_DEPLOYED";
        }

        if (running) {
            return "RUNNING";
        }

        return "STOPPED";
    }
}
EOF

############################################
# AcmStageUtils.java
############################################

cat > $BASE/state/AcmStageUtils.java <<'EOF'
package org.onap.policy.clamp.acm.runtime.state;

public class AcmStageUtils {

    public static final String CREATED = "CREATED";
    public static final String PRIMED = "PRIMED";
    public static final String DEPLOYED = "DEPLOYED";
    public static final String RUNNING = "RUNNING";
}
EOF

############################################
# README CLAMP Runtime
############################################

cat > $PROJECT/clamping-runtime/README.md <<'EOF'
CLAMP ACM Runtime (ONAP)

Modules :

- Participants Provider
- Automation Composition Instantiation
- Supervision Handler
- State Resolver
- Stage Utilities

Rôle :
Ce module orchestre le cycle de vie des Automation Compositions :
CREATE → PRIME → DEPLOY → RUN
EOF

echo
echo "CLAMP Runtime terminé ✔"
echo

############################################
# PARTIE 5 - DCAE + RIC + KAFKA + VES + KPI
############################################

echo
echo "========================================"
echo "Création DCAE / RIC / Kafka / VES..."
echo "========================================"

############################################
# DCAE KPI Simulator
############################################

mkdir -p $PROJECT/dcae/kpi-simulator
mkdir -p $PROJECT/dcae/ves-config

cat > $PROJECT/dcae/kpi-simulator/producer.py <<'EOF'
import json
from kafka import KafkaProducer

producer = KafkaProducer(
    bootstrap_servers="localhost:9092"
)

with open("sample-events.json") as f:
    events = json.load(f)

for event in events:
    producer.send(
        "kpi-topic",
        json.dumps(event).encode("utf-8")
    )

print("KPI events sent.")
EOF

cat > $PROJECT/dcae/kpi-simulator/sample-events.json <<'EOF'
[
  {
    "cellId": "Cell-01",
    "throughput": 520,
    "sinr": 23,
    "prb": 65
  },
  {
    "cellId": "Cell-02",
    "throughput": 480,
    "sinr": 18,
    "prb": 82
  }
]
EOF

############################################
# VES Collector config
############################################

cat > $PROJECT/dcae/ves-config/ves-collector.yaml <<'EOF'
collector:
  host: localhost
  port: 8443

topics:
  metrics: kpi-topic
EOF

############################################
# RIC xApp
############################################

mkdir -p $PROJECT/ran-control/ric-xapp
mkdir -p $PROJECT/ran-control/a1-policy
mkdir -p $PROJECT/ran-control/vendor-adapter

cat > $PROJECT/ran-control/ric-xapp/xapp.py <<'EOF'
def update_beam(beam):
    print("Applying beam:", beam)
EOF

cat > $PROJECT/ran-control/ric-xapp/config.yaml <<'EOF'
ric:
  host: ric.local
  port: 36421

beam:
  default: 12
EOF

############################################
# A1 Policy
############################################

cat > $PROJECT/ran-control/a1-policy/beam-update-policy.json <<'EOF'
{
  "policyId": "beam-policy",
  "beam": 12,
  "minConfidence": 0.95,
  "maxPower": 18
}
EOF

############################################
# Vendor Adapter
############################################

cat > $PROJECT/ran-control/vendor-adapter/ran-api-mapping.yaml <<'EOF'
beamUpdate:
  vendor: Nokia
  endpoint: /api/v1/beam
  method: POST
EOF

############################################
# Kafka schemas
############################################

mkdir -p $PROJECT/kafka/schemas

cat > $PROJECT/kafka/schemas/kpi-event.json <<'EOF'
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "cellId": { "type": "string" },
    "throughput": { "type": "number" },
    "sinr": { "type": "number" },
    "prb": { "type": "number" },
    "timestamp": { "type": "string" }
  },
  "required": ["cellId", "throughput", "sinr", "prb"]
}
EOF

cat > $PROJECT/kafka/schemas/ml-result.json <<'EOF'
{
  "type": "object",
  "properties": {
    "beam": { "type": "integer" },
    "confidence": { "type": "number" },
    "gain": { "type": "number" }
  },
  "required": ["beam", "confidence"]
}
EOF

cat > $PROJECT/kafka/schemas/a1-command.json <<'EOF'
{
  "type": "object",
  "properties": {
    "command": { "type": "string" },
    "beam": { "type": "integer" },
    "power": { "type": "number" }
  },
  "required": ["command", "beam"]
}
EOF

############################################
# Kafka docker-compose
############################################

cat > $PROJECT/kafka/docker-compose-kafka.yaml <<'EOF'
version: "3.8"

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.4
    ports:
      - "2181:2181"

  kafka:
    image: confluentinc/cp-kafka:7.4
    ports:
      - "9092:9092"
    environment:
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
EOF

############################################
# Run helper
############################################

cat > $PROJECT/dcae/kpi-simulator/run.sh <<'EOF'
#!/bin/bash

pip install kafka-python

python3 producer.py
EOF

chmod +x $PROJECT/dcae/kpi-simulator/run.sh

echo
echo "========================================"
echo "DCAE + RIC + Kafka + VES terminé ✔"
echo "========================================"



############################################
# PARTIE 6 - K8S + HELM + OBSERVABILITY
############################################

echo
echo "========================================"
echo "Création Kubernetes + Helm + Observabilité"
echo "========================================"

############################################
# Namespace + Config + Ingress
############################################

mkdir -p $PROJECT/k8s/raw

cat > $PROJECT/k8s/raw/namespace.yaml <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: clamp-system
EOF

cat > $PROJECT/k8s/raw/configmaps.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: clamp-config
  namespace: clamp-system
data:
  KAFKA_BROKER: kafka:9092
  ML_URL: http://beam-optimizer:8000
  CLAMP_URL: http://clamp-runtime:8080
EOF

cat > $PROJECT/k8s/raw/ingress.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: clamp-ingress
  namespace: clamp-system
spec:
  rules:
    - host: clamp.local
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port:
                  number: 8080
EOF

############################################
# Helm Chart base
############################################

mkdir -p $PROJECT/k8s/helm/hybrid-pipeline/templates

cat > $PROJECT/k8s/helm/hybrid-pipeline/Chart.yaml <<'EOF'
apiVersion: v2
name: hybrid-pipeline
version: 1.0.0
description: CLAMP + ML + RIC Hybrid System
EOF

cat > $PROJECT/k8s/helm/hybrid-pipeline/values.yaml <<'EOF'
kafka:
  replicas: 1

ml:
  image: beam-optimizer:latest

java:
  image: java-orchestrator:latest

ric:
  enabled: true
EOF

############################################
# Java deployment
############################################

cat > $PROJECT/k8s/helm/hybrid-pipeline/templates/java.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: java-orchestrator
  namespace: clamp-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app: java-orchestrator
  template:
    metadata:
      labels:
        app: java-orchestrator
    spec:
      containers:
        - name: java
          image: java-orchestrator:latest
          ports:
            - containerPort: 8085
EOF

############################################
# Python ML deployment
############################################

cat > $PROJECT/k8s/helm/hybrid-pipeline/templates/python.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: beam-optimizer
  namespace: clamp-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: beam-optimizer
  template:
    metadata:
      labels:
        app: beam-optimizer
    spec:
      containers:
        - name: ml
          image: beam-optimizer:latest
          ports:
            - containerPort: 8000
EOF

############################################
# Kafka deployment
############################################

cat > $PROJECT/k8s/helm/hybrid-pipeline/templates/kafka.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafka
  namespace: clamp-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
        - name: kafka
          image: apache/kafka:latest
          ports:
            - containerPort: 9092
EOF

############################################
# RIC deployment
############################################

cat > $PROJECT/k8s/helm/hybrid-pipeline/templates/ric.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ric-xapp
  namespace: clamp-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ric-xapp
  template:
    metadata:
      labels:
        app: ric-xapp
    spec:
      containers:
        - name: ric
          image: ric-xapp:latest
          ports:
            - containerPort: 8085
EOF

############################################
# Prometheus
############################################

mkdir -p $PROJECT/observability/prometheus

cat > $PROJECT/observability/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: "java-orchestrator"
    static_configs:
      - targets: ["java-orchestrator:8085"]

  - job_name: "ml-service"
    static_configs:
      - targets: ["beam-optimizer:8000"]
EOF

cat > $PROJECT/observability/prometheus/rules.yaml <<'EOF'
groups:
  - name: control-loop
    rules:
      - alert: HighCPUUsage
        expr: cpu_usage > 80
        for: 1m
EOF

############################################
# Grafana dashboards
############################################

mkdir -p $PROJECT/grafana/dashboards

cat > $PROJECT/grafana/dashboards/control-loop.json <<'EOF'
{
  "title": "CLAMP Control Loop",
  "panels": [
    { "title": "Throughput", "type": "timeseries" },
    { "title": "SINR", "type": "timeseries" },
    { "title": "PRB Usage", "type": "gauge" },
    { "title": "Kafka Messages", "type": "stat" }
  ]
}
EOF

cat > $PROJECT/grafana/dashboards/ml-performance.json <<'EOF'
{
  "title": "ML Performance",
  "panels": [
    { "title": "Prediction Confidence", "type": "gauge" },
    { "title": "Inference Time", "type": "timeseries" },
    { "title": "Beam Distribution", "type": "barchart" }
  ]
}
EOF

cat > $PROJECT/grafana/datasource.yaml <<'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
EOF

############################################
# Logs config
############################################

mkdir -p $PROJECT/logs

cat > $PROJECT/logs/logback.xml <<'EOF'
<configuration>

  <appender name="STDOUT"
            class="ch.qos.logback.core.ConsoleAppender"/>

  <root level="INFO">
    <appender-ref ref="STDOUT"/>
  </root>

</configuration>
EOF

echo
echo "========================================"
echo "Kubernetes + Observabilité terminé ✔"
echo "========================================"


echo "=== PARTIE 7 : Observabilité + Tools + Model Layer ==="

# =========================
# OBSERVABILITÉ
# =========================
mkdir -p $PROJECT/observability/prometheus
mkdir -p $PROJECT/grafana/dashboards
mkdir -p $PROJECT/grafana

cat > $PROJECT/observability/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: "spring-boot"
    static_configs:
      - targets: ["backend:8080"]

  - job_name: "ml-service"
    static_configs:
      - targets: ["beam-optimizer:8000"]
EOF

cat > $PROJECT/observability/prometheus/rules.yaml <<EOF
groups:
  - name: control-loop-alerts
    rules:
      - alert: HighCPUUsage
        expr: cpu_usage > 80
        for: 1m
EOF

# =========================
# GRAFANA
# =========================
cat > $PROJECT/grafana/dashboards/control-loop.json <<EOF
{
  "title": "CLAMP Control Loop",
  "panels": [
    { "title": "Throughput", "type": "timeseries" },
    { "title": "SINR", "type": "timeseries" },
    { "title": "PRB Usage", "type": "gauge" },
    { "title": "Kafka Messages", "type": "stat" }
  ]
}
EOF

cat > $PROJECT/grafana/dashboards/ml-performance.json <<EOF
{
  "title": "ML Performance",
  "panels": [
    { "title": "Prediction Confidence", "type": "gauge" },
    { "title": "Inference Time", "type": "timeseries" },
    { "title": "Beam Distribution", "type": "barchart" }
  ]
}
EOF

cat > $PROJECT/grafana/datasource.yaml <<EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
EOF

# =========================
# LOGS
# =========================
mkdir -p $PROJECT/logs

cat > $PROJECT/logs/logback.xml <<EOF
<configuration>
  <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender"/>
  <root level="INFO">
    <appender-ref ref="STDOUT"/>
  </root>
</configuration>
EOF

# =========================
# TOOLS
# =========================
mkdir -p $PROJECT/tools

cat > $PROJECT/tools/send-kpi.sh <<EOF
#!/bin/bash
echo "Sending KPI events..."
curl -X POST http://localhost:8085/api/kpi \\
  -H "Content-Type: application/json" \\
  -d @kpi.json
EOF

cat > $PROJECT/tools/check-loop-status.sh <<EOF
#!/bin/bash
curl http://localhost:8080/api/loop/status
EOF

cat > $PROJECT/tools/logs.sh <<EOF
#!/bin/bash
kubectl logs -f deployment/java-orchestrator
EOF

cat > $PROJECT/tools/deploy-all.sh <<EOF
#!/bin/bash

echo "Deploy Kafka..."
docker compose -f kafka/docker-compose-kafka.yaml up -d

echo "Deploy ML..."
kubectl apply -f k8s/helm/python.yaml

echo "Deploy Java..."
kubectl apply -f k8s/helm/java.yaml

echo "Deploy RIC..."
kubectl apply -f k8s/helm/ric.yaml
EOF

cat > $PROJECT/tools/restart-loop.sh <<EOF
#!/bin/bash
kubectl rollout restart deployment/java-orchestrator
kubectl rollout restart deployment/beam-optimizer
kubectl rollout restart deployment/policy-engine
EOF

chmod +x $PROJECT/tools/*.sh

# =========================
# MODEL LAYER
# =========================
mkdir -p $PROJECT/model-layer/tosca-models

cat > $PROJECT/model-layer/tosca-models/ToscaCapabilityAssignment.java <<EOF
package org.onap.policy.models.tosca;

import java.util.Map;

public class ToscaCapabilityAssignment {
    private String capabilityName;
    private Map<String, Object> properties;
}
EOF

cat > $PROJECT/model-layer/tosca-models/AutomationComposition.java <<EOF
package org.onap.policy.models.tosca;

import java.util.List;
import java.util.UUID;

public class AutomationComposition {
    private UUID instanceId;
    private String state;
    private List<Object> elements;
}
EOF

cat > $PROJECT/model-layer/tosca-models/AutomationCompositionElement.java <<EOF
package org.onap.policy.models.tosca;

import java.util.List;
import java.util.UUID;

public class AutomationCompositionElement {
    private UUID id;
    private String participant;
    private String state;
    private List<Object> capabilities;
}
EOF

cat > $PROJECT/model-layer/tosca-models/ToscaConceptIdentifier.java <<EOF
package org.onap.policy.models.tosca.concepts;

import java.io.Serializable;

public class ToscaConceptIdentifier implements Serializable {
    private String name;
    private String version;
}
EOF

echo "=== PARTIE 7 TERMINÉE ==="









