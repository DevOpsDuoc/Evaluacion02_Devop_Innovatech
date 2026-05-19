# Dockerfile multi-stage para el backend Spring Boot
# Construye la aplicación con Maven y usa un runtime JRE slim.

FROM maven:3.9.9 AS builder
WORKDIR /app

COPY pom.xml .
COPY src ./src

RUN mvn -B -DskipTests package

FROM eclipse-temurin:17-jre AS runtime
WORKDIR /app

COPY --from=builder /app/target/*.jar /app/app.jar

RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

EXPOSE 3001
ENV JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
