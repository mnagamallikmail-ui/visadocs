# Stage 1: Build stage
FROM gradle:8-jdk21-alpine AS build
WORKDIR /app
COPY . .
RUN gradle bootJar -x test

# Stage 2: Execution stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
# Install LibreOffice and true-type fonts for high-performance native PDF generation
RUN apk update && apk add --no-cache libreoffice ttf-dejavu ttf-liberation font-noto
# Copy the built jar file from Stage 1
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
