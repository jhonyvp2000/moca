# App de Moca (prototipo V1)

App Flutter para Android. Qué se construye y por qué está en `docs/prototipo-v1.md`.

## Cómo llega el APK al teléfono

GitHub arma el APK solo (`.github/workflows/apk.yml`):

- **Cada cambio en `app/`**: en GitHub, pestaña **Actions** → la ejecución más reciente → sección **Artifacts**. Se descarga un `.zip` con el APK dentro.
- **Cada entrega terminada**: se publica en **Releases** con el nombre `entrega-N`. Desde el teléfono, con tu sesión de GitHub abierta en el navegador, abre el Release y toca el `.apk`.

Para instalarlo, Android pide permitir «instalar apps de origen desconocido» para el navegador. Se acepta una sola vez.

## La llave de firma (se hace una sola vez)

Todas las versiones del APK deben firmarse con **la misma llave**. Si cambia, Android no deja actualizar: hay que desinstalar y **se pierden los datos guardados en el teléfono**. Por eso la llave la creas tú, la guardas bien y GitHub la usa desde sus secretos. Nunca se sube al repositorio.

**Una llave por app.** Moca usa su propia llave; no reutilices la de otra app tuya, como TVSamGo. Así, si una llave se pierde o se filtra, solo afecta a una app. Crear la llave de Moca no modifica las llaves de otras apps: es un archivo nuevo en su propia carpeta, y los secretos de GitHub son de cada repositorio.

1. En tu PC, con Java instalado (viene con Android Studio), abre PowerShell. Crea una carpeta solo para la llave de Moca, fuera de los proyectos, y comprueba que esté limpia:

   ```powershell
   New-Item -ItemType Directory -Force -Path F:\JVP\LLAVES\Moca
   cd F:\JVP\LLAVES\Moca
   Test-Path .\moca.jks
   ```

   Si `Test-Path` responde **False**, crea la llave:

   ```powershell
   keytool -genkeypair -v -keystore moca.jks -alias moca -keyalg RSA -keysize 2048 -validity 10000
   ```

   Si responde **True**, ya existe un `moca.jks` en esa carpeta: detente y revisa de dónde salió antes de seguir.

   El comando te pide una contraseña y algunos datos (nombre, ciudad). Usa una contraseña distinta a la de tus otras apps. Guarda `moca.jks` y la contraseña en tu respaldo. Si se pierden, no se puede actualizar la app instalada.

   Si Windows no reconoce `keytool`, está dentro de Android Studio, normalmente en `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`.

2. Convierte la llave a texto:

   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("F:\JVP\LLAVES\Moca\moca.jks")) | Set-Clipboard
   ```

3. En GitHub: repositorio `moca` → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**. Crea estos cuatro:

   | Nombre | Valor |
   |---|---|
   | `MOCA_KEYSTORE_BASE64` | Lo que copiaste en el paso 2 |
   | `MOCA_KEYSTORE_PASSWORD` | La contraseña de la llave |
   | `MOCA_KEY_ALIAS` | `moca` |
   | `MOCA_KEY_PASSWORD` | La misma contraseña |

Mientras no existan los secretos, el APK sale firmado con una llave de depuración y su nombre termina en `-depuracion`. Sirve para mirar la app, pero hay que desinstalarlo antes de instalar uno firmado con la llave de Moca.

## Armarlo en una PC (opcional)

Con Flutter 3.47.7 y Android Studio instalados:

```powershell
cd F:\JVP\CLAUDECODE\Moca\app
flutter pub get
flutter build apk --release
```

Para firmar con la llave de Moca, crea `app/android/key.properties` (no se sube al repositorio):

```
storeFile=F:/JVP/LLAVES/Moca/moca.jks
storePassword=...
keyAlias=moca
keyPassword=...
```

## Revisar antes de subir

```
dart format lib test
flutter analyze
flutter test
```
