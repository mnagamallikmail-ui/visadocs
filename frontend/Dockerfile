# Stage 1: Flutter Build
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
ARG BUILD_COMMIT=2ca9545
ARG BUILD_TIMESTAMP="2026-10-04 19:54 IST"
ARG BUILD_ENV=Production

COPY . .
# Get dependencies and build Flutter web for release
RUN flutter pub get
RUN flutter build web --release --dart-define=BUILD_COMMIT=${BUILD_COMMIT} --dart-define=BUILD_TIMESTAMP="${BUILD_TIMESTAMP}" --dart-define=BUILD_ENV=${BUILD_ENV}

# Stage 2: Nginx Web Server
FROM nginx:alpine
# Copy custom Nginx configuration with SPA fallback and asset caching
COPY nginx.conf /etc/nginx/conf.d/default.conf
# Copy the compiled web assets from Stage 1 into Nginx default public directory
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
