#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/ac-multislice-lab"
MODULE_DIR="${PROJECT_DIR}/participant-slice"

if [ ! -d "${PROJECT_DIR}" ]; then
    printf 'Erreur : exécuter d’abord 01-structure.sh\n' >&2
    exit 1
fi

write_file() {
    local target="$1"

    if [ -e "$target" ]; then
        printf 'Conservé (existe déjà) : %s\n' "$target"
        return 0
    fi

    mkdir -p "$(dirname "$target")"
    cat > "$target"
    printf 'Créé : %s\n' "$target"
}

write_file "${MODULE_DIR}/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <groupId>org.onap.policy.clamp.acm.participant</groupId>
    <artifactId>ac-multislice-participant</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <name>AC MultiSlice Lab Participant</name>
    <description>Participant expérimental multi-slice pour ONAP ACM</description>

    <properties>
        <java.version>17</java.version>
        <maven.compiler.release>${java.version}</maven.compiler.release>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <spring-boot.version>3.3.5</spring-boot.version>
        <fabric8.version>7.1.0</fabric8.version>
        <junit.version>5.11.3</junit.version>
        <mockito.version>5.14.2</mockito.version>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-dependencies</artifactId>
                <version>${spring-boot.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <dependency>
            <groupId>io.fabric8</groupId>
            <artifactId>kubernetes-client</artifactId>
            <version>${fabric8.version}</version>
        </dependency>

        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
        </dependency>

        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-api</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>${junit.version}</version>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>org.mockito</groupId>
            <artifactId>mockito-junit-jupiter</artifactId>
            <version>${mockito.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.13.0</version>
                <configuration>
                    <release>${maven.compiler.release}</release>
                </configuration>
            </plugin>

            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.5.2</version>
                <configuration>
                    <useModulePath>false</useModulePath>
                </configuration>
            </plugin>

            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <version>${spring-boot.version}</version>
            </plugin>
        </plugins>
    </build>
</project>
EOF

printf '\nPartie 7A/8 terminée.\n'
printf 'Configuration Maven générée.\n'
printf 'Aucune compilation ni aucun service démarré.\n'

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/ac-multislice-lab"
TEST_BASE="${PROJECT_DIR}/participant-slice/src/test/java/org/onap/policy/clamp/acm/participant/multislice"

if [ ! -d "${PROJECT_DIR}" ]; then
    printf 'Erreur : exécuter d’abord 01-structure.sh\n' >&2
    exit 1
fi

write_file() {
    local target="$1"

    if [ -e "$target" ]; then
        printf 'Conservé (existe déjà) : %s\n' "$target"
        return 0
    fi

    mkdir -p "$(dirname "$target")"
    cat > "$target"
    printf 'Créé : %s\n' "$target"
}

write_file "${TEST_BASE}/models/SliceTypeTest.java" <<'EOF'
package org.onap.policy.clamp.acm.participant.multislice.models;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class SliceTypeTest {

    @Test
    void shouldParseUrllc() {
        assertEquals(SliceType.URLLC, SliceType.from("URLLC"));
    }

    @Test
    void shouldParseEmbbIgnoringCase() {
        assertEquals(SliceType.EMBB, SliceType.from("eMBB"));
        assertEquals(SliceType.EMBB, SliceType.from("embb"));
    }

    @Test
    void shouldRejectUnknownType() {
        assertThrows(
                IllegalArgumentException.class,
                () -> SliceType.from("UNKNOWN"));
    }

    @Test
    void shouldRejectNullType() {
        assertThrows(
                IllegalArgumentException.class,
                () -> SliceType.from(null));
    }
}
EOF

write_file "${TEST_BASE}/service/QuotaManagerTest.java" <<'EOF'
package org.onap.policy.clamp.acm.participant.multislice.service;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;
import org.onap.policy.clamp.acm.participant.multislice.models.SliceType;

class QuotaManagerTest {

    private final QuotaManager quotaManager =
            new QuotaManager(4000, 8192, 50);

    @Test
    void shouldAcceptRequestWithinLimits() {
        assertDoesNotThrow(() -> quotaManager.validate(
                SliceType.URLLC, 2, 1000, 1024));
    }

    @Test
    void shouldRejectCpuBudgetExceeded() {
        assertThrows(
                IllegalArgumentException.class,
                () -> quotaManager.validate(
                        SliceType.URLLC, 5, 1000, 512));
    }

    @Test
    void shouldRejectMemoryBudgetExceeded() {
        assertThrows(
                IllegalArgumentException.class,
                () -> quotaManager.validate(
                        SliceType.EMBB, 2, 500, 5000));
    }

    @Test
    void shouldRejectNegativeReplicas() {
        assertThrows(
                IllegalArgumentException.class,
                () -> quotaManager.validate(
                        SliceType.EMBB, -1, 500, 512));
    }
}
EOF

write_file "${TEST_BASE}/handler/SliceElementHandlerTest.java" <<'EOF'
package org.onap.policy.clamp.acm.participant.multislice.handler;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.onap.policy.clamp.acm.participant.multislice.models.SliceConfiguration;
import org.onap.policy.clamp.acm.participant.multislice.models.SliceType;
import org.onap.policy.clamp.acm.participant.multislice.service.SliceService;
import org.mockito.Mockito;

class SliceElementHandlerTest {

    @Test
    void shouldConvertValidProperties() {
        SliceService service = Mockito.mock(SliceService.class);
        SliceElementHandler handler =
                new SliceElementHandler(service, new ObjectMapper());

        Map<String, Object> properties = Map.of(
                "sliceId", "slice-001",
                "sliceType", "URLLC",
                "namespace", "network-slices",
                "deploymentName", "urllc-app",
                "replicas", 1,
                "cpuMillicores", 500,
                "memoryMiB", 512);

        SliceConfiguration config = handler.convert(properties);

        assertEquals("slice-001", config.getSliceId());
        assertEquals(SliceType.URLLC, config.getSliceType());
    }

    @Test
    void shouldRejectEmptyProperties() {
        SliceService service = Mockito.mock(SliceService.class);
        SliceElementHandler handler =
                new SliceElementHandler(service, new ObjectMapper());

        assertThrows(
                IllegalArgumentException.class,
                () -> handler.convert(Map.of()));
    }
}
EOF

printf '\nPartie 7B/8 terminée.\n'
printf 'Tests unitaires générés.\n'
printf 'Aucun test exécuté et aucun service démarré.\n'


set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/ac-multislice-lab"
TEST_BASE="${PROJECT_DIR}/participant-slice/src/test/java/org/onap/policy/clamp/acm/participant/multislice"

if [ ! -d "${PROJECT_DIR}" ]; then
    printf 'Erreur : exécuter d’abord 01-structure.sh\n' >&2
    exit 1
fi

write_file() {
    local target="$1"

    if [ -e "$target" ]; then
        printf 'Conservé (existe déjà) : %s\n' "$target"
        return 0
    fi

    mkdir -p "$(dirname "$target")"
    cat > "$target"
    printf 'Créé : %s\n' "$target"
}

write_file "${TEST_BASE}/parameters/ParticipantMultiSliceParametersTest.java" <<'EOF'
package org.onap.policy.clamp.acm.participant.multislice.parameters;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

import org.junit.jupiter.api.Test;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.context.annotation.Configuration;

class ParticipantMultiSliceParametersTest {

    private final ApplicationContextRunner contextRunner =
            new ApplicationContextRunner()
                    .withUserConfiguration(TestConfiguration.class);

    @Test
    void shouldLoadDefaultValues() {
        contextRunner.run(context -> {
            ParticipantMultiSliceParameters parameters =
                    context.getBean(ParticipantMultiSliceParameters.class);

            assertFalse(parameters.getKubernetes().isEnabled());
            assertEquals(
                    4000,
                    parameters.getQuota().getMaxCpuMillicores());
            assertEquals(
                    8192,
                    parameters.getQuota().getMaxMemoryMiB());
            assertEquals(
                    "network-slices",
                    parameters.getDefaults().getNamespace());
        });
    }

    @Test
    void shouldOverrideProperties() {
        contextRunner
                .withPropertyValues(
                        "slice.kubernetes.enabled=true",
                        "slice.quota.max-replicas=10",
                        "slice.defaults.namespace=test-slices")
                .run(context -> {
                    ParticipantMultiSliceParameters parameters =
                            context.getBean(
                                    ParticipantMultiSliceParameters.class);

                    assertEquals(
                            true,
                            parameters.getKubernetes().isEnabled());
                    assertEquals(
                            10,
                            parameters.getQuota().getMaxReplicas());
                    assertEquals(
                            "test-slices",
                            parameters.getDefaults().getNamespace());
                });
    }

    @Configuration(proxyBeanMethods = false)
    @EnableConfigurationProperties(ParticipantMultiSliceParameters.class)
    static class TestConfiguration {
    }
}
EOF

printf '\nPartie 7C/8 terminée.\n'
printf 'Tests de configuration générés.\n'
printf 'Aucun test exécuté et aucun service démarré.\n'