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
