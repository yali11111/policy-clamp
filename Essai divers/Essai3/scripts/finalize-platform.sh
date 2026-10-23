#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

errors=0
warnings=0

error() {
    printf '[ERREUR] %s\n' "$1"
    errors=$((errors + 1))
}

warn() {
    printf '[AVERTISSEMENT] %s\n' "$1"
    warnings=$((warnings + 1))
}

ok() {
    printf '[OK] %s\n' "$1"
}

check_file() {
    local file="$1"

    if [[ -f "$file" ]]; then
        ok "Fichier présent : $file"
    else
        warn "Fichier absent : $file"
    fi
}

echo "============================================================"
echo "RAN Congestion Control Platform"
echo "Contrôle final statique"
echo "============================================================"
echo

# ------------------------------------------------------------
# A. Structure racine
# ------------------------------------------------------------

echo "=== A. Structure racine ==="

check_file pom.xml
check_file docs/integration/modules.txt
check_file docs/integration/INTEGRATION.md
check_file config/kafka-topics.env.example

# ------------------------------------------------------------
# B. Modules Maven
# ------------------------------------------------------------

echo
echo "=== B. Modules Maven ==="

modules=(
    ran-common
    ran-kpi-service
    ran-predictor-service
    ran-control-service
    ran-action-service
    ran-clamp-participant-service
    traffic-steering-participant
    scaling-participant
    network-config-participant
)

for module in "${modules[@]}"; do
    if [[ ! -d "$module" ]]; then
        warn "Répertoire absent : $module"
        continue
    fi

    if [[ -f "$module/pom.xml" ]]; then
        ok "POM présent : $module"
    else
        warn "POM absent : $module"
    fi

    if [[ -f pom.xml ]] &&
       grep -Eq \
           "<module>[[:space:]]*${module}[[:space:]]*</module>" \
           pom.xml; then
        ok "Déclaration racine présente : $module"
    else
        warn "Déclaration racine absente : $module"
    fi
done

# ------------------------------------------------------------
# C. Contrats partagés
# ------------------------------------------------------------

echo
echo "=== C. Contrats ran-common ==="

COMMON="ran-common/src/main/java/org/onap/policy/ran/common"

for contract in RanKpi CongestionEvent ActionEvent; do
    found=0

    if [[ -d "$COMMON" ]]; then
        while IFS= read -r -d '' file; do
            if grep -Eq \
                "(class|record|interface|enum)[[:space:]]+${contract}([[:space:]<{]|$)" \
                "$file"; then
                found=1
                break
            fi
        done < <(find "$COMMON" -type f -name '*.java' -print0)
    fi

    if [[ "$found" -eq 1 ]]; then
        ok "Contrat détecté : $contract"
    else
        warn "Contrat absent ou non détecté : $contract"
    fi
done

# ------------------------------------------------------------
# D. Configurations des services
# ------------------------------------------------------------

echo
echo "=== D. Configurations applicatives ==="

services=(
    ran-kpi-service
    ran-predictor-service
    ran-control-service
    ran-action-service
)

for service in "${services[@]}"; do
    file="$service/src/main/resources/application.yml"

    if [[ ! -f "$file" ]]; then
        warn "Configuration absente : $file"
        continue
    fi

    ok "Configuration présente : $service"

    if grep -q 'bootstrap-servers' "$file"; then
        ok "Paramètre Kafka présent : $service"
    else
        warn "Paramètre Kafka absent : $service"
    fi
done

# ------------------------------------------------------------
# E. Mode simulation
# ------------------------------------------------------------

echo
echo "=== E. Configuration du mode simulation ==="

check_simulation() {
    local file="$1"
    local expected="$2"

    if [[ ! -f "$file" ]]; then
        warn "Impossible de vérifier le mode simulation : $file"
        return
    fi

    if grep -Fq "$expected" "$file"; then
        ok "Valeur par défaut de simulation détectée : $file"
    else
        warn "Valeur de simulation à vérifier : $file"
    fi
}

check_simulation \
    "ran-control-service/src/main/resources/application.yml" \
    'simulation-mode: ${RAN_CONTROL_SIMULATION_MODE:true}'

check_simulation \
    "ran-action-service/src/main/resources/application.yml" \
    'simulation-mode: ${RAN_ACTION_SIMULATION_MODE:true}'

# ------------------------------------------------------------
# F. Documentation et contrôles complémentaires
# ------------------------------------------------------------

echo
echo "=== F. Documentation de sécurité et d'observabilité ==="

expected_files=(
    docs/security/ACTION-SECURITY.md
    docs/security/KAFKA-RELIABILITY.md
    docs/observability/METRICS.md
    docs/testing/INTEGRATION-TESTS.md
    config/observability/ran-alerts.yml
    scripts/validate-platform.sh
    scripts/check-simulation-defaults.sh
    scripts/check-kafka-contracts.sh
)

for file in "${expected_files[@]}"; do
    check_file "$file"
done

# ------------------------------------------------------------
# G. Rapport final
# ------------------------------------------------------------

echo
echo "============================================================"
echo "Résultat du contrôle statique"
echo "============================================================"
printf 'Erreurs : %s\n' "$errors"
printf 'Avertissements : %s\n' "$warnings"

if [[ "$errors" -gt 0 ]]; then
    echo "Contrôle terminé avec des erreurs."
    exit 1
fi

if [[ "$warnings" -gt 0 ]]; then
    echo "Contrôle terminé avec des avertissements."
    echo "Une inspection manuelle est nécessaire."
else
    echo "Tous les contrôles de présence ont réussi."
fi

echo
echo "IMPORTANT :"
echo "- Aucune compilation n'a été exécutée."
echo "- Aucun service n'a été démarré."
echo "- Aucune connexion Kafka n'a été effectuée."
echo "- Ce contrôle ne valide pas les contrats à l'exécution."
