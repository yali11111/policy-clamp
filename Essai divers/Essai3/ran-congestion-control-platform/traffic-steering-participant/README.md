# Traffic Steering Participant

## Responsabilités

Ce module implémente l'interface `ActionParticipant` du
`ran-action-service` pour traiter les commandes
`TRAFFIC_STEERING`.

## Validations

- Type d'action compatible.
- Identifiant d'action présent.
- Action non terminale et non expirée.
- Mode `balanced` ou `emergency`.
- Cellule source cohérente avec la commande.
- Paramètre `preserveQos=true`.
- Mode d'exécution `SIMULATION`.

## Sécurité

Ce participant ne contacte aucun contrôleur réseau et ne modifie
aucune configuration RAN. Les commandes en mode `PARTICIPANT`
sont rejetées.

## Intégration

Le module dépend de `ran-action-service` pour réutiliser
`ActionParticipant` et `ActionExecutionResult`.

Le package Java appartient à `org.example.ran.action` afin
de rester dans le périmètre de scan Spring Boot de
`RanActionApplication`.

Le module doit être déclaré dans le POM parent. Il doit également
être présent dans le classpath de `ran-action-service` pour que
Spring puisse découvrir ce participant.

## Tests

Les tests couvrent le type d'action, la simulation valide,
les paramètres incorrects, la cellule incohérente, le refus
du mode réel et l'expiration.
