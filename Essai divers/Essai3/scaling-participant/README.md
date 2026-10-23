# Scaling Participant

## Responsabilités

Ce module fournit un participant spécialisé dans les demandes
de mise à l'échelle `SCALE_OUT` et `SCALE_IN`.

## Fonctionnement

- Vérification du type d'action.
- Vérification de la direction demandée.
- Validation du nombre de réplicas.
- Application de limites configurables.
- Simulation du résultat sans modifier une infrastructure.

## Configuration

| Variable | Valeur par défaut |
|---|---|
| SERVER_PORT | 8085 |
| RAN_SCALING_SIMULATION_MODE | true |
| RAN_SCALING_MIN_REPLICAS | 1 |
| RAN_SCALING_MAX_REPLICAS | 10 |

## Sécurité

Le mode simulation est activé par défaut.

Désactiver le mode simulation ne déclenche aucune mise à l'échelle
réelle : en l'absence d'un adaptateur de production, la demande
est rejetée.

Une future intégration devra vérifier les autorisations, la cible,
les quotas, la capacité disponible et les contraintes de disponibilité.

## Intégration

Le participant implémente l'interface `ActionParticipant` du module
`ran-action-service` et utilise le contrat `ActionEvent` de `ran-common`.

Il doit être enregistré dans le service d'exécution pour participer
au routage des actions. Le lancement autonome de ce module ne suffit
pas à le connecter automatiquement au consommateur Kafka existant.
