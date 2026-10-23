# Interface de configuration AC MultiSlice Lab

## Objectif

La page `Configuration.demo.jsx` permet de tester les paramètres
applicatifs des profils URLLC et eMBB.

## Fonctionnalités

- Sélection d'un profil et application de ses valeurs par défaut.
- Configuration du namespace et du nombre de replicas.
- Configuration CPU et mémoire par replica.
- Configuration des quotas applicatifs.
- Calcul local des ressources théoriques.
- Validation des valeurs avant enregistrement.
- Réinitialisation des paramètres.
- Export de la configuration au format JSON.
- Affichage de l'état des intégrations externes.

## Fichiers générés

- `ui-multislice/src/config/sliceConfig.js`
- `ui-multislice/src/components/ConfigField.jsx`
- `ui-multislice/src/components/ConfigSection.jsx`
- `ui-multislice/src/components/ResourceMeter.jsx`
- `ui-multislice/src/components/IntegrationStatus.jsx`
- `ui-multislice/src/pages/Configuration.demo.jsx`
- `ui-multislice/src/styles/configuration.css`

## Intégration dans l'application React

Importer la feuille CSS et la page depuis le point d'entrée existant :

    import "./styles/configuration.css";
    import ConfigurationDemo from "./pages/Configuration.demo.jsx";

Puis rendre le composant dans la route ou la zone de contenu souhaitée :

    <ConfigurationDemo />

Ne pas remplacer automatiquement le routeur ou le point d'entrée existant :
adapter les imports à l'architecture réelle de l'application.

## Dépendances

La page utilise React et `lucide-react`.

Si cette dernière dépendance est absente du projet, l'ajouter avec :

    npm install lucide-react

## Limites

- L'enregistrement est local à la session React.
- Aucun backend n'est appelé.
- L'export JSON est effectué par le navigateur.
- Kubernetes, ONAP ACM et Kafka ne sont pas connectés.
- Les quotas sont des garde-fous de démonstration, pas des quotas
  effectifs du cluster.
- Les profils URLLC et eMBB ne garantissent ni latence, ni débit,
  ni qualité de service réseau.
