# Scaling Participant

## Responsabilités

Le module implémente ActionParticipant pour les commandes
SCALE_OUT et SCALE_IN.

Il simule une demande de capacité et ne contacte aucun
orchestrateur ou cluster.

## Validations

- Type SCALE_OUT ou SCALE_IN.
- Identifiant présent et action non terminale.
- Expiration de la commande.
- Mode SIMULATION obligatoire.
- Composant cible présent.
- Direction cohérente avec le type d'action.
- Nombre de réplicas entier et dans les limites configurées.

## Configuration

| Variable | Défaut |
|---|---:|
| RAN_SCALING_SIMULATION_MODE | true |
| RAN_SCALING_MINIMUM_REPLICAS | 1 |
| RAN_SCALING_MAXIMUM_REPLICAS | 10 |
| RAN_SCALING_MAXIMUM_STEP | 2 |

## Limites

Le nombre de réplicas demandé est une cible absolue.
Le participant ne connaît pas la capacité actuelle et ne
calcule donc pas le delta réellement appliqué.

maximum-step est validé par ScalingPolicy mais n'est pas
appliqué à une variation réelle, faute d'état de capacité courant.

Le mode réel est rejeté tant qu'un adaptateur de production
n'a pas été développé et sécurisé.

## Intégration

Le module dépend de ran-action-service pour réutiliser
ActionParticipant et ActionExecutionResult.

Le JAR doit être présent dans le classpath de
ran-action-service pour que Spring découvre le participant.
Le module doit également être déclaré dans le POM parent.
