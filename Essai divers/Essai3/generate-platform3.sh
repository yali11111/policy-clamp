
#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# RAN Congestion Control Platform
# PARTIE 7B/8 — 3/3 — MOITIÉ 1/2
# Network Configuration Participant
#
# Génération de fichiers uniquement.
# Aucun service n'est démarré.
# ============================================================

BASE="network-config-participant"
PKG="$BASE/src/main/java/org/example/ran/networkconfig"

mkdir -p \
  "$PKG/participant" \
  "$BASE/src/main/resources"

# ------------------------------------------------------------
# 1. NetworkConfigParticipant.java
# ------------------------------------------------------------

cat > "$PKG/participant/NetworkConfigParticipant.java" <<'EOF'
package org.example.ran.networkconfig.participant;

import org.example.ran.action.participant.ActionParticipant;
import org.example.ran.action.service.ActionExecutionResult;
import org.onap.policy.ran.common.ActionEvent;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Set;

/**
 * Participant de configuration réseau.
 *
 * Cette implémentation valide et simule les demandes.
 * Elle ne contacte aucun équipement, contrôleur ou API externe.
 */
@Component
public class NetworkConfigParticipant implements ActionParticipant {

    private static final Set<String> ALLOWED_PARAMETERS = Set.of(
            "configKey",
            "configValue",
            "target",
            "changeTicket"
    );

    private final boolean simulationMode;
    private final int maxValueLength;

    public NetworkConfigParticipant(
            @Value("${ran.network-config.simulation-mode:true}")
            boolean simulationMode,
            @Value("${ran.network-config.max-value-length:256}")
            int maxValueLength) {

        if (maxValueLength < 1 || maxValueLength > 4096) {
            throw new IllegalArgumentException(
                    "maxValueLength must be between 1 and 4096");
        }

        this.simulationMode = simulationMode;
        this.maxValueLength = maxValueLength;
    }

    @Override
    public boolean supports(ActionEvent action) {
        return action != null
                && action.actionType()
                == ActionEvent.ActionType.NETWORK_CONFIGURATION;
    }

    @Override
    public ActionExecutionResult execute(ActionEvent action) {
        if (!supports(action)) {
            return ActionExecutionResult.rejected(
                    action == null ? "unknown" : action.actionId(),
                    "Type d'action incompatible avec NetworkConfigParticipant"
            );
        }

        if (!simulationMode) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "Exécution réelle indisponible : aucun adaptateur réseau configuré"
            );
        }

        Map<String, String> parameters = action.parameters();

        if (parameters == null || parameters.isEmpty()) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "Paramètres de configuration absents"
            );
        }

        for (String key : parameters.keySet()) {
            if (!ALLOWED_PARAMETERS.contains(key)
                    && !key.equals("executionMode")) {
                return ActionExecutionResult.rejected(
                        action.actionId(),
                        "Paramètre de configuration non autorisé : " + key
                );
            }
        }

        String configKey = parameters.get("configKey");
        String configValue = parameters.get("configValue");
        String target = parameters.get("target");
        String changeTicket = parameters.get("changeTicket");

        if (configKey == null || configKey.isBlank()) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "configKey est obligatoire"
            );
        }

        if (configValue == null || configValue.isBlank()) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "configValue est obligatoire"
            );
        }

        if (configKey.length() > 128) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "configKey dépasse la longueur autorisée"
            );
        }

        if (configValue.length() > maxValueLength) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "configValue dépasse la longueur autorisée"
            );
        }

        if (target == null || target.isBlank()) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "La cible réseau est obligatoire"
            );
        }

        if (target.length() > 128) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "La cible réseau dépasse la longueur autorisée"
            );
        }

        if (changeTicket != null && changeTicket.length() > 128) {
            return ActionExecutionResult.rejected(
                    action.actionId(),
                    "changeTicket dépasse la longueur autorisée"
            );
        }

        /*
         * Aucun changement réel n'est effectué.
         * Ne pas journaliser configValue : il peut contenir
         * une donnée opérationnelle sensible.
         */
        return ActionExecutionResult.success(
                action.actionId(),
                "Configuration validée et simulée : target="
                        + target
                        + ", configKey="
                        + configKey
                        + ", changeTicket="
                        + (changeTicket == null ? "absent" : "présent")
                        + " ; aucune modification réseau effectuée",
                true
        );
    }
}
EOF

