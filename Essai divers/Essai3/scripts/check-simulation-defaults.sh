#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

errors=0

check_default() {
    local file="$1"
    local expected="$2"

    if [[ ! -f "$file" ]]; then
        echo "[AVERTISSEMENT] Fichier absent : $file"
        return
    fi

    if grep -Fq "$expected" "$file"; then
        echo "[OK] Valeur attendue trouvée dans $file"
    else
        echo "[AVERTISSEMENT] Valeur attendue non détectée dans $file"
        errors=$((errors + 1))
    fi
}

check_default \
    "ran-action-service/src/main/resources/application.yml" \
    'simulation-mode: ${RAN_ACTION_SIMULATION_MODE:true}'

check_default \
    "ran-control-service/src/main/resources/application.yml" \
    'simulation-mode: ${RAN_CONTROL_SIMULATION_MODE:true}'

echo
if [[ "$errors" -gt 0 ]]; then
    echo "Des vérifications nécessitent une inspection manuelle."
    exit 1
fi

echo "Vérification statique terminée."
echo "Ce contrôle ne garantit pas la sécurité d'une exécution réelle."
