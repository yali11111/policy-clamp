# Intégration du gestionnaire ACM

`SliceElementHandler` est un adaptateur métier autonome.

Il expose :
- `prepare(Map<String, Object>)`
- `deploy(String)`
- `undeploy(String)`
- `status(String)`

Pour le raccorder à un participant ONAP ACM réel :

1. Étendre la classe de base appropriée à la version ONAP utilisée.
2. Adapter les signatures de `deploy` et `undeploy` aux DTO ACM.
3. Extraire la configuration depuis `InstanceElementDto.inProperties()`.
4. Convertir les exceptions métier en résultats d'état ACM.
5. Appeler `ParticipantIntermediaryApi` pour publier les changements d'état.
6. Ajouter les tests avec les véritables dépendances du participant.

Ne pas déclarer l'élément comme compatible avec le runtime avant d'avoir
validé cette intégration et le modèle de composition TOSCA correspondant.
