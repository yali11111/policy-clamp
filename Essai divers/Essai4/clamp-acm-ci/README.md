# CLAMP ACM CI

Projet de référence pour la supervision, les décisions de
politiques et l'orchestration contrôlée d'automatisations.

## Modules

- shared-events : contrats d'événements communs.
- monitoring-service : collecte et publication des métriques.
- policy-engine-service : traitement Kafka Streams.
- automation-controller-service : validation et orchestration.
- kafka-config : configuration des topics Kafka.
- tosca : types et compositions ACM.
- xtesting : tests de fumée.
- docker : définitions de conteneurs.
- helm : déploiement Kubernetes.
- .github/workflows : pipelines CI/CD.

## Flux

1. Monitoring publie les métriques.
2. Le moteur de politiques analyse les événements.
3. Une décision est publiée sur Kafka.
4. Le contrôleur valide la demande.
5. Une action autorisée est transmise à l'adaptateur concerné.
6. Le résultat est enregistré pour assurer la traçabilité.

## ONAP et CLAMP

Les fichiers TOSCA devront être adaptés à la version ONAP/ACM
réellement installée. La présence des fichiers ne garantit pas
leur acceptation par le contrôleur ACM.

## Sécurité

- Ne pas exposer Kafka directement aux interfaces utilisateur.
- Configurer TLS et les ACL Kafka.
- Valider les paramètres des actions.
- Utiliser des identifiants idempotents.
- Prévoir des contrôles d'autorisation et une piste d'audit.
- Exiger une validation appropriée pour les actions sensibles.

## Génération

Le script crée des fichiers uniquement.
Il n'installe aucune dépendance et ne démarre aucun service.
