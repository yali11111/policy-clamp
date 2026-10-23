# Observabilité de la plateforme RAN

## Objectif

Définir les indicateurs nécessaires pour suivre la chaîne :

ran.kpi -> ran.congestion -> ran.action

Les noms ci-dessous constituent une convention de référence.
Ils ne sont pas automatiquement enregistrés par cette partie.
Chaque métrique doit être implémentée dans le service concerné.

## Métriques applicatives recommandées

### Service KPI

- ran_kpi_events_received_total
- ran_kpi_events_rejected_total
- ran_kpi_processing_duration_seconds

### Service Predictor

- ran_congestion_events_published_total
- ran_prediction_failures_total
- ran_prediction_duration_seconds

### Service Control

- ran_control_events_received_total
- ran_control_actions_requested_total
- ran_control_actions_suppressed_total
- ran_control_decision_duration_seconds

### Service Action

- ran_action_events_received_total
- ran_action_execution_total
- ran_action_execution_failures_total
- ran_action_expired_total
- ran_action_duplicates_total
- ran_action_execution_duration_seconds

## Métriques Kafka et JVM

Surveiller également, selon les métriques exposées par les
versions utilisées :

- le retard des consommateurs ;
- le nombre de reconnexions et d'erreurs ;
- les taux de publication et de consommation ;
- les erreurs de sérialisation et de désérialisation ;
- l'utilisation mémoire et les pauses GC ;
- les threads et les connexions.

Les noms exacts des métriques Kafka dépendent des bibliothèques
et de leur configuration.

## Règles de cardinalité

Ne pas utiliser cellId, actionId, correlationId ou ranNodeId
comme labels Prometheus à forte cardinalité.

Ces identifiants doivent être conservés dans les logs structurés
ou dans un système de traçabilité dédié.

Les labels doivent privilégier des dimensions bornées :
service, type d'action, statut et catégorie d'erreur.

## Alertes recommandées

- absence prolongée de messages KPI attendus ;
- hausse du retard des consommateurs ;
- hausse des erreurs de publication ;
- augmentation des commandes expirées ;
- hausse des rejets ou des erreurs de traitement ;
- indisponibilité d'un service ;
- consommation mémoire anormale.

Les seuils d'alerte doivent être déterminés à partir des mesures
réelles de l'environnement.