# ------------------------------------------------------------
# 2. NetworkConfigParticipantApplication.java
# ------------------------------------------------------------

cat > "$PKG/NetworkConfigParticipantApplication.java" <<'EOF'
package org.example.ran.networkconfig;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(
        scanBasePackages = {
                "org.example.ran.networkconfig"
        }
)
public class NetworkConfigParticipantApplication {

    public static void main(String[] args) {
        SpringApplication.run(
                NetworkConfigParticipantApplication.class,
                args
        );
    }
}
EOF

# ------------------------------------------------------------
# 3. application.yml
# ------------------------------------------------------------

cat > "$BASE/src/main/resources/application.yml" <<'EOF'
spring:
  application:
    name: network-config-participant

server:
  port: ${SERVER_PORT:8086}

management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus
  endpoint:
    health:
      probes:
        enabled: true

ran:
  network-config:
    simulation-mode: ${RAN_NETWORK_CONFIG_SIMULATION_MODE:true}
    max-value-length: ${RAN_NETWORK_CONFIG_MAX_VALUE_LENGTH:256}

logging:
  level:
    root: INFO
    org.example.ran.networkconfig: INFO
EOF

# ------------------------------------------------------------
# 4. pom.xml
# ------------------------------------------------------------

cat > "$BASE/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.example.ran</groupId>
        <artifactId>ran-congestion-control-platform</artifactId>
        <version>1.0.0-SNAPSHOT</version>
        <relativePath>../pom.xml</relativePath>
    </parent>

    <artifactId>network-config-participant</artifactId>
    <name>Network Configuration Participant</name>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>org.example.ran</groupId>
            <artifactId>ran-common</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.example.ran</groupId>
            <artifactId>ran-action-service</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-configuration-processor</artifactId>
            <optional>true</optional>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
EOF

echo "PARTIE 7B/8 — 3/3, moitié 1/2 générée."
echo "Module : network-config-participant"
echo "Aucune compilation ou activation de service exécutée."


# ============================================================
# RAN Congestion Control Platform
# PARTIE 7B/8 — 3/3 — PARTIE 2/2
# Tests et documentation du network-config-participant
#
# Génération de fichiers uniquement.
# Aucun service n'est démarré.
# ============================================================

BASE="network-config-participant"
TEST="$BASE/src/test/java/org/example/ran/networkconfig/participant"

mkdir -p "$TEST"

# ------------------------------------------------------------
# 5. NetworkConfigParticipantTest.java
# ------------------------------------------------------------

cat > "$TEST/NetworkConfigParticipantTest.java" <<'EOF'
package org.example.ran.networkconfig.participant;

import org.example.ran.action.service.ActionExecutionResult;
import org.junit.jupiter.api.Test;
import org.onap.policy.ran.common.ActionEvent;

