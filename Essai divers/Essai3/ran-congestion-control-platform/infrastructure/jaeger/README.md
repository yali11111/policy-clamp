# Jaeger

Le service Jaeger est prévu pour recevoir les traces distribuées
émises par les services de la plateforme.

Ports prévus dans le docker-compose racine :

- 16686 : interface Web de Jaeger.
- 4317 : réception OTLP sur gRPC.
- 4318 : réception OTLP sur HTTP.

Les services applicatifs devront être configurés pour exporter
les traces vers le collecteur approprié.

Dans un déploiement conteneurisé, utiliser le nom DNS du service
Jaeger et non localhost depuis les conteneurs applicatifs.

La configuration actuelle vise un environnement de démonstration.
Elle ne définit pas de stockage durable de production.
