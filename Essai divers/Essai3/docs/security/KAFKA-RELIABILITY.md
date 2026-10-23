# Fiabilité Kafka

## 1. Règles générales

Les producteurs doivent observer les résultats asynchrones
de publication et traiter explicitement les erreurs.

Les consommateurs doivent éviter de valider un offset avant
que le traitement requis soit terminé.

Une reprise limitée ne résout pas les erreurs permanentes,
notamment les messages JSON invalides ou les contrats incompatibles.

## 2. Catégories d'erreurs

### Erreurs temporaires

Exemples :
- interruption momentanée du broker ;
- indisponibilité réseau ;
- erreur temporaire d'un service externe.

Une stratégie de reprise avec délai peut être appropriée.

### Erreurs permanentes

Exemples :
- message JSON mal formé ;
- type d'action inconnu ;
- cible non autorisée ;
- paramètres invalides ;
- contrat incompatible.

Ces erreurs doivent être classées explicitement. Une dead-letter
topic peut conserver les messages non traitables pour analyse.

## 3. Idempotence

L'idempotence du producteur Kafka ne garantit pas à elle seule
l'exécution métier unique d'une commande.

Le registre en mémoire du ran-action-service est limité :
- il disparaît au redémarrage ;
- il n'est pas partagé entre plusieurs instances ;
- il ne constitue pas un registre transactionnel durable.

En production, utiliser un stockage durable avec une contrainte
d'unicité sur actionId et une stratégie définie pour les reprises.

## 4. Publication et offsets

Pour le service de contrôle, la publication d'une action est
asynchrone. Le consommateur actuel ne coordonne pas explicitement
la confirmation de publication avec la validation de l'offset.

Il faut définir une stratégie garantissant qu'une erreur de
publication ne soit pas silencieusement perdue.

Une transaction Kafka peut aider lorsque les opérations concernées
sont dans le même périmètre transactionnel Kafka. Elle ne rend pas
automatiquement transactionnels les appels à un système externe.

## 5. Dead-letter topic

Avant la production, définir :
- le nom du topic ;
- les droits de lecture et d'écriture ;
- la politique de rétention ;
- les métadonnées d'erreur ;
- la procédure de diagnostic ;
- les conditions de rejeu contrôlé.

Ne pas rejouer automatiquement une commande opérationnelle sans
revérifier sa validité, sa cible et son expiration.