import java.time.Instant;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class NetworkConfigParticipantTest {

    private static final Instant NOW =
            Instant.parse("2026-01-01T12:00:00Z");

    private ActionEvent createAction(
            ActionEvent.ActionType type,
            Map<String, String> parameters) {

        return new ActionEvent(
                "action-config-001",
                "correlation-001",
                "congestion-001",
                NOW,
                "gnb-001",
                "cell-001",
                "default",
                type,
                ActionEvent.ActionStatus.REQUESTED,
                ActionEvent.ActionTarget.NETWORK_CONFIG_PARTICIPANT,
                parameters,
                "test network configuration",
                "unit-test",
                NOW.plusSeconds(60)
        );
    }

    private Map<String, String> validParameters() {
        return Map.of(
                "configKey", "scheduler.policy",
                "configValue", "balanced",
                "target", "cell-001",
                "changeTicket", "CHANGE-001"
        );
    }

    @Test
    void supportsOnlyNetworkConfigurationActions() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 256);

        assertTrue(participant.supports(createAction(
                ActionEvent.ActionType.NETWORK_CONFIGURATION,
                validParameters()
        )));

        assertFalse(participant.supports(createAction(
                ActionEvent.ActionType.SCALE_OUT,
                validParameters()
        )));

        assertFalse(participant.supports(createAction(
                ActionEvent.ActionType.NO_OP,
                Map.of()
        )));

        assertFalse(participant.supports(null));
    }

    @Test
    void simulatesValidConfiguration() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 256);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.NETWORK_CONFIGURATION,
                        validParameters()
                )
        );

        assertEquals("SUCCEEDED", result.status());
        assertTrue(result.simulated());
        assertTrue(result.message().contains("cell-001"));
        assertTrue(result.message().contains("scheduler.policy"));
    }

    @Test
    void rejectsMissingConfigKey() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 256);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.NETWORK_CONFIGURATION,
                        Map.of(
                                "configValue", "balanced",
                                "target", "cell-001"
                        )
                )
        );

        assertEquals("REJECTED", result.status());
        assertTrue(result.message().contains("configKey"));
    }

    @Test
    void rejectsMissingConfigValue() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 256);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.NETWORK_CONFIGURATION,
                        Map.of(
                                "configKey", "scheduler.policy",
                                "target", "cell-001"
                        )
                )
        );

        assertEquals("REJECTED", result.status());
        assertTrue(result.message().contains("configValue"));
    }

    @Test
    void rejectsMissingTarget() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 256);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.NETWORK_CONFIGURATION,
                        Map.of(
                                "configKey", "scheduler.policy",
                                "configValue", "balanced"
                        )
                )
        );

        assertEquals("REJECTED", result.status());
        assertTrue(result.message().contains("cible"));
    }

    @Test
    void rejectsUnsupportedParameter() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 256);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.NETWORK_CONFIGURATION,
                        Map.of(
                                "configKey", "scheduler.policy",
                                "configValue", "balanced",
                                "target", "cell-001",
                                "shellCommand", "unexpected"
                        )
                )
        );

        assertEquals("REJECTED", result.status());
        assertTrue(result.message().contains("non autorisé"));
    }

    @Test
    void rejectsConfigValueExceedingConfiguredLimit() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 8);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.NETWORK_CONFIGURATION,
                        Map.of(
                                "configKey", "scheduler.policy",
                                "configValue", "value-too-long",
                                "target", "cell-001"
                        )
                )
        );

        assertEquals("REJECTED", result.status());
        assertTrue(result.message().contains("longueur"));
    }

    @Test
    void rejectsRealExecutionWithoutAdapter() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(false, 256);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.NETWORK_CONFIGURATION,
                        validParameters()
                )
        );

        assertEquals("REJECTED", result.status());
        assertFalse(result.simulated());
        assertTrue(result.message().contains("adaptateur"));
    }

    @Test
    void rejectsInvalidMaximumValueLength() {
        assertThrows(
                IllegalArgumentException.class,
                () -> new NetworkConfigParticipant(true, 0)
        );

        assertThrows(
                IllegalArgumentException.class,
                () -> new NetworkConfigParticipant(true, 4097)
        );
    }

    @Test
    void rejectsWrongActionType() {
        NetworkConfigParticipant participant =
                new NetworkConfigParticipant(true, 256);

        ActionExecutionResult result = participant.execute(
                createAction(
                        ActionEvent.ActionType.SCALE_OUT,
                        validParameters()
                )
        );

        assertEquals("REJECTED", result.status());
    }
}
EOF

