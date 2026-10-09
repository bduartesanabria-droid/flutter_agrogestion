ARG REGISTRO=docker.io/library

FROM ${REGISTRO}/alpine:3.20 AS publicado

RUN apk add --no-cache curl jq unzip

ARG REPO=bduartesanabria-droid/flutter_agrogestion
ARG SOURCE_COMMIT=sin-commit

# El CI deja compiladas la web y las descargas en la ultima version publicada
RUN echo "commit ${SOURCE_COMMIT}" \
    && mkdir /app /d \
    && curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" -o /tmp/release.json \
    && url=$(jq -r '.assets[]? | select(.name=="AgroGestion_web.zip") | .browser_download_url' /tmp/release.json) \
    && if [ -z "$url" ]; then echo "La ultima version publicada no trae AgroGestion_web.zip" >&2; exit 1; fi \
    && curl -fsSL -o /tmp/web.zip "$url" \
    && unzip -q /tmp/web.zip -d /app \
    && test -f /app/index.html \
    && for f in AgroGestion.apk AgroGestion_windows.zip version.json; do \
         url=$(jq -r --arg f "$f" '.assets[]? | select(.name==$f) | .browser_download_url' /tmp/release.json); \
         if [ -z "$url" ] || ! curl -fsSL -o "/d/$f" "$url"; then rm -f /d/*; break; fi; \
       done; \
    ls -la /d

FROM ${REGISTRO}/nginx:stable-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY portada/index.html portada/privacidad.html portada/llms.txt portada/robots.txt portada/sitemap.xml portada/flutter_service_worker.js /usr/share/nginx/html/
COPY portada/css /usr/share/nginx/html/css
COPY portada/js /usr/share/nginx/html/js
COPY portada/img /usr/share/nginx/html/img
COPY portada/fonts /usr/share/nginx/html/fonts
COPY --from=publicado /app /usr/share/nginx/html/app
COPY --from=publicado /d /usr/share/nginx/html/descargas

EXPOSE 80
