#!/usr/bin/env bash
# install-all.sh
# Génère le projet en exécutant les 8 parties.
# Aucun service n'est démarré.

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for part in \
    01-structure.sh \
    02-models.sh \
    03-kubernetes-client.sh \
    04-slice-service.sh \
    05-acm-handler.sh \
    06-configuration.sh \
    07-maven-tests.sh \
    08-documentation.sh
do
    if [ ! -f "${SCRIPT_DIR}/${part}" ]; then
        printf 'Script manquant : %s\n' "${SCRIPT_DIR}/${part}" >&2
        exit 1
    fi

    printf '\n=== Exécution de %s ===\n' "${part}"
    bash "${SCRIPT_DIR}/${part}"
done

printf '\nGénération terminée. Aucun service n’a été démarré.\n'