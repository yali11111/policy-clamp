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
