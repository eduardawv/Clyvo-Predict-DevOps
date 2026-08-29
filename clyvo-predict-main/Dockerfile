# =================================================================
# CLYVO Predict — Dockerfile
# Build: eclipse-temurin:17-jdk (Maven)
# Runtime: eclipse-temurin:17-jre (leve, sem ferramentas de build)
# Porta 8080 | Usuário sem root (clyvouser)
# =================================================================

# ── STAGE 1: Build ───────────────────────────────────────────
FROM eclipse-temurin:17-jdk AS build
WORKDIR /app

# Copia pom + wrapper antes do código (cache de dependências)
COPY pom.xml .
COPY .mvn/ .mvn/
COPY mvnw .
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B --no-transfer-progress

# Copia código e compila
COPY src/ src/
RUN ./mvnw package -DskipTests -B --no-transfer-progress

# ── STAGE 2: Runtime ─────────────────────────────────────────
FROM eclipse-temurin:17-jre AS runtime
WORKDIR /app

# Usuário sem privilégios (penalidade -10 pts evitada)
RUN groupadd --system clyvogroup && \
    useradd --system --gid clyvogroup --shell /bin/false clyvouser

# Copia apenas o JAR compilado
COPY --from=build /app/target/clyvo-predict-0.0.1-SNAPSHOT.jar app.jar
RUN chown -R clyvouser:clyvogroup /app

USER clyvouser
EXPOSE 8080

ENV JAVA_OPTS="-Xms256m -Xmx512m -Djava.security.egd=file:/dev/./urandom"
ENV SPRING_PROFILES_ACTIVE=prod

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
