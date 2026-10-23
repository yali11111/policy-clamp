#!/bin/sh

set -eu

ROOT="${1:-clamp-acm-ci}"

echo "=========================================="
echo "CLAMP ACM CI - Validation statique"
echo "=========================================="

FILES="
pom.xml
shared-events/pom.xml
monitoring-service/pom.xml
policy-engine-service/pom.xml
automation-controller-service/pom.xml
kafka-config/topics.properties
kafka-config/README.md
tosca/policy-types/threshold-policy.yaml
tosca/node-types/monitoring-node.yaml
tosca/node-types/policy-engine-node.yaml
tosca/node-types/automation-controller-node.yaml
tosca/compositions/closed-loop-demo.yaml
tosca/README.md
"

for RELATIVE_FILE in $FILES; do
    FILE="$ROOT/$RELATIVE_FILE"

    if [ -s "$FILE" ]; then
        echo "OK : $RELATIVE_FILE"
    else
        echo "ERREUR : fichier absent ou vide : $RELATIVE_FILE"
        exit 1
    fi
done

echo ""
echo "Validation statique terminee."
echo "Aucune compilation ou connexion a un service effectuee."
