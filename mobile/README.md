# Helpet mobile

App Flutter (arquitectura por features, estado con Riverpod). Android por ahora
(`minSdk 23`, `targetSdk 34`, `compileSdk 34`).

## Ejecutar en un dispositivo físico Android

El backend corre en `localhost:3000` en la PC. Para que el teléfono conectado
por USB lo alcance, hay que reenviar el puerto con `adb reverse` **cada vez
que se reconecta el cable o el dispositivo**:

```
adb reverse tcp:3000 tcp:3000
```

Luego correr la app pasando la URL del backend (ya configurado en
`.vscode/launch.json` para depurar desde VS Code):

```
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Si en cambio usas un emulador Android, el valor por defecto
(`http://10.0.2.2:3000`) ya funciona sin pasar `--dart-define`.

## Google Maps (Sprint 3 — E4)

La pantalla de mapa y el selector de ubicación al crear/editar un reporte
usan `google_maps_flutter`, que necesita una API key de Google Cloud
Console **para el proyecto `helpet-app-503fd`** con estas APIs habilitadas:

- Maps SDK for Android
- Geocoding API (reverse geocoding del marcador arrastrable)

Pasos para crear la key (Google Cloud Console → APIs & Services →
Credentials → Create credentials → API key), restringida a Android con el
`applicationId` `com.helpet.app` y el SHA-1 del keystore de debug:

```
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Una vez creada, pegar el valor en `android/local.properties` (archivo
local, ya en `.gitignore`, nunca se sube al repo):

```
googleMapsApiKey=TU_KEY_AQUI
```

`android/app/build.gradle` la inyecta en `AndroidManifest.xml` vía
`manifestPlaceholders` en tiempo de compilación de Gradle — no se usa
`--dart-define` para esto porque el manifest de Android no lo lee (el
`--dart-define` solo llega al código Dart, no al manifest nativo). Mientras
`googleMapsApiKey` no tenga un valor real, el mapa se ve en gris/en blanco.

## Firebase

Ya configurado contra el proyecto real `helpet-app-503fd`
(`lib/firebase_options.dart`, generado con `flutterfire configure`). Servicios
que deben estar activos en la consola de Firebase para que la app funcione:

- **Authentication** (Correo/contraseña)
- **Firestore** (con las reglas de `firestore.rules` en la raíz del repo,
  desplegadas con `firebase deploy --only firestore:rules`)
- **Storage** (con las reglas de `storage.rules`, desplegadas con
  `firebase deploy --only storage:rules`) — necesario para subir fotos de
  reportes (E2)
