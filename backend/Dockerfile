# Stage 1: Build stage
FROM gradle:8-jdk21-alpine AS build
WORKDIR /app
COPY . .
RUN gradle bootJar -x test

# Stage 2: Execution stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
# Copy the built jar file from Stage 1
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
