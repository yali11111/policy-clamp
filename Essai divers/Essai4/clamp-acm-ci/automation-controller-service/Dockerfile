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
