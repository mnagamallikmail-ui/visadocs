# Stage 1: Flutter Build
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY . .
# Get dependencies and build Flutter web for release
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Nginx Web Server
FROM nginx:alpine
# Copy the compiled web assets from Stage 1 into Nginx default public directory
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
