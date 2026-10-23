# RAN Congestion Control UI

Interface Angular de supervision des services RAN.

## Modules

- Dashboard
- KPI Monitoring
- Congestion et prédictions
- Historique des actions
- Participants réseau
- Configuration

## Backend

L'interface utilise une API HTTP accessible sous /api.

Le proxy de développement cible par défaut :

http://localhost:8080

Cette adresse doit être adaptée si les services Spring Boot
utilisent un autre port ou une API Gateway différente.

## Endpoints attendus

- GET /dashboard/summary
- GET /kpis/latest
- GET /kpis/history
- GET /congestion/events
- GET /actions
- GET /actions/{id}
- GET /participants

Ces routes sont des conventions frontend.
Leur existence doit être vérifiée dans le backend.

## Installation

Les fichiers sont préparés manuellement.
Aucune dépendance n'est installée par le script de création.

Avant toute compilation future, vérifier les versions
compatibles d'Angular, de Node.js et de TypeScript.

## Sécurité

Les actions réseau restent pilotées par le backend.
Ne pas exposer Kafka directement au navigateur.
Les opérations de contrôle doivent être protégées
par une authentification et des autorisations adaptées.
