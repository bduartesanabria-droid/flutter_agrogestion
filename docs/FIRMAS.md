# Firmas de Android y Windows

El flujo `Pruebas` firma el APK y el ejecutable de Windows cuando existen estos secretos del repositorio. Sin ellos arma los paquetes igual y deja una advertencia.

| Secreto | Qué es |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Almacén de claves `.jks` en base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Clave del almacén y de la llave |
| `ANDROID_KEY_ALIAS` | Alias de la llave (`agrogestion`) |
| `WINDOWS_PFX_BASE64` | Certificado de firma `.pfx` en base64 |
| `WINDOWS_PFX_PASSWORD` | Clave del `.pfx` |

## Android

- Con una llave fija el APK nuevo se instala encima del anterior. Con la clave de depuración, que cambia en cada compilación, Android responde "la aplicación no se instaló".
- Compilar en local: crear `android/key.properties` con `storeFile`, `storePassword`, `keyAlias` y `keyPassword`. Está ignorado por Git.
- Fuera de Google Play, Android pide permitir la instalación de orígenes desconocidos y Play Protect puede mostrar un aviso la primera vez.

## Windows

- Se firman el `.exe` y las `.dll` con SHA-256 y sello de tiempo.
- `AgroGestion_certificado.cer` es el certificado público. Para confiar en él: doble clic, Instalar certificado, Equipo local, "Editores de confianza".
- Un certificado propio muestra el nombre del editor, pero SmartScreen puede avisar la primera vez. Para que no avise hace falta un certificado de una entidad reconocida (Azure Trusted Signing, SignPath o uno comercial): se cambian los dos secretos de Windows y no hay que tocar código.
- Si el zip descargado muestra el aviso: clic derecho en el zip, Propiedades, Desbloquear, y recién entonces extraer.

## Cuidado con las llaves

El `.jks` y el `.pfx` nunca se suben al repositorio. Si se pierde el `.jks` no se podrá actualizar la aplicación instalada: guardar una copia fuera del computador.
