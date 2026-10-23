
#!/usr/bin/env bash
set -euo pipefail


# ============================================================
# RAN Congestion Control Platform
# PARTIE 8/8 — 2/4
# Sécurité, fiabilité et gestion des erreurs
#
# Génération de fichiers uniquement.
# Aucun service démarré, aucune compilation exécutée.
# ============================================================

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$ROOT"

mkdir -p \
    config/security \
    docs/security \
    scripts

# ------------------------------------------------------------
# 1. Politique de sécurité
# ------------------------------------------------------------

cat > config/security/action-policy.yml <<'EOF'
# Politique de référence pour les commandes RAN.
# Ce fichier est documentaire : les services ne le chargent
# pas automatiquement dans cette version.

security:
  simulation-mode: true

  action-validation:
    require-action-id: true
    require-correlation-id: true
    require-expiration: true
    reject-expired-actions: true
    reject-terminal-actions: true
    reject-unknown-action-types: true
    reject-unknown-targets: true

  execution:
    require-authorized-target: true
    require-parameter-validation: true
    require-operational-limits: true
    require-audit-record: true
    require-explicit-production-adapter: true

  replay-protection:
    enabled: true
    storage: durable
    unique-key: actionId

  kafka:
    require-authentication-in-production: true
    require-topic-acls-in-production: true
    require-encryption-in-production: true
EOF

# ------------------------------------------------------------
# 2. Variables d'environnement documentées
# ------------------------------------------------------------

cat > config/security/security.env.example <<'EOF'
# Exemple uniquement : renseigner les valeurs selon
# l'environnement et le mécanisme de secrets retenus.

RAN_ACTION_SIMULATION_MODE=true

# Ne pas enregistrer de secrets réels dans ce fichier.
# Configurer les identifiants Kafka par un gestionnaire
# de secrets ou par l'environnement sécurisé du déploiement.

KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=
KAFKA_SASL_JAAS_CONFIG=

# Les propriétés ci-dessus ne sont pas automatiquement activées
# par les KafkaConfig.java actuels.
EOF

# ------------------------------------------------------------
# 3. Politique de reprise Kafka
# ------------------------------------------------------------

cat > docs/security/KAFKA-RELIABILITY.md <<'EOF'
# Fiabilité Kafka

## 1. Règles générales

Les producteurs doivent observer les résultats asynchrones
de publication et traiter explicitement les erreurs.

Les consommateurs doivent éviter de valider un offset avant
que le traitement requis soit terminé.

Une reprise limitée ne résout pas les erreurs permanentes,
notamment les messages JSON invalides ou les contrats incompatibles.

## 2. Catégories d'erreurs

### Erreurs temporaires

Exemples :
- interruption momentanée du broker ;
- indisponibilité réseau ;
- erreur temporaire d'un service externe.

Une stratégie de reprise avec délai peut être appropriée.

### Erreurs permanentes

Exemples :
- message JSON mal formé ;
- type d'action inconnu ;
- cible non autorisée ;
- paramètres invalides ;
- contrat incompatible.

Ces erreurs doivent être classées explicitement. Une dead-letter
topic peut conserver les messages non traitables pour analyse.

## 3. Idempotence

L'idempotence du producteur Kafka ne garantit pas à elle seule
l'exécution métier unique d'une commande.

Le registre en mémoire du ran-action-service est limité :
- il disparaît au redémarrage ;
- il n'est pas partagé entre plusieurs instances ;
- il ne constitue pas un registre transactionnel durable.

En production, utiliser un stockage durable avec une contrainte
d'unicité sur actionId et une stratégie définie pour les reprises.

## 4. Publication et offsets

Pour le service de contrôle, la publication d'une action est
asynchrone. Le consommateur actuel ne coordonne pas explicitement
la confirmation de publication avec la validation de l'offset.

Il faut définir une stratégie garantissant qu'une erreur de
publication ne soit pas silencieusement perdue.

