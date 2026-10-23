# Plan de tests d'intégration

## Objectif

Vérifier la cohérence des échanges entre les services sans
commander d'équipements réseau réels.

## Scénarios

### Scénario 1 : chaîne KPI et congestion

1. Publier un événement KPI de test dans un environnement Kafka isolé.
2. Vérifier que le prédicteur reçoit l'événement.
3. Vérifier la publication éventuelle d'un CongestionEvent.
4. Contrôler les champs de corrélation et les valeurs métier.

### Scénario 2 : décision de contrôle

1. Publier un événement de congestion synthétique.
2. Vérifier la décision produite par le moteur de contrôle.
3. Vérifier le type d'action, la cible et les paramètres.
4. Vérifier que le cooldown empêche les actions répétées prévues.

### Scénario 3 : exécution simulée

1. Publier un ActionEvent valide.
2. Vérifier que le service d'action le reçoit.
3. Vérifier le résultat simulé.
4. Confirmer qu'aucun adaptateur réseau réel n'est appelé.

### Scénario 4 : commande expirée

1. Publier une commande dont expiresAt est antérieur à l'heure courante.
2. Vérifier qu'elle est rejetée comme expirée.
3. Vérifier que l'exécutant n'effectue aucune opération externe.

### Scénario 5 : message invalide

1. Publier un message JSON incompatible dans un topic de test.
2. Vérifier le comportement du désérialiseur et du gestionnaire d'erreurs.
3. Vérifier qu'un message irrécupérable ne bloque pas indéfiniment
   le traitement des autres messages.

## Isolation

Les tests doivent utiliser des topics et des groupes dédiés.
Ils ne doivent pas publier dans les topics d'un environnement
de production.

Le mode simulation doit rester activé.

## Critères de validation

- contrats JSON compatibles entre producteurs et consommateurs ;
- propagation cohérente des identifiants de corrélation ;
- traitement explicite des erreurs ;
- absence d'action opérationnelle dans les tests ;
- comportement documenté lors des reprises et des rejeux.
