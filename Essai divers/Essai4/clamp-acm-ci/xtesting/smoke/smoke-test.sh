#!/bin/sh

set -eu

BASE_URL="${AUTOMATION_URL:-http://localhost:8083}"
HEALTH_URL="${HEALTH_URL:-http://localhost:8083/actuator/health}"

echo "CLAMP ACM CI - Smoke test HTTP"
echo "URL de sante : $HEALTH_URL"

if ! command -v curl >/dev/null 2>&1; then
    echo "ERREUR : curl doit etre disponible pour lancer ce test."
    exit 1
fi

echo ""
echo "Verification de l'endpoint de sante"

HTTP_CODE=$(
    curl --silent --show-error \
         --output /dev/null \
         --write-out '%{http_code}' \
         "$HEALTH_URL"
) || {
    echo "ERREUR : endpoint de sante inaccessible."
    exit 1
}

if [ "$HTTP_CODE" != "200" ]; then
    echo "ERREUR : statut HTTP inattendu : $HTTP_CODE"
    exit 1
fi

echo "OK : endpoint de sante HTTP 200"

echo ""
echo "Verification de l'API de consultation"

HTTP_CODE=$(
    curl --silent --show-error \
         --output /dev/null \
         --write-out '%{http_code}' \
         "$BASE_URL/api/automation/requests"
) || {
    echo "ERREUR : API d'automatisation inaccessible."
    exit 1
}

if [ "$HTTP_CODE" != "200" ]; then
    echo "ERREUR : statut HTTP inattendu : $HTTP_CODE"
    exit 1
fi

echo "OK : API de consultation HTTP 200"
echo "Smoke tests termines."