Une transaction Kafka peut aider lorsque les opérations concernées
sont dans le même périmètre transactionnel Kafka. Elle ne rend pas
automatiquement transactionnels les appels à un système externe.

## 5. Dead-letter topic

Avant la production, définir :
- le nom du topic ;
- les droits de lecture et d'écriture ;
- la politique de rétention ;
- les métadonnées d'erreur ;
- la procédure de diagnostic ;
- les conditions de rejeu contrôlé.

Ne pas rejouer automatiquement une commande opérationnelle sans
revérifier sa validité, sa cible et son expiration.
EOF

# ------------------------------------------------------------
# 4. Exigences pour les actions opérationnelles
# ------------------------------------------------------------

cat > docs/security/ACTION-SECURITY.md <<'EOF'
# Sécurité des actions RAN

## Validation avant exécution

Chaque commande doit être vérifiée avant toute opération externe.

Contrôles minimaux :
- actionId présent et conforme ;
- correlationId présent ;
- horodatage et expiration valides ;
- action non expirée ;
- statut compatible avec une nouvelle exécution ;
- type d'action autorisé ;
- cible autorisée pour le type demandé ;
- paramètres validés par une liste d'autorisation ;
- limites opérationnelles et règles de QoS respectées.

## Autorisation

Une valeur de paramètre telle que executionMode=PARTICIPANT
ne constitue pas une preuve d'autorisation.

L'autorisation doit être imposée par le composant d'exécution,
avec une identité authentifiée, une politique explicite et un
contrôle de la cible.

## Simulation

Le mode simulation doit rester actif tant que :
- l'adaptateur réel n'a pas été implémenté ;
- les autorisations ne sont pas vérifiées ;
- les limites de sécurité ne sont pas définies ;
- les tests de non-régression ne sont pas validés ;
- les mécanismes d'arrêt et de retour arrière ne sont pas définis.

## Audit

Les événements d'audit devraient inclure :
- identifiant de l'action ;
- identifiant de corrélation ;
- type d'action et cible ;
- décision de validation ;
- résultat et horodatage ;
- motif de rejet, le cas échéant.

Ne pas journaliser les secrets, jetons d'accès ou données
d'authentification.
EOF

# ------------------------------------------------------------
# 5. Vérification statique des réglages de simulation
# ------------------------------------------------------------

cat > scripts/check-simulation-defaults.sh <<'EOF'
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
EOF

chmod +x scripts/check-simulation-defaults.sh

echo
echo "PARTIE 8/8 — 2/4 générée."
echo "Fichiers créés :"
echo "  config/security/action-policy.yml"
echo "  config/security/security.env.example"
echo "  docs/security/KAFKA-RELIABILITY.md"
echo "  docs/security/ACTION-SECURITY.md"
echo "  scripts/check-simulation-defaults.sh"
echo
echo "Aucune compilation ni aucun démarrage de service."

# ============================================================
# RAN Congestion Control Platform
# PARTIE 8/8 — 3/4
# Observabilité, métriques et tests d'intégration
#
# Génération de fichiers uniquement.
# Aucune compilation, aucun service démarré.
# ============================================================

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$ROOT"

mkdir -p \
    docs/observability \
    docs/testing \
    scripts \
    config/observability \
    integration-tests

# ------------------------------------------------------------
# 1. Documentation des métriques
# ------------------------------------------------------------

cat > docs/observability/METRICS.md <<'EOF'
# Observabilité de la plateforme RAN

## Objectif

Définir les indicateurs nécessaires pour suivre la chaîne :

ran.kpi -> ran.congestion -> ran.action

Les noms ci-dessous constituent une convention de référence.
Ils ne sont pas automatiquement enregistrés par cette partie.
Chaque métrique doit être implémentée dans le service concerné.

## Métriques applicatives recommandées

### Service KPI

