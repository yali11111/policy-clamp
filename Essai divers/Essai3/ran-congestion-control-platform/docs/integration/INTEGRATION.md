# Intégration de la plateforme RAN

## Objectif

Ce document décrit les vérifications à effectuer avant la
compilation et le déploiement de la plateforme.

## Flux fonctionnel

1. ran-kpi-service publie les KPI sur ran.kpi.
2. ran-predictor-service consomme ran.kpi.
3. Le prédicteur publie les événements sur ran.congestion.
4. ran-control-service consomme ran.congestion.
5. Le service de contrôle publie les commandes sur ran.action.
6. ran-action-service consomme ran.action.
7. Les participants spécialisés sont intégrés après vérification
   de leurs contrats et de leur routage.

## Contrats

Le module ran-common doit être la source de vérité pour les
contrats échangés entre services.

Vérifier les champs, les constructeurs, les types des énumérations,
les règles de sérialisation JSON et la compatibilité des versions.

Ne pas recréer localement les contrats déjà présents.

## Topics Kafka

- ran.kpi : événements KPI.
- ran.congestion : événements de congestion.
- ran.action : commandes de contrôle.

Le topic ran.action.result reste optionnel tant que le contrat
de résultat, son producteur et ses consommateurs ne sont pas
effectivement implémentés.

## Points à vérifier

- Les modules sont déclarés dans le POM racine.
- Les dépendances internes utilisent la même version du projet.
- Les versions de Java, Spring Boot et Spring Kafka sont compatibles.
- Les clés Kafka correspondent aux identifiants métier attendus.
- Les erreurs de désérialisation sont traitées explicitement.
- Les offsets ne sont validés qu'après un traitement fiable.
- Les publications asynchrones sont suivies jusqu'à leur confirmation.
- Le mode simulation reste actif tant qu'aucun adaptateur réel
  n'a été audité et validé.

## Limites du validateur

Le script validate-platform.sh effectue des contrôles statiques
simples. Il ne valide ni la syntaxe complète du YAML, ni la
compilation Java, ni les contrats JSON, ni la connectivité Kafka.
