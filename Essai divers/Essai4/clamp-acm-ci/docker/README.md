# Docker - CLAMP ACM CI

## Fichiers

- ../.dockerignore : exclusions du contexte Docker.
- service.Dockerfile : construction multi-stage des microservices.

## Prerequis pour une construction reelle

- Docker disponible.
- Java 21 compatible avec le projet.
- Acces au depot Maven pour telecharger les dependances.
- POM racine et modules presents dans le contexte de build.

## Construire une image

Toutes les commandes suivantes sont des exemples documentaires.
Elles ne sont pas executees par les scripts de generation.

Depuis la racine du depot clamp-acm-ci :

### Monitoring

docker build \
  -f docker/service.Dockerfile \
  --build-arg MODULE=monitoring-service \
  -t clamp-acm/monitoring-service:1.0.0 .

### Policy Engine

docker build \
  -f docker/service.Dockerfile \
  --build-arg MODULE=policy-engine-service \
  -t clamp-acm/policy-engine-service:1.0.0 .

### Automation Controller

docker build \
  -f docker/service.Dockerfile \
  --build-arg MODULE=automation-controller-service \
  -t clamp-acm/automation-controller-service:1.0.0 .

## Fonctionnement

L'etape build utilise Maven pour construire le module demande
et ses dependances Maven internes.

L'option -DskipTests evite l'execution des tests, mais n'evite
pas la compilation. La commande clean package compile le code
et produit le JAR.

L'image finale contient uniquement le JAR et le runtime Java,
pas le depot Maven complet.

## Limites

- Le nom du JAR suppose une version Maven 1.0.0.
- Les images de base doivent etre controlees et mises a jour.
- Les dependances Maven doivent etre accessibles au build.
- Les images doivent etre analysees avant une publication.
- Les secrets ne doivent jamais etre copies dans l'image.
- Aucun deploiement Kubernetes n'est effectue ici.
