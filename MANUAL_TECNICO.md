# Manual técnico — Helpet

Guía para instalar, configurar, ejecutar, probar y desplegar los tres componentes de Helpet.

## 1. Arquitectura

Helpet se compone de tres componentes que se comunican por HTTP:

| Componente | Carpeta | Tecnología | Responsabilidad |
|---|---|---|---|
| Aplicación móvil | `mobile/` | Flutter (Dart), Riverpod | Interfaz de usuario, captura de fotos y ubicación, mapa |
| Backend | `backend/` | Node.js + Express | API REST, reglas de negocio, notificaciones push |
| Servicio de IA | `ai-service/` | Python + FastAPI, PyTorch | Embeddings con MobileNetV3-Large afinado (ArcFace) y comparación de fotografías |

Los tres usan el proyecto de Firebase `helpet-app-503fd`:

- **Authentication**: correo/contraseña y Google Sign-In. El backend verifica el ID token en cada petición.
- **Cloud Firestore**: única fuente de verdad (colecciones `users`, `mascotas`, `reportes`, `embeddings`, `coincidencias`, `notificacionesUsuario`, `reportesUsuario`).
- **Cloud Storage**: fotografías de reportes, mascotas y perfiles (la app sube directo; el backend guarda la URL).
- **Cloud Messaging (FCM)**: notificaciones push, enviadas solo desde el backend.

Flujo principal: la app crea un reporte → el backend lo guarda y llama al servicio de IA → el servicio de IA genera el embedding, lo compara con los reportes activos del tipo opuesto y de la misma especie, y registra las coincidencias con similitud de coseno ≥ 0,145 → el servicio de IA avisa al backend, que envía la notificación push.

## 2. Requisitos

- Flutter 3.35 con el SDK de Android (`compileSdk 36`, `minSdk 23`) y JDK 17.
- Node.js 20.
- Python 3.11 o superior.
- Una cuenta de servicio de Firebase con su archivo de credenciales (`serviceAccountKey.json`, nunca se sube al repositorio).
- Una clave de la API de Google Maps (Maps SDK for Android).
- Para desplegar: la CLI de Google Cloud (`gcloud`) autenticada en el proyecto.

## 3. Backend (`backend/`)

1. Copiar `backend/.env.example` a `backend/.env` y definir:

   | Variable | Descripción |
   |---|---|
   | `PORT` | Puerto HTTP (por defecto 3000) |
   | `GOOGLE_APPLICATION_CREDENTIALS` | Ruta al archivo de la cuenta de servicio |
   | `FIREBASE_STORAGE_BUCKET` | Bucket de Storage (`helpet-app-503fd.firebasestorage.app`) |
   | `AI_SERVICE_URL` | URL del servicio de IA |
   | `INTERNAL_API_KEY` | Clave compartida para las llamadas servidor a servidor con el servicio de IA |
   | `SIMILARITY_THRESHOLD` | Solo informativo para `GET /admin/metricas`; debe coincidir con el del servicio de IA |
   | `CORS_ORIGIN` | Opcional. Orígenes permitidos, separados por comas |
   | `LOG_LEVEL` | Opcional. `error`, `warn`, `info` (por defecto) o `debug` |

2. Instalar y ejecutar:

   ```bash
   cd backend
   npm install
   npm run dev        # desarrollo, con recarga automática
   npm start          # producción
   ```

3. Dar rol de administrador a un usuario (custom claim `rol` del token):

   ```bash
   node scripts/setAdminClaim.js <uid>
   ```

   El usuario debe cerrar sesión y volver a entrar para que su token incluya el rol.

## 4. Servicio de IA (`ai-service/`)

```bash
cd ai-service
python -m venv venv
venv/Scripts/activate            # Windows (en Linux/macOS: source venv/bin/activate)
pip install -r requirements.txt
export INTERNAL_API_KEY=<mismo valor que en backend/.env>
export GOOGLE_APPLICATION_CREDENTIALS=serviceAccountKey.json
export BACKEND_URL=http://localhost:3000
uvicorn app.main:app --port 8001
```

El servicio no lee archivos `.env`: las variables deben exportarse en la terminal antes de iniciarlo. Si `INTERNAL_API_KEY` no coincide con la del backend, las llamadas entre ambos fallan con 401 y los reportes se crean sin generar coincidencias.

El umbral de similitud se define en `app/config.py` (`SIMILARITY_THRESHOLD = 0.145`) y los pesos del modelo en `app/models/mnv3_helpet.pt`.

## 5. Aplicación móvil (`mobile/`)

1. Agregar la clave de Google Maps en `mobile/android/local.properties`:

   ```properties
   googleMapsApiKey=<clave>
   ```

2. Compilar indicando la URL del backend:

   ```bash
   cd mobile
   flutter pub get
   flutter build apk --release --dart-define=API_BASE_URL=<URL del backend>
   ```

   Sin `API_BASE_URL`, la aplicación apunta a `10.0.2.2`, dirección que solo existe en el emulador de Android.

3. Para probar en un dispositivo físico contra un backend local: `adb reverse tcp:3000 tcp:3000` y compilar con `API_BASE_URL=http://localhost:3000`, o usar la IP de la red local del computador.

## 6. Despliegue

- El backend y el servicio de IA se despliegan como contenedores en **Google Cloud Run** (región `us-central1`, proyecto `helpet-app-503fd`).
- `INTERNAL_API_KEY` se guarda en **Secret Manager** (secreto `internal-api-key`); las credenciales de Firebase se obtienen de la cuenta de servicio del entorno de Cloud Run.
- El APK de prueba se distribuye con **Firebase App Distribution**.
- Las reglas de seguridad están en `firestore.rules` y `storage.rules` (se despliegan con `firebase deploy --only firestore:rules,storage`).

## 7. Pruebas y calidad

| Componente | Comando | Qué cubre |
|---|---|---|
| Backend | `npm test` | Pruebas unitarias |
| Backend | `npm run test:integration:ci` | Integración contra los emuladores de Firestore y Authentication |
| Backend | `npm run lint` | Análisis estático (ESLint) |
| Servicio de IA | `pytest` | Pruebas unitarias (requiere `requirements-dev.txt`) |
| Servicio de IA | `ruff check .` | Análisis estático |
| Aplicación móvil | `flutter test` | Pruebas de widgets y del cliente HTTP |
| Aplicación móvil | `flutter analyze` | Análisis estático |

Todas se ejecutan automáticamente en GitHub Actions en cada cambio a `master` (`.github/workflows/ci.yml`).

## 8. Evaluación del modelo

El modelo de reconocimiento (MobileNetV3-Large ajustado con ArcFace) se entrenó y evaluó con el conjunto público PetFinder.my Adoption Prediction, disponible en Kaggle. Los pesos resultantes se incluyen en `ai-service/app/models/mnv3_helpet.pt`, y el servicio los carga al iniciar; no es necesario volver a entrenar el modelo para ejecutar la aplicación.
