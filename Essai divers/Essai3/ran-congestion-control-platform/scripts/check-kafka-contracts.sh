#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

errors=0

check_topic() {
    local module="$1"
    local expected="$2"
    local file="$module/src/main/resources/application.yml"

    if [[ ! -f "$file" ]]; then
        echo "[AVERTISSEMENT] Configuration absente : $file"
        return
    fi

    if grep -Fq "$expected" "$file"; then
        echo "[OK] $module : $expected"
    else
        echo "[AVERTISSEMENT] Topic non détecté : $module / $expected"
        errors=$((errors + 1))
    fi
}

echo "=== Vérification statique des topics Kafka ==="

check_topic ran-kpi-service 'ran.kpi'
check_topic ran-predictor-service 'ran.kpi'
check_topic ran-predictor-service 'ran.congestion'
check_topic ran-control-service 'ran.congestion'
check_topic ran-control-service 'ran.action'
check_topic ran-action-service 'ran.action'

echo
if [[ "$errors" -gt 0 ]]; then
    echo "Certaines configurations nécessitent une inspection."
    exit 1
fi

echo "Vérification statique terminée."
echo "Aucune connexion à Kafka n'a été effectuée."
