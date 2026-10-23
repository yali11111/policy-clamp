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