- ran_kpi_events_received_total
- ran_kpi_events_rejected_total
- ran_kpi_processing_duration_seconds

### Service Predictor

- ran_congestion_events_published_total
- ran_prediction_failures_total
- ran_prediction_duration_seconds

### Service Control

- ran_control_events_received_total
- ran_control_actions_requested_total
- ran_control_actions_suppressed_total
- ran_control_decision_duration_seconds

### Service Action

- ran_action_events_received_total
- ran_action_execution_total
- ran_action_execution_failures_total
- ran_action_expired_total
- ran_action_duplicates_total
- ran_action_execution_duration_seconds

## Métriques Kafka et JVM

Surveiller également, selon les métriques exposées par les
versions utilisées :

- le retard des consommateurs ;
- le nombre de reconnexions et d'erreurs ;
- les taux de publication et de consommation ;
- les erreurs de sérialisation et de désérialisation ;
- l'utilisation mémoire et les pauses GC ;
- les threads et les connexions.

Les noms exacts des métriques Kafka dépendent des bibliothèques
et de leur configuration.

## Règles de cardinalité

Ne pas utiliser cellId, actionId, correlationId ou ranNodeId
comme labels Prometheus à forte cardinalité.

Ces identifiants doivent être conservés dans les logs structurés
ou dans un système de traçabilité dédié.

Les labels doivent privilégier des dimensions bornées :
service, type d'action, statut et catégorie d'erreur.

## Alertes recommandées

- absence prolongée de messages KPI attendus ;
- hausse du retard des consommateurs ;
- hausse des erreurs de publication ;
- augmentation des commandes expirées ;
- hausse des rejets ou des erreurs de traitement ;
- indisponibilité d'un service ;
- consommation mémoire anormale.

Les seuils d'alerte doivent être déterminés à partir des mesures
réelles de l'environnement.
EOF

# ------------------------------------------------------------
# 2. Exemple de règles d'alerte Prometheus
# ------------------------------------------------------------

cat > config/observability/ran-alerts.yml <<'EOF'
# Exemple de règles Prometheus.
# Ce fichier doit être raccordé à la configuration Prometheus
# effective avant d'être chargé.
#
# Les métriques applicatives personnalisées ne sont pas toutes
# implémentées dans cette version : vérifier leur disponibilité
# avant d'activer ces règles.

groups:
  - name: ran-platform
    rules:
      - alert: RanActionExecutionFailures
        expr: increase(ran_action_execution_failures_total[5m]) > 0
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Échecs d'exécution d'actions RAN"
          description: "Des échecs ont été observés pendant la période."

      - alert: RanActionExpirations
        expr: increase(ran_action_expired_total[10m]) > 5
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Hausse des commandes RAN expirées"
          description: "Vérifier les délais de traitement et le retard Kafka."

      - alert: RanPredictionFailures
        expr: increase(ran_prediction_failures_total[5m]) > 0
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Échecs du prédicteur RAN"
          description: "Vérifier les données KPI et les erreurs applicatives."
EOF

# ------------------------------------------------------------
# 3. Plan de tests d'intégration
# ------------------------------------------------------------

cat > docs/testing/INTEGRATION-TESTS.md <<'EOF'
# Plan de tests d'intégration

## Objectif

Vérifier la cohérence des échanges entre les services sans
commander d'équipements réseau réels.

## Scénarios

### Scénario 1 : chaîne KPI et congestion

1. Publier un événement KPI de test dans un environnement Kafka isolé.
2. Vérifier que le prédicteur reçoit l'événement.
3. Vérifier la publication éventuelle d'un CongestionEvent.
4. Contrôler les champs de corrélation et les valeurs métier.

### Scénario 2 : décision de contrôle

1. Publier un événement de congestion synthétique.
2. Vérifier la décision produite par le moteur de contrôle.
3. Vérifier le type d'action, la cible et les paramètres.
4. Vérifier que le cooldown empêche les actions répétées prévues.

