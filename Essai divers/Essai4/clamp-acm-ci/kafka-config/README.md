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
