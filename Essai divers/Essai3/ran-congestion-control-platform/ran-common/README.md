# ran-common

Module contenant les contrats de données partagés par les
services de la plateforme.

## Classes

- RanKpi : observation des KPI radio.
- CongestionEvent : événement de congestion.
- ActionEvent : commande et état d'une action de contrôle.

## Conventions

- Horodatages : java.time.Instant, en UTC.
- Pourcentages : nombres compris entre 0 et 100.
- Confiance de prédiction : nombre compris entre 0 et 1.
- Identifiants : chaînes non vides.
- Paramètres d'action : Map<String, String>.
- Événements synthétiques : synthetic=true.

## Sérialisation

Ces modèles ne dépendent pas directement de Jackson. Les services
qui les échangent sur Kafka devront configurer explicitement leur
sérialiseur JSON et la désérialisation des types.

Le contrat JSON doit être conservé de manière compatible lors
des évolutions du schéma.

## Sécurité

Ne pas placer de données personnelles, secrets, identifiants
d'abonnés ou informations sensibles dans les événements.
