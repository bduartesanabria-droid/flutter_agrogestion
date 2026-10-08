# AgroGestión (app Flutter)

<details>
<summary><b>Read this in English</b></summary>

Flutter client (Android APK and web) for the AgroGestión FastAPI backend. It covers sign in, data consent, farms and lots, plantings and cycles, plant counts, adverse events, money (expenses, income, cash flow), workers, regional news, glossary and knowledge library. Each role (admin, farmer, accountant, expert) sees only what its permissions allow. Run `flutter test` before every pull request; GitHub Actions runs the same checks.

</details>

Cliente Flutter (APK de Android y web) del backend FastAPI de AgroGestión. Cubre inicio de sesión, autorización de datos, fincas y lotes, siembras y ciclos, conteo de plantas, eventos adversos, dinero (gastos, ingresos y flujo de caja), trabajadores, novedades regionales, glosario y biblioteca de conocimiento. Cada perfil (administrador, agricultor, contador y experto) ve solo lo que sus permisos permiten.

## Ejecutar

1. Levantar la API (`uvicorn app.main:app --host 0.0.0.0 --port 8000`).
2. `flutter pub get`
3. `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000` en el emulador de Android. En web, `flutter run -d chrome --web-port 8080` (el CORS del backend permite `http://localhost:8080`).

## Estructura

- `lib/app`: raíz de la app y estado compartido (`AppScope`).
- `lib/core`: tema y tokens de diseño, widgets reutilizables, cliente de la API, formato y permisos por rol.
- `lib/features/<módulo>`: `data` (repositorios), `domain` (modelos) y `presentation` (pantallas).
- `assets/fonts`: Plus Jakarta Sans y JetBrains Mono (licencia OFL).
- `test/modulos`, `test/roles`, `test/vistas`: pruebas por módulo, por rol y por pantalla; `test/support` trae la API simulada.
- `tool/capturar_vistas_test.dart`: genera PNG de cada pantalla para revisar el diseño sin emulador.

## Pruebas

```bash
flutter analyze
flutter test
flutter test tool/capturar_vistas_test.dart --dart-define=CAPTURAS=build/capturas
```

Las pruebas de pantalla corren en cuatro anchos (320, 390, 820 y 1280 px) y fallan si algo se desborda. El flujo de GitHub Actions (`.github/workflows/pruebas.yml`) corre formato, análisis, las tres suites y la construcción web y APK.
