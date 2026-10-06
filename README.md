# agrogestion

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Despliegue en Coolify

1. Crea un recurso **Docker Compose** conectado a este repositorio. Coolify
   encontrará el archivo `docker-compose.yml` en la raíz del repositorio.
2. En las variables del recurso, define `API_BASE_URL` con la URL pública HTTPS
   de la API, por ejemplo `https://api.example.com`. El Compose la pasa como
   argumento de build porque queda compilada dentro de Flutter Web.
3. Asigna el dominio de la aplicación al servicio `agrogestion` en el puerto
   `80`. Coolify puede encargarse del proxy y del certificado HTTPS.

El backend debe permitir el dominio de la aplicación en su configuración CORS.
La aplicación usa almacenamiento seguro del navegador para la sesión, por lo
que el despliegue debe servirse mediante HTTPS.

Si prefieres desplegar con el recurso **Dockerfile** en vez de Docker Compose,
usa el `Dockerfile` de la raíz y configura `API_BASE_URL` como argumento de
build.
