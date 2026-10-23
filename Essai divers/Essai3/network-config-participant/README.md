# Network Configuration Participant

## 1. Responsabilités

Ce module fournit un participant spécialisé dans la validation
des demandes de configuration réseau.

Il implémente l'interface `ActionParticipant` du module
`ran-action-service` et utilise le contrat `ActionEvent`
fourni par `ran-common`.

## 2. Fonctionnement

Le participant :

1. Vérifie le type `NETWORK_CONFIGURATION`.
2. Refuse l'exécution réelle si aucun adaptateur n'est disponible.
3. Vérifie la présence de `configKey`, `configValue` et `target`.
4. Limite la taille des paramètres.
5. Refuse les clés non autorisées.
6. Retourne un résultat simulé sans modifier le réseau.

## 3. Paramètres acceptés

| Paramètre | Obligatoire | Description |
|---|---|---|
| configKey | Oui | Identifiant du paramètre réseau |
| configValue | Oui | Valeur demandée |
| target | Oui | Cible logique de la configuration |
| changeTicket | Non | Référence de changement |
| executionMode | Non | Métadonnée de mode d'exécution |

La longueur maximale de `configKey` est de 128 caractères.
La longueur de `configValue` est configurable.
La cible et la référence de changement sont limitées à 128 caractères.

Les clés autorisées constituent une validation applicative,
pas une politique complète d'autorisation réseau.

## 4. Configuration

| Variable | Valeur par défaut |
|---|---|
| SERVER_PORT | 8086 |
| RAN_NETWORK_CONFIG_SIMULATION_MODE | true |
| RAN_NETWORK_CONFIG_MAX_VALUE_LENGTH | 256 |

Le mode simulation est activé par défaut.

Même lorsque le mode simulation est désactivé, aucune opération
réelle n'est exécutée : les demandes sont rejetées tant qu'un
adaptateur de production n'est pas implémenté.

## 5. Tests

Les tests couvrent :

- le routage par type d'action ;
- une configuration valide ;
- les paramètres obligatoires ;
- les paramètres non autorisés ;
- les limites de longueur ;
- le refus de l'exécution réelle sans adaptateur ;
- les valeurs de configuration invalides.

Exécution ultérieure des tests depuis la racine du projet :

    mvn -pl network-config-participant -am test

Cette commande n'est pas exécutée par le présent script.

## 6. Intégration

Le module doit être déclaré dans le POM parent Maven.

Le participant doit ensuite être enregistré dans le mécanisme
de routage du service d'exécution des actions.

Le démarrage autonome de cette application Spring Boot ne la
connecte pas automatiquement au topic Kafka `ran.action`.

## 7. Limites avant production

Une intégration réelle nécessitera notamment :

- une API ou un contrôleur réseau explicitement configuré ;
- une authentification et une autorisation par cible ;
- une liste blanche de paramètres et de valeurs ;
- une validation des changements et des règles de QoS ;
- une journalisation d'audit sans données sensibles ;
- une stratégie de retour arrière ;
- une idempotence durable et une gestion des erreurs ;
- des tests d'intégration sur un environnement isolé.

Aucune modification d'équipement réseau n'est effectuée par
cette implémentation.
