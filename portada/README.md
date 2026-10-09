# AgroGestión: portada web

<details>
<summary><b>Read this in English</b></summary>

Static landing page for AgroGestión (agrogestion.proyecto.sbs): explains the product, links to the web app (`/app/`) and offers the Android APK and Windows downloads. It is web only and independent from the backend and the Flutter app. Plain HTML, CSS and a little JavaScript; self-hosted fonts; no trackers. Tests: `npm test` (static checks, contrast, versions, layout at 5 widths, downloads).

</details>

Página estática de AgroGestión: presenta la aplicación, deja entrar a la versión web y ofrece las descargas para Android y Windows. Es solo web y no depende del backend ni de la app Flutter.

## Cómo se publica

La portada vive dentro del repositorio de la app Flutter y se despliega con el mismo `Dockerfile` (un solo dominio, una sola imagen de nginx):

| Ruta | Contenido |
|---|---|
| `/` | Esta portada |
| `/app/` | Aplicación web de Flutter (compilada con `--base-href /app/`) |
| `/descargas/` | APK, zip de Windows y `version.json` |
| `/privacidad.html` | Política de privacidad, leída de la API (`/politica`) |

Las descargas salen de la última versión publicada en GitHub Releases:

1. El workflow `Descargas` compila el APK y el programa de Windows en cada push a `main`, genera `version.json` (tamaño y huella reales) y crea el release `build-N`.
2. Al construir la imagen, el `Dockerfile` baja esos tres archivos de `releases/latest`. Si falta alguno, no publica ninguno y la portada muestra "Descarga no disponible por ahora".
3. Para que el servidor se reconstruya con la versión recién publicada, defina en los secretos del repositorio `COOLIFY_WEBHOOK` (URL de despliegue del recurso) y `COOLIFY_TOKEN`. Sin ellos, el release se crea igual y la imagen se reconstruye en el siguiente despliegue.

## Estructura

```
index.html, privacidad.html
css/    tokens.css (todos los colores), base.css, portada.css
js/     descargas.js, politica.js
img/    capturas reales de la app, favicon, og.png
fonts/  Plus Jakarta Sans y JetBrains Mono (OFL)
scripts/ generar_version.mjs, servir.mjs
tests/  estatica, contraste, version, vistas, descargas
```

## Descargas

`descargas/version.json` se genera con la huella real de cada archivo (lo hace el workflow; a mano sirve para probar):

```bash
node scripts/generar_version.mjs descargas 1.0.0
```

Si el archivo no existe, la página muestra "Descarga no disponible por ahora" y no inventa cifras.

## Pruebas

```bash
npm ci
npm test
```

Se necesita Chrome o Edge (o `CHROME_PATH`). Desde la raíz del repositorio: `cd portada && npm ci && npm test`. Las pruebas revisan: un solo `h1`, nada incrustado ni externo, imágenes con medidas, enlaces válidos, contraste AA de cada par de colores, ausencia de desbordes a 320, 360, 390, 820 y 1280 px (también con el texto al 200%), tarjetas del mismo tamaño, menú corto, teclado y foco, preguntas frecuentes, política de privacidad y las descargas con y sin `version.json`.

## Datos pendientes del equipo

- Correo de contacto (hoy el pie no muestra contacto).
- Versión mínima de Android (hoy la portada no la menciona).
- Confirmar si la aplicación es gratuita (hoy la portada no habla de precio).
