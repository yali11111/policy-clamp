# Modeles TOSCA CLAMP ACM CI

## Contenu

- policy-types/clamp-acm-policy-types.yaml :
  types de politiques de supervision et de controle.

- node-types/clamp-acm-node-types.yaml :
  types conceptuels des trois composants.

- compositions/clamp-acm-closed-loop.yaml :
  composition illustrative de boucle fermee.

## Flux logique

1. Monitoring publie MetricsEvent sur acm.metrics.
2. Le moteur de politiques analyse les metriques.
3. Une PolicyDecisionEvent est publiee sur
   acm.policy-decisions.
4. Le controleur valide la demande.
5. L'execution reelle reste desactivee par defaut.

## Compatibilite ONAP ACM

Les types TOSCA generiques ne sont pas necessairement des types
natifs acceptes par le moteur de composition ONAP ACM.

Avant tout deploiement :

- confirmer la version ONAP ACM et son profil TOSCA ;
- verifier les types de politiques et de noeuds reconnus ;
- adapter les imports et les definitions aux modeles de cette version ;
- verifier les exigences de distribution, de controle et de runtime ;
- executer les validateurs officiels disponibles pour cette version.

La composition presentee ici est un modele de reference.
Sa generation ne prouve pas son acceptation par ONAP ACM.

## Limites fonctionnelles

Les proprietes TOSCA documentent des objectifs de configuration.
Elles ne modifient pas automatiquement le comportement des
applications Spring Boot generees dans les parties precedentes.

En particulier, le cooldown, l'approbation obligatoire et la limite
d'actions doivent etre implementes et testes dans le controleur
avant de considerer ces protections comme effectives.

Le moteur de politiques actuel renvoie MANUAL_REVIEW en cas de
depassement de seuil ; il ne genere pas automatiquement une
demande SCALE_OUT ou SCALE_IN.

## Securite

- Ne jamais activer une action reelle uniquement parce qu'un seuil
  a ete depasse.
- Verifier la cible, les droits et les limites avant toute operation.
- Conserver les identifiants de correlation et les resultats.
- Refuser les actions inconnues.
- Maintenir l'execution desactivee pendant la validation initiale.
