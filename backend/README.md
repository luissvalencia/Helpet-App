# Helpet backend

API REST en Node.js + Express. Usa Firebase Admin SDK para verificar tokens de
Firebase Auth y leer/escribir en Firestore. No hay base de datos SQL: Firestore
es la única fuente de verdad.

## Configuración inicial

1. `npm install`
2. Descargar una clave de cuenta de servicio desde Firebase Console
   (`helpet-app-503fd` > Project settings > Service accounts > Generate new
   private key) y guardarla como `backend/serviceAccountKey.json` (ya está en
   `.gitignore`, nunca se sube al repo).
3. Copiar `.env.example` a `.env` y ajustar `GOOGLE_APPLICATION_CREDENTIALS`
   si el archivo tiene otro nombre o ruta.
4. `npm run dev` levanta el servidor con recarga automática en
   `http://localhost:3000`. `GET /health` debe responder `{"status":"ok"}`.

## Estructura

```
src/
  config/       -> inicialización de Firebase Admin
  middlewares/  -> verificación de ID token, chequeo de rol admin, manejo de errores
  routes/       -> definición de endpoints Express
  controllers/  -> parseo/validación de request y respuesta HTTP
  services/     -> lógica de negocio y acceso a Firestore
scripts/
  setAdminClaim.js -> asigna el rol admin (custom claim) a un usuario existente
```

## Asignar el primer usuario admin

No hay UI de gestión de roles en este sprint. Para dar rol admin a un usuario
que ya se registró desde la app:

```
node scripts/setAdminClaim.js <uid-del-usuario>
```

El usuario debe volver a iniciar sesión para que el ID token incluya el
custom claim `rol: admin`.

## Endpoints

Todas las rutas (excepto `/health`) requieren header `Authorization: Bearer <idToken>`.

- `GET /health`
- `GET /users/me`, `PATCH /users/me`
- `POST /reportes`, `GET /reportes?lat&lng&radioKm`, `GET /reportes/:id`,
  `PATCH /reportes/:id`, `POST /reportes/:id/cerrar`
- `GET /admin/users`, `PATCH /admin/users/:uid/disable`,
  `DELETE /admin/reportes/:id` (requieren rol admin)
