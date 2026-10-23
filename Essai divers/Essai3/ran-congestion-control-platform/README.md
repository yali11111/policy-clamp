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