# ------------------------------------------------------------
# 6. README.md
# ------------------------------------------------------------

cat > "$BASE/README.md" <<'EOF'
# Network Configuration Participant

## 1. Responsabilités

Ce module fournit un participant spécialisé dans la validation
des demandes de configuration réseau.

Il implémente l'interface `ActionParticipant` du module
`ran-action-service` et utilise le contrat `ActionEvent`
fourni par `ran-common`.

## 2. Fonctionnement

Le participant :

1. Vérifie le type `NETWORK_CONFIGURATION`.
2. Refuse l'exécution réelle si aucun adaptateur n'est disponible.
3. Vérifie la présence de `configKey`, `configValue` et `target`.
4. Limite la taille des paramètres.
5. Refuse les clés non autorisées.
6. Retourne un résultat simulé sans modifier le réseau.

## 3. Paramètres acceptés

| Paramètre | Obligatoire | Description |
|---|---|---|
| configKey | Oui | Identifiant du paramètre réseau |
| configValue | Oui | Valeur demandée |
| target | Oui | Cible logique de la configuration |
| changeTicket | Non | Référence de changement |
| executionMode | Non | Métadonnée de mode d'exécution |

La longueur maximale de `configKey` est de 128 caractères.
La longueur de `configValue` est configurable.
La cible et la référence de changement sont limitées à 128 caractères.

Les clés autorisées constituent une validation applicative,
pas une politique complète d'autorisation réseau.

## 4. Configuration

| Variable | Valeur par défaut |
|---|---|
| SERVER_PORT | 8086 |
| RAN_NETWORK_CONFIG_SIMULATION_MODE | true |
| RAN_NETWORK_CONFIG_MAX_VALUE_LENGTH | 256 |

Le mode simulation est activé par défaut.

Même lorsque le mode simulation est désactivé, aucune opération
réelle n'est exécutée : les demandes sont rejetées tant qu'un
adaptateur de production n'est pas implémenté.

## 5. Tests

Les tests couvrent :

- le routage par type d'action ;
- une configuration valide ;
- les paramètres obligatoires ;
- les paramètres non autorisés ;
- les limites de longueur ;
- le refus de l'exécution réelle sans adaptateur ;
- les valeurs de configuration invalides.

Exécution ultérieure des tests depuis la racine du projet :

    mvn -pl network-config-participant -am test

Cette commande n'est pas exécutée par le présent script.

## 6. Intégration

Le module doit être déclaré dans le POM parent Maven.

Le participant doit ensuite être enregistré dans le mécanisme
de routage du service d'exécution des actions.

Le démarrage autonome de cette application Spring Boot ne la
connecte pas automatiquement au topic Kafka `ran.action`.

## 7. Limites avant production

Une intégration réelle nécessitera notamment :

- une API ou un contrôleur réseau explicitement configuré ;
- une authentification et une autorisation par cible ;
- une liste blanche de paramètres et de valeurs ;
- une validation des changements et des règles de QoS ;
- une journalisation d'audit sans données sensibles ;
- une stratégie de retour arrière ;
- une idempotence durable et une gestion des erreurs ;
- des tests d'intégration sur un environnement isolé.

Aucune modification d'équipement réseau n'est effectuée par
cette implémentation.
EOF

echo "PARTIE 7B/8 — 3/3, partie 2/2 générée."
echo "Module complété : network-config-participant."
echo "Aucune compilation ou activation de service exécutée."


# ============================================================
# RAN Congestion Control Platform
# PARTIE 8/8 — 1/4
# Intégration globale et validation statique
#
# Génération de fichiers uniquement.
# Aucune compilation, aucun démarrage de service.
# ============================================================

ROOT="ran-congestion-control-platform"

if [[ ! -d "$ROOT" ]]; then
    echo "ERREUR : répertoire '$ROOT' introuvable." >&2
    echo "Exécuter ce script depuis son répertoire parent." >&2
    exit 1
fi

