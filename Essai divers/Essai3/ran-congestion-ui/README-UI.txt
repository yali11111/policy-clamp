RAN CONGESTION CONTROL
Frontend Angular

Organisation :
- core/config       : configuration de l'API
- core/models       : modèles de données
- core/services     : communication HTTP
- core/interceptors : gestion des erreurs HTTP
- layout            : structure générale et navigation
- shared            : composants réutilisables
- pages             : écrans de supervision
- environments      : configuration des environnements

Intégration :
- Backend existant : Spring Boot
- Communication    : HTTP REST
- Préfixe API      : /api
- Actualisation    : configuration dans environment.ts

Contraintes :
- Aucune installation de dépendances
- Aucun démarrage de serveur
- Aucune commande npm
- Aucun accès direct à Kafka depuis Angular

Les endpoints HTTP devront être vérifiés dans le code
des contrôleurs Spring Boot existants.