### Scénario 3 : exécution simulée

1. Publier un ActionEvent valide.
2. Vérifier que le service d'action le reçoit.
3. Vérifier le résultat simulé.
4. Confirmer qu'aucun adaptateur réseau réel n'est appelé.

### Scénario 4 : commande expirée

1. Publier une commande dont expiresAt est antérieur à l'heure courante.
2. Vérifier qu'elle est rejetée comme expirée.
3. Vérifier que l'exécutant n'effectue aucune opération externe.

### Scénario 5 : message invalide

1. Publier un message JSON incompatible dans un topic de test.
2. Vérifier le comportement du désérialiseur et du gestionnaire d'erreurs.
3. Vérifier qu'un message irrécupérable ne bloque pas indéfiniment
   le traitement des autres messages.

## Isolation

Les tests doivent utiliser des topics et des groupes dédiés.
Ils ne doivent pas publier dans les topics d'un environnement
de production.

Le mode simulation doit rester activé.

## Critères de validation

- contrats JSON compatibles entre producteurs et consommateurs ;
- propagation cohérente des identifiants de corrélation ;
- traitement explicite des erreurs ;
- absence d'action opérationnelle dans les tests ;
- comportement documenté lors des reprises et des rejeux.
EOF

# ------------------------------------------------------------
# 4. Vérification statique des topics
# ------------------------------------------------------------

cat > scripts/check-kafka-contracts.sh <<'EOF'
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
EOF

chmod +x scripts/check-kafka-contracts.sh

# ------------------------------------------------------------
# 5. Documentation des résultats de test
# ------------------------------------------------------------

cat > integration-tests/README.md <<'EOF'
# Tests d'intégration RAN

Ce répertoire documente les tests d'intégration à ajouter.

Les tests réels doivent être développés avec des dépendances
de test compatibles avec les versions Maven du projet.

Avant leur implémentation :

1. vérifier les constructeurs réels des contrats ran-common ;
2. vérifier les versions de Spring Boot et Spring Kafka ;
3. isoler les topics et groupes de consommateurs ;
4. désactiver tout adaptateur d'exécution réseau réel ;
5. définir des délais d'attente bornés ;
6. nettoyer les ressources après chaque test.

Aucun test d'intégration n'est exécuté par les scripts générateurs.
EOF

echo
echo "PARTIE 8/8 — 3/4 générée."
echo "Fichiers créés :"
echo "  docs/observability/METRICS.md"
echo "  config/observability/ran-alerts.yml"
echo "  docs/testing/INTEGRATION-TESTS.md"
echo "  scripts/check-kafka-contracts.sh"
echo "  integration-tests/README.md"
echo
echo "Aucune compilation, aucun test lancé, aucun service démarré."

# ============================================================
# RAN Congestion Control Platform
# PARTIE 8/8 — 4/4
# Finalisation et contrôle global d'intégration
#
# Génération de fichiers uniquement.
# Aucune compilation.
# Aucun démarrage de service.
# Aucune connexion Kafka.
# ============================================================

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$ROOT"

mkdir -p \
    scripts \
    docs/integration \
    reports

# ------------------------------------------------------------
# 1. Contrôle global de l'intégration
# ------------------------------------------------------------

cat > scripts/finalize-platform.sh <<'SCRIPT'
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
SCRIPT

chmod +x scripts/finalize-platform.sh

# ------------------------------------------------------------
# 2. Rapport documentaire de clôture
# ------------------------------------------------------------

cat > docs/integration/FINAL-CHECKLIST.md <<'EOF'
# Checklist finale — RAN Congestion Control Platform

## 1. Structure du projet

- [ ] Tous les modules attendus existent.
- [ ] Chaque module possède un POM valide.
- [ ] Tous les modules sont déclarés dans le POM racine.
- [ ] Les versions des dépendances sont cohérentes.
- [ ] La version Java cible est uniforme.

