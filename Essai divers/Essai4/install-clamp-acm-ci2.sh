#!/bin/sh
set -eu

ROOT="clamp-acm-ci"

echo "=========================================="
echo "Correction Docker - CLAMP ACM CI"
echo "=========================================="

# 1. Ajouter le plugin Spring Boot aux trois services
for SERVICE in \
    monitoring-service \
    policy-engine-service \
    automation-controller-service
do
    POM="$ROOT/$SERVICE/pom.xml"

    if ! grep -q 'spring-boot-maven-plugin' "$POM"; then
        TMP="$POM.tmp"

        awk '
        /<\/project>/ {
            print "    <build>"
            print "        <plugins>"
            print "            <plugin>"
            print "                <groupId>org.springframework.boot</groupId>"
            print "                <artifactId>spring-boot-maven-plugin</artifactId>"
            print "            </plugin>"
            print "        </plugins>"
            print "    </build>"
        }
        { print }
        ' "$POM" > "$TMP"

        mv "$TMP" "$POM"
    fi
done

# 2. Dockerfile du monitoring-service
cat > "$ROOT/monitoring-service/Dockerfile" <<'EOF'
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace

COPY . .
RUN mvn -B -pl monitoring-service -am package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /app

RUN useradd --system --uid 10001 appuser
COPY --from=build --chown=10001:10001 \
    /workspace/monitoring-service/target/*.jar /app/app.jar

USER 10001
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
EOF

# 3. Dockerfile du policy-engine-service
cat > "$ROOT/policy-engine-service/Dockerfile" <<'EOF'
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace

COPY . .
RUN mvn -B -pl policy-engine-service -am package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /app

RUN useradd --system --uid 10001 appuser
COPY --from=build --chown=10001:10001 \
    /workspace/policy-engine-service/target/*.jar /app/app.jar

USER 10001
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
EOF

# 4. Dockerfile du automation-controller-service
cat > "$ROOT/automation-controller-service/Dockerfile" <<'EOF'
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace

COPY . .
RUN mvn -B -pl automation-controller-service -am package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /app

RUN useradd --system --uid 10001 appuser
COPY --from=build --chown=10001:10001 \
    /workspace/automation-controller-service/target/*.jar /app/app.jar

USER 10001
EXPOSE 8083
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
EOF

# 5. Vérifier les fichiers et le plugin
echo ""
echo "Verification du correctif"

for SERVICE in \
    monitoring-service \
    policy-engine-service \
    automation-controller-service
do
    test -s "$ROOT/$SERVICE/Dockerfile"
    grep -q 'spring-boot-maven-plugin' "$ROOT/$SERVICE/pom.xml"

    echo "OK : $ROOT/$SERVICE/Dockerfile"
    echo "OK : plugin Spring Boot dans $ROOT/$SERVICE/pom.xml"
done

echo ""
echo "Correctif applique."
echo "Aucun build Docker ou Maven execute."