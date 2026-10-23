# Flux du participant CLAMP / ACM

1. Une composition d'automatisation est définie dans ONAP ACM.
2. Les éléments de composition représentent les actions RAN.
3. L'adaptateur reçoit les commandes selon le contrat ACM retenu.
4. Le service d'action valide les paramètres.
5. Le participant simulé exécute ou rejette l'action.
6. Le résultat est communiqué au mécanisme de supervision.

Ce document décrit le flux cible ; les interfaces concrètes
doivent être alignées sur la version ONAP installée.
