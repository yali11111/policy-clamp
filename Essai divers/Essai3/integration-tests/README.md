# Tests d'intégration RAN

Ce répertoire documente les tests d'intégration à ajouter.

Les tests réels doivent être développés avec des dépendances
de test compatibles avec les versions Maven du projet.

Avant leur implémentation :

1. vérifier les constructeurs réels des contrats ran-common ;
2. vérifier les versions de Spring Boot et Spring Kafka ;
3. isoler les topics et groupes de consommateurs ;
4. désactiver tout adaptateur d'exécution réseau réel ;
5. définir des délais d'attente bornés ;
6. nettoyer les ressources après chaque test.

Aucun test d'intégration n'est exécuté par les scripts générateurs.
