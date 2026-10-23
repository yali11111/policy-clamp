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
