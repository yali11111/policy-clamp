# Pipelines GitHub Actions

## ci.yml

Ce workflow :

1. Recupere le depot.
2. Configure Java 21.
3. Valide les POM Maven.
4. Compile les modules et execute les tests avec Maven verify.
5. Construit les trois images Docker sans publication.

Les images ne sont pas poussees vers un registre.

Le build Docker reutilise docker/service.Dockerfile et le
parametre MODULE pour construire chaque microservice.

## config-validation.yml

Ce workflow verifie la presence des fichiers structurants
du depot et execute les scripts de validation disponibles.

La validation de presence ne garantit pas la validite
syntaxique des fichiers YAML ou la compatibilite TOSCA.

## Parametres de securite

- Les permissions GitHub sont limitees a contents: read.
- Aucun secret de registre n'est necessaire.
- Aucun deploiement Kubernetes n'est execute.
- Les pull requests ne publient aucune image.

Pour la production, auditer les actions externes et les
epingler sur des SHA de commit verifies.

## Resultats attendus

Une compilation ou un test en echec bloque le job Docker.

Une erreur de configuration detectee par le workflow
config-validation provoque l'echec du job correspondant.
