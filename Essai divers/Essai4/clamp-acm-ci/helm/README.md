# Déploiement Helm CLAMP ACM CI

Trois chartes sont générées :

- monitoring
- policy-engine
- automation-controller

## Prérequis pour un déploiement ultérieur

- Un cluster Kubernetes opérationnel.
- Helm installé sur la machine d'administration.
- Les images des trois services construites et disponibles.
- Un broker Kafka accessible depuis le cluster.
- Une configuration de sécurité adaptée à l'environnement.

## Configuration Kafka

La valeur par défaut est kafka:9092.

Adapter cette adresse à l'installation réelle. Pour un cluster
de production, utiliser TLS, une authentification adaptée et
des secrets Kubernetes gérés de façon sécurisée.

## Exemple de validation ultérieure

helm lint helm/monitoring
helm lint helm/policy-engine
helm lint helm/automation-controller

## Exemple de rendu sans déploiement

helm template acm-monitoring helm/monitoring
helm template acm-policy helm/policy-engine
helm template acm-automation helm/automation-controller

## Attention aux ports HTTP

Le monitoring-service et le policy-engine-service générés
précédemment ne disposent pas nécessairement d'un serveur HTTP.
Leurs Services Kubernetes ne garantissent donc pas une
accessibilité HTTP. Ne pas activer de sondes HTTP avant d'avoir
configuré un endpoint réel.

Le contrôleur d'automatisation écoute par défaut sur le port 8083.

## Exécution réelle

La valeur automation.executionEnabled reste false par défaut.
La passer à true ne suffit pas à mettre en œuvre un adaptateur
réseau sûr. Une intégration réelle doit inclure des autorisations,
des validations de cible, des limites opérationnelles, une
gestion des erreurs et une traçabilité complète.
