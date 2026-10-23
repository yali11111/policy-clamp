# Sécurité des actions RAN

## Validation avant exécution

Chaque commande doit être vérifiée avant toute opération externe.

Contrôles minimaux :
- actionId présent et conforme ;
- correlationId présent ;
- horodatage et expiration valides ;
- action non expirée ;
- statut compatible avec une nouvelle exécution ;
- type d'action autorisé ;
- cible autorisée pour le type demandé ;
- paramètres validés par une liste d'autorisation ;
- limites opérationnelles et règles de QoS respectées.

## Autorisation

Une valeur de paramètre telle que executionMode=PARTICIPANT
ne constitue pas une preuve d'autorisation.

L'autorisation doit être imposée par le composant d'exécution,
avec une identité authentifiée, une politique explicite et un
contrôle de la cible.

## Simulation

Le mode simulation doit rester actif tant que :
- l'adaptateur réel n'a pas été implémenté ;
- les autorisations ne sont pas vérifiées ;
- les limites de sécurité ne sont pas définies ;
- les tests de non-régression ne sont pas validés ;
- les mécanismes d'arrêt et de retour arrière ne sont pas définis.

## Audit

Les événements d'audit devraient inclure :
- identifiant de l'action ;
- identifiant de corrélation ;
- type d'action et cible ;
- décision de validation ;
- résultat et horodatage ;
- motif de rejet, le cas échéant.

Ne pas journaliser les secrets, jetons d'accès ou données
d'authentification.
