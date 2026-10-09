FROM debian:bookworm-slim AS build

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "${FLUTTER_HOME}" \
    && flutter precache --web

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG API_BASE_URL
RUN test -n "$API_BASE_URL" || (echo "API_BASE_URL must be set to the public API URL." >&2 && exit 1) \
    && flutter build web --release --base-href /app/ --dart-define="API_BASE_URL=${API_BASE_URL}"

FROM alpine:3.20 AS descargas

RUN apk add --no-cache curl jq

ARG REPO=bduartesanabria-droid/flutter_agrogestion
ARG SOURCE_COMMIT=sin-commit

# Baja la ultima version publicada; si falta alguno de los tres archivos no publica ninguno
RUN echo "commit ${SOURCE_COMMIT}" \
    && mkdir /d \
    && (curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" -o /tmp/release.json || echo '{}' > /tmp/release.json) \
    && for f in AgroGestion.apk AgroGestion_windows.zip version.json; do \
         url=$(jq -r --arg f "$f" '.assets[]? | select(.name==$f) | .browser_download_url' /tmp/release.json); \
         if [ -z "$url" ] || ! curl -fsSL -o "/d/$f" "$url"; then rm -f /d/*; break; fi; \
       done; \
    ls -la /d

FROM nginx:stable-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY portada/index.html portada/privacidad.html portada/llms.txt portada/robots.txt portada/sitemap.xml /usr/share/nginx/html/
COPY portada/css /usr/share/nginx/html/css
COPY portada/js /usr/share/nginx/html/js
COPY portada/img /usr/share/nginx/html/img
COPY portada/fonts /usr/share/nginx/html/fonts
COPY --from=build /app/build/web /usr/share/nginx/html/app
COPY --from=descargas /d /usr/share/nginx/html/descargas

EXPOSE 80
