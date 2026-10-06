FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG API_BASE_URL
RUN test -n "$API_BASE_URL" || (echo "API_BASE_URL must be set to the public API URL." >&2 && exit 1) \
    && flutter build web --release --dart-define="API_BASE_URL=${API_BASE_URL}"

FROM nginx:stable-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
