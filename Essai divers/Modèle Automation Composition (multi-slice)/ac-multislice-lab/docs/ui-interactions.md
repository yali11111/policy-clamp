# Interactions du dashboard

Le module `dashboardActions.js` fournit des utilitaires pour :

- valider les identifiants ;
- construire une slice de démonstration ;
- générer des événements ;
- vérifier les limites de ressources ;
- exporter les données en JSON.

## Mode d'exécution

Toutes les opérations sont locales au navigateur.

Aucun appel REST vers ONAP ACM n'est effectué.
Aucune ressource Kubernetes n'est créée ou modifiée.

## Intégration React

Importer les fonctions nécessaires :

```jsx
import {
  buildDemoSlice,
  createDashboardEvent,
  serializeSlices,
  validateDemoResources,
} from "../services/dashboardActions.js";
```

Les opérations de scaling réel nécessitent une API backend sécurisée,
une authentification et une intégration explicitement configurée.
