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
