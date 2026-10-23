#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/ac-multislice-lab"

if [ ! -d "${PROJECT_DIR}" ]; then
    printf 'Erreur : exécuter d’abord 01-structure.sh\n' >&2
    exit 1
fi

write_file() {
    local target="$1"

    if [ -e "$target" ]; then
        printf 'Conservé (existe déjà) : %s\n' "$target"
        return 0
    fi

    mkdir -p "$(dirname "$target")"
    cat > "$target"
    printf 'Créé : %s\n' "$target"
}

# ------------------------------------------------------------
# README.md
# ------------------------------------------------------------

write_file "${PROJECT_DIR}/README.md" <<'EOF'
# AC MultiSlice Lab

Prototype Java/Spring Boot pour étudier la gestion applicative
de slices URLLC et eMBB dans un contexte d'orchestration réseau.

## Objectifs

- Modéliser les profils URLLC et eMBB.
- Valider les demandes de ressources CPU, mémoire et replicas.
- Gérer un état applicatif local pour chaque slice.
- Préparer une façade vers les Deployments Kubernetes.
- Préparer l'intégration avec un participant ONAP Automation
  Composition Management (ACM).

## Architecture

Le module `participant-slice` contient le code Java.

- `models/` : configuration, profils et états des slices.
- `service/` : quotas, accès Kubernetes, scaling et orchestration.
- `handler/` : adaptation des propriétés aux services métier.
- `parameters/` : paramètres Spring Boot.
- `resources/` : configuration et contrat OpenAPI.
- `src/test/` : tests unitaires et tests de configuration.

Le répertoire `ac-model/` contient un modèle déclaratif de laboratoire.
Il ne constitue pas un modèle TOSCA complet importable par ONAP ACM.

## Prérequis

- JDK 17.
- Maven 3.9 ou version compatible.
- Accès à un dépôt Maven pour télécharger les dépendances.

Un cluster Kubernetes n'est pas requis pour compiler et exécuter
les tests unitaires qui n'utilisent pas de cluster.

## Génération

Depuis le répertoire contenant les scripts :

```bash
chmod +x install-all.sh
./install-all.sh
