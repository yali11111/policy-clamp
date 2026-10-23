
#!/usr/bin/env bash

set -eu

# Racine du projet, indépendante du répertoire courant.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/ac-multislice-lab"

printf '%s\n' "Création de la structure du projet..."
printf 'Répertoire cible : %s\n' "$PROJECT_DIR"

# Modèle Automation Composition.
mkdir -p "${PROJECT_DIR}/ac-model"

# Sources du participant multi-slice.
JAVA_DIR="${PROJECT_DIR}/participant-slice/src/main/java/org/onap/policy/clamp/acm/participant/multislice"

mkdir -p "${JAVA_DIR}/handler"
mkdir -p "${JAVA_DIR}/models"
mkdir -p "${JAVA_DIR}/service"
mkdir -p "${JAVA_DIR}/parameters"
mkdir -p "${JAVA_DIR}/controller"
mkdir -p "${JAVA_DIR}/exception"
mkdir -p "${JAVA_DIR}/configurations"

# Ressources Spring Boot.
mkdir -p "${PROJECT_DIR}/participant-slice/src/main/resources/config"
mkdir -p "${PROJECT_DIR}/participant-slice/src/main/resources/openapi"

# Tests.
TEST_DIR="${PROJECT_DIR}/participant-slice/src/test/java/org/onap/policy/clamp/acm/participant/multislice"

mkdir -p "${TEST_DIR}/handler"
mkdir -p "${TEST_DIR}/models"
mkdir -p "${TEST_DIR}/service"
mkdir -p "${TEST_DIR}/parameters"
mkdir -p "${PROJECT_DIR}/participant-slice/src/test/resources"

# Documentation.
mkdir -p "${PROJECT_DIR}/docs"

# Fichier README initial, uniquement s'il n'existe pas déjà.
if [ ! -f "${PROJECT_DIR}/README.md" ]; then
    cat > "${PROJECT_DIR}/README.md" <<'EOF'
# AC MultiSlice Lab

Participant expérimental ONAP ACM pour l'orchestration de slices URLLC
et eMBB.

Le projet est généré par scripts Shell indépendants.

Aucun conteneur, cluster Kubernetes ou service externe n'est démarré
pendant la génération des fichiers.

Voir les scripts d'installation et la documentation pour la suite.
EOF
fi

# Fichier .gitignore initial, sans écraser un fichier existant.
if [ ! -f "${PROJECT_DIR}/.gitignore" ]; then
    cat > "${PROJECT_DIR}/.gitignore" <<'EOF'
target/
*.class
*.log
.idea/
.vscode/
.DS_Store
EOF
fi

printf '\nArborescence créée :\n'

find "${PROJECT_DIR}" -type d | sort

printf '\nPartie 1/8 terminée.\n'
printf 'Aucun fichier existant n’a été écrasé.\n'
printf 'Aucun service n’a été démarré.\n'