cd "$ROOT"

mkdir -p \
    scripts \
    docs/integration \
    config

# ------------------------------------------------------------
# 1. Manifeste des modules attendus
# ------------------------------------------------------------

cat > docs/integration/modules.txt <<'EOF'
# Modules attendus de la plateforme RAN
# Vérifier leur présence avant toute compilation.

ran-common
ran-kpi-service
ran-predictor-service
ran-control-service
ran-action-service
ran-clamp-participant-service
traffic-steering-participant
scaling-participant
network-config-participant
EOF

# ------------------------------------------------------------
# 2. Contrat documentaire des topics Kafka
# ------------------------------------------------------------

cat > config/kafka-topics.env.example <<'EOF'
# Exemple de configuration.
# Ces variables ne créent pas les topics Kafka.

KAFKA_BOOTSTRAP_SERVERS=localhost:9092

RAN_KPI_TOPIC=ran.kpi
RAN_CONGESTION_TOPIC=ran.congestion
RAN_ACTION_TOPIC=ran.action

# À activer uniquement lorsqu'un contrat de résultat commun
# et un producteur de résultats ont été implémentés.
RAN_ACTION_RESULT_TOPIC=ran.action.result
EOF

# ------------------------------------------------------------
# 3. Validation statique de la structure
# ------------------------------------------------------------

cat > scripts/validate-platform.sh <<'EOF'
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
EOF

chmod +x scripts/validate-platform.sh

# ------------------------------------------------------------
# 4. Documentation d'intégration
# ------------------------------------------------------------

cat > docs/integration/INTEGRATION.md <<'EOF'
# Intégration de la plateforme RAN

## Objectif

Ce document décrit les vérifications à effectuer avant la
compilation et le déploiement de la plateforme.

## Flux fonctionnel

1. ran-kpi-service publie les KPI sur ran.kpi.
2. ran-predictor-service consomme ran.kpi.
3. Le prédicteur publie les événements sur ran.congestion.
4. ran-control-service consomme ran.congestion.
5. Le service de contrôle publie les commandes sur ran.action.
6. ran-action-service consomme ran.action.
7. Les participants spécialisés sont intégrés après vérification
   de leurs contrats et de leur routage.

## Contrats

Le module ran-common doit être la source de vérité pour les
contrats échangés entre services.

Vérifier les champs, les constructeurs, les types des énumérations,
les règles de sérialisation JSON et la compatibilité des versions.

Ne pas recréer localement les contrats déjà présents.

## Topics Kafka

- ran.kpi : événements KPI.
- ran.congestion : événements de congestion.
- ran.action : commandes de contrôle.

Le topic ran.action.result reste optionnel tant que le contrat
de résultat, son producteur et ses consommateurs ne sont pas
effectivement implémentés.

## Points à vérifier

- Les modules sont déclarés dans le POM racine.
- Les dépendances internes utilisent la même version du projet.
- Les versions de Java, Spring Boot et Spring Kafka sont compatibles.
- Les clés Kafka correspondent aux identifiants métier attendus.
- Les erreurs de désérialisation sont traitées explicitement.
- Les offsets ne sont validés qu'après un traitement fiable.
- Les publications asynchrones sont suivies jusqu'à leur confirmation.
- Le mode simulation reste actif tant qu'aucun adaptateur réel
  n'a été audité et validé.

## Limites du validateur

Le script validate-platform.sh effectue des contrôles statiques
simples. Il ne valide ni la syntaxe complète du YAML, ni la
compilation Java, ni les contrats JSON, ni la connectivité Kafka.
EOF

echo
echo "PARTIE 8/8 — 1/4 générée."
echo "Fichiers créés :"
echo "  docs/integration/modules.txt"
echo "  config/kafka-topics.env.example"
echo "  scripts/validate-platform.sh"
echo "  docs/integration/INTEGRATION.md"
echo
echo "Aucun service démarré. Aucune compilation exécutée."