## 2. Contrats et messages

- [ ] RanKpi est compatible entre producteur et consommateur.
- [ ] CongestionEvent est compatible entre prédicteur et contrôle.
- [ ] ActionEvent est compatible entre contrôle et exécution.
- [ ] Les noms des champs JSON sont cohérents.
- [ ] Les énumérations sont compatibles.
- [ ] Les clés Kafka utilisent les identifiants métier attendus.

## 3. Kafka et fiabilité

- [ ] Les topics requis sont documentés.
- [ ] Les erreurs de publication asynchrone sont traitées.
- [ ] La stratégie de validation des offsets est documentée.
- [ ] Les erreurs de désérialisation ont un traitement défini.
- [ ] Une stratégie de dead-letter topic est définie.
- [ ] Les rejeux sont protégés par une idempotence durable.

## 4. Sécurité

- [ ] La simulation est activée par défaut.
- [ ] Les cibles sont validées et autorisées.
- [ ] Les paramètres d'action utilisent une liste d'autorisation.
- [ ] L'expiration des commandes est contrôlée.
- [ ] Les mécanismes d'audit sont définis.
- [ ] Aucun secret n'est stocké dans les fichiers d'exemple.
- [ ] Les adaptateurs opérationnels sont soumis à une validation dédiée.

## 5. Observabilité

- [ ] Les métriques documentées sont implémentées.
- [ ] Les endpoints Actuator sont vérifiés.
- [ ] Les règles Prometheus référencent des métriques disponibles.
- [ ] Les identifiants à forte cardinalité sont exclus des labels.
- [ ] Les journaux permettent de corréler les événements.

## 6. Validation finale

- [ ] Les contrôles statiques sont examinés.
- [ ] Les tests unitaires sont exécutés dans une étape ultérieure.
- [ ] Les tests d'intégration sont exécutés avec des topics isolés.
- [ ] La compilation Maven est validée dans une étape distincte.
- [ ] Aucun test ne commande un équipement réel.
- [ ] Les limites et avertissements connus sont documentés.

## Portée

Cette checklist est documentaire. Le script de finalisation
vérifie uniquement la présence de certains fichiers et éléments
textuels. Il ne remplace ni la compilation ni les tests.
EOF

# ------------------------------------------------------------
# 3. Rapport de clôture initial
# ------------------------------------------------------------

cat > reports/integration-status.md <<'EOF'
# Rapport de clôture initial

## État

La partie 8/8 fournit les scripts de vérification et la
documentation de référence.

La création de ces fichiers ne signifie pas que les modules
Maven compilent ni que les services communiquent correctement.

## Contrôles disponibles

- Structure des modules Maven.
- Présence des contrats partagés.
- Présence des configurations applicatives.
- Détection textuelle des valeurs par défaut du mode simulation.
- Présence de la documentation de sécurité et d'observabilité.

## Contrôles restant à réaliser séparément

- Compilation Maven complète.
- Tests unitaires et tests d'intégration.
- Validation syntaxique des fichiers YAML.
- Vérification des contrats JSON réels.
- Tests Kafka avec un environnement isolé.
- Validation des versions et des dépendances.
- Vérification des mécanismes d'idempotence et de reprise.

## Sécurité

Aucune action RAN réelle ne doit être autorisée sur la seule base
du succès de ces contrôles statiques.
EOF

# ------------------------------------------------------------
# 4. Résumé
# ------------------------------------------------------------

echo
echo "PARTIE 8/8 — 4/4 générée."
echo
echo "Fichiers créés :"
echo "  scripts/finalize-platform.sh"
echo "  docs/integration/FINAL-CHECKLIST.md"
echo "  reports/integration-status.md"
echo
echo "Aucune compilation ni aucun démarrage de service."
echo "Pour lancer ultérieurement le contrôle statique :"
echo "  cd \"$ROOT\""
echo "  ./scripts/finalize-platform.sh"

