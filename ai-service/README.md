# Helpet AI service

FastAPI + MobileNetV3-Large (transfer learning, torchvision,
`IMAGENET1K_V2`) para generar embeddings visuales de las fotos de reportes
y detectar coincidencias por similitud de coseno (Sprint 2, E3).

## Credencial de Firebase

Este servicio usa su propia cuenta de servicio (Admin SDK) para leer/escribir
en Firestore — las colecciones `embeddings` y `coincidencias`, y el campo
`embeddingId` de `reportes`. No usa el SDK de cliente ni Storage (las fotos
se descargan por su URL pública con `requests`).

`firebase_client.py` usa `credentials.ApplicationDefault()` (Application
Default Credentials), igual que el backend. En Cloud Run la toma sola de la
cuenta de servicio adjunta al servicio, sin necesitar ningún archivo. En
local, exporta `GOOGLE_APPLICATION_CREDENTIALS` apuntando a un
`serviceAccountKey.json` descargado del mismo proyecto `helpet-app-503fd`
(puede ser una copia de `backend/serviceAccountKey.json`) antes de levantar
`uvicorn` — está en `.gitignore`, nunca se sube al repo.

## Ejecutar localmente

```
py -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
set GOOGLE_APPLICATION_CREDENTIALS=serviceAccountKey.json
set INTERNAL_API_KEY=<mismo valor que backend/.env>
uvicorn app.main:app --reload --port 8001
```

`GET /health` debe responder `{"status": "ok"}`.

## Endpoints

- `GET /health`
- `POST /embeddings/generate` — body `{ "reporteId": "...", "fotoUrl": "..." }`.
  Genera el embedding (960 dimensiones, normalizado), lo guarda en
  `embeddings`, actualiza `reportes/{id}.embeddingId` y guarda en
  `coincidencias` las que superen el umbral de similitud (`SIMILARITY_THRESHOLD`
  en `app/config.py`, 0.75 por defecto — US-15).
