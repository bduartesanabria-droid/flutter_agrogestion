# Conexión local AgroGestion

## Arquitectura local

- Backend: FastAPI en `http://localhost:8000`.
- Frontend: Flutter Web en `http://localhost:8080`.
- CORS permitido: `http://localhost:8080`.
- Salud de la API: `GET http://localhost:8000/health`.

## Backend

Desde `C:\Users\ASUS\Documents\GitHub\agrogestion`:

```powershell
Copy-Item .env.example .env
python -m pip install -e ".[dev]"
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

La variable `ALLOWED_ORIGINS` debe contener:

```text
http://localhost:3000,http://localhost:8080
```

El middleware de FastAPI lee esa variable en `app/core/config.py` y la aplica en `app/main.py`.

## Flutter Web

Desde `C:\Users\ASUS\Documents\GitHub\flutter_agrogestion`:

```powershell
flutter pub get
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:8000
```

`ApiClient` usa `String.fromEnvironment('API_BASE_URL')`. Si no se especifica, Flutter Web usa `http://localhost:8000` como valor local por defecto.

## Prueba rápida

Antes de abrir Flutter, verifica:

```powershell
Invoke-WebRequest http://localhost:8000/health
```

Desde Dart también se puede comprobar con:

```dart
final api = ApiClient();
final disponible = await api.checkConnection();
```

No se debe usar `Access-Control-Allow-Origin: *` en desarrollo con credenciales. La configuración actual permite explícitamente los orígenes declarados y los headers `Authorization`, `Content-Type` e `Idempotency-Key`.
