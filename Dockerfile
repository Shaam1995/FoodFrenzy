# ═══════════════════════════════════════════════════════
#  FoodFrenzy – Dockerfile
#  Multi-Stage Build: Maven Build → Lightweight Runtime
#  Java 17 | Spring Boot 3.1.3 | MySQL 8.0
# ═══════════════════════════════════════════════════════

# ──────────────────────────────────────────
# STAGE 1: Build
# ──────────────────────────────────────────
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy dependency files first (for Docker layer caching)
COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn

# Download all dependencies (cached if pom.xml unchanged)
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the JAR (skip tests for faster build)
RUN mvn clean package -DskipTests -B

# ──────────────────────────────────────────
# STAGE 2: Runtime
# ──────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine

# Add a non-root user for security
RUN addgroup -S foodfrenzy && adduser -S foodfrenzy -G foodfrenzy

WORKDIR /app

# Copy only the built JAR from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Set ownership
RUN chown foodfrenzy:foodfrenzy app.jar

# Switch to non-root user
USER foodfrenzy

# Expose Spring Boot default port
EXPOSE 8080

# Environment variables (override via docker run -e or docker-compose)
ENV SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/foodfrenzy
ENV SPRING_DATASOURCE_USERNAME=root
ENV SPRING_DATASOURCE_PASSWORD=root
ENV SPRING_JPA_HIBERNATE_DDL_AUTO=update
ENV SERVER_PORT=8080

# JVM tuning for containers
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseContainerSupport"

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
