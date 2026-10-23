# ============================================================
# Etape 1 : construction Maven avec Java 21
# Contexte de build : racine du depot clamp-acm-ci
# ============================================================

FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /workspace

# Copie du projet, hors fichiers exclus par .dockerignore.
COPY . .

# Le module a construire est fourni via --build-arg MODULE=...
ARG MODULE

RUN test -n "$MODULE" \
    && test -f "$MODULE/pom.xml" \
    && mvn -B -ntp \
       -pl "$MODULE" -am \
       clean package \
       -DskipTests \
    && test -f "$MODULE/target/$MODULE-1.0.0.jar"

# ============================================================
# Etape 2 : image d'execution Java 21
# ============================================================

FROM eclipse-temurin:21-jre

WORKDIR /app

# Identite non privilegiee pour l'execution.
RUN groupadd --system app \
    && useradd --system \
       --gid app \
       --home-dir /app \
       --shell /usr/sbin/nologin \
       app

ARG MODULE

COPY --from=build \
    --chown=app:app \
    /workspace/${MODULE}/target/${MODULE}-1.0.0.jar \
    /app/app.jar

USER app

ENV JAVA_OPTS=""

# Le processus Java reste le processus principal du conteneur.
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
