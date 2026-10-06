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

1. Crea un recurso **Dockerfile** conectado a este repositorio y usa la raíz
   del repositorio como directorio de build.
2. En **Build Arguments**, define `API_BASE_URL` con la URL pública HTTPS de la
   API, por ejemplo `https://api.example.com`. Es un argumento de build porque
   la URL queda compilada dentro de la aplicación Flutter Web.
3. Configura el puerto del contenedor como `80` y asigna el dominio de la
   aplicación. Coolify puede encargarse del proxy y del certificado HTTPS.

El backend debe permitir el dominio de la aplicación en su configuración CORS.
La aplicación usa almacenamiento seguro del navegador para la sesión, por lo
que el despliegue debe servirse mediante HTTPS.
