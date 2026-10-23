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
