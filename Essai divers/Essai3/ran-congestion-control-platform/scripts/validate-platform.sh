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

echo "=== Vérification des modules Maven ==="

for module in "${modules[@]}"; do
    if [[ -f "$module/pom.xml" ]]; then
        ok "POM présent : $module"
    else
        warn "POM absent : $module"
    fi
done

echo
echo "=== Vérification du POM racine ==="

if [[ -f pom.xml ]]; then
    ok "POM racine présent"

    for module in "${modules[@]}"; do
        if grep -Eq \
            "<module>[[:space:]]*${module}[[:space:]]*</module>" \
            pom.xml; then
            ok "Module déclaré : $module"
        else
            warn "Module non déclaré dans le POM racine : $module"
        fi
    done
else
    error "POM racine absent"
fi

echo
echo "=== Vérification des contrats partagés ==="

common_dir="ran-common/src/main/java/org/onap/policy/ran/common"

for contract in RanKpi CongestionEvent ActionEvent; do
    found=0

    if [[ -d "$common_dir" ]]; then
        while IFS= read -r file; do
            if grep -Eq \
                "(class|record|interface|enum)[[:space:]]+${contract}([[:space:]<{]|$)" \
                "$file"; then
                found=1
                break
            fi
        done < <(find "$common_dir" -type f -name '*.java')
    fi

    if [[ "$found" -eq 1 ]]; then
        ok "Contrat trouvé : $contract"
    else
        warn "Contrat non détecté : $contract"
    fi
done

echo
echo "=== Vérification des configurations Kafka ==="

for module in \
    ran-kpi-service \
    ran-predictor-service \
    ran-control-service \
    ran-action-service; do

    file="$module/src/main/resources/application.yml"

    if [[ -f "$file" ]]; then
        ok "Configuration présente : $module"

        if grep -q 'bootstrap-servers' "$file"; then
            ok "Bootstrap Kafka configuré : $module"
        else
            warn "Bootstrap Kafka non détecté : $module"
        fi
    else
        warn "application.yml absent : $module"
    fi
done

echo
echo "=== Résultat ==="
printf 'Erreurs : %s\n' "$errors"
printf 'Avertissements : %s\n' "$warnings"

if [[ "$errors" -gt 0 ]]; then
    exit 1
fi

echo "Validation structurelle terminée."
echo "Les avertissements doivent être examinés manuellement."
echo "Aucune compilation ni connexion Kafka effectuée."
