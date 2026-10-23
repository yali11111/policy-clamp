# Checklist finale — RAN Congestion Control Platform

## 1. Structure du projet

- [ ] Tous les modules attendus existent.
- [ ] Chaque module possède un POM valide.
- [ ] Tous les modules sont déclarés dans le POM racine.
- [ ] Les versions des dépendances sont cohérentes.
- [ ] La version Java cible est uniforme.

## 2. Contrats et messages

- [ ] RanKpi est compatible entre producteur et consommateur.
- [ ] CongestionEvent est compatible entre prédicteur et contrôle.
- [ ] ActionEvent est compatible entre contrôle et exécution.
- [ ] Les noms des champs JSON sont cohérents.
- [ ] Les énumérations sont compatibles.
- [ ] Les clés Kafka utilisent les identifiants métier attendus.

## 3. Kafka et fiabilité

- [ ] Les topics requis sont documentés.
- [ ] Les erreurs de publication asynchrone sont traitées.
- [ ] La stratégie de validation des offsets est documentée.
- [ ] Les erreurs de désérialisation ont un traitement défini.
- [ ] Une stratégie de dead-letter topic est définie.
- [ ] Les rejeux sont protégés par une idempotence durable.

## 4. Sécurité

- [ ] La simulation est activée par défaut.
- [ ] Les cibles sont validées et autorisées.
- [ ] Les paramètres d'action utilisent une liste d'autorisation.
- [ ] L'expiration des commandes est contrôlée.
- [ ] Les mécanismes d'audit sont définis.
- [ ] Aucun secret n'est stocké dans les fichiers d'exemple.
- [ ] Les adaptateurs opérationnels sont soumis à une validation dédiée.

## 5. Observabilité

- [ ] Les métriques documentées sont implémentées.
- [ ] Les endpoints Actuator sont vérifiés.
- [ ] Les règles Prometheus référencent des métriques disponibles.
- [ ] Les identifiants à forte cardinalité sont exclus des labels.
- [ ] Les journaux permettent de corréler les événements.

## 6. Validation finale

- [ ] Les contrôles statiques sont examinés.
- [ ] Les tests unitaires sont exécutés dans une étape ultérieure.
- [ ] Les tests d'intégration sont exécutés avec des topics isolés.
- [ ] La compilation Maven est validée dans une étape distincte.
- [ ] Aucun test ne commande un équipement réel.
- [ ] Les limites et avertissements connus sont documentés.

## Portée

Cette checklist est documentaire. Le script de finalisation
vérifie uniquement la présence de certains fichiers et éléments
textuels. Il ne remplace ni la compilation ni les tests.
