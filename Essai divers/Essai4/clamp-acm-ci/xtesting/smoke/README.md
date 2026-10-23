# Tests de fumee

Les tests de fumee servent a verifier les points d'entree
HTTP et la disponibilite des services une fois ceux-ci deployes.

Prerequis pour les tests HTTP :
- services demarres ;
- ports accessibles ;
- dependances et configuration correctement installees.

Les controles HTTP ne remplacent ni les tests unitaires,
ni les tests d'integration Kafka, ni la validation ONAP ACM.
