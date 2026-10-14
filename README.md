1# Helpet

Plataforma para localizar mascotas extraviadas en Colombia mediante reconocimiento de imágenes con IA.

Proyecto de grado — Ingeniería de Sistemas, Unicomfacauca.

## Estructura del repo

```
helpet/
  mobile/        -> App Flutter (Dart)
  backend/       -> API REST (Node.js + Express)
  ai-service/    -> Servicio de reconocimiento de imágenes (Python + FastAPI)
```

## Estado

Backlog completo: autenticación y perfil (E1), reportes de mascotas (E2), reconocimiento de
imágenes con IA (E3), geolocalización y mapa (E4), notificaciones push (E5), validación y
calidad (E6), y seguimiento de coincidencias y contacto entre dueños (E7). Backend y servicio
de IA desplegados en Google Cloud Run.

## Desarrollo local

Ver [MANUAL_TECNICO.md](MANUAL_TECNICO.md) para instalar, configurar, probar y desplegar el
sistema completo, y `mobile/README.md`, `backend/README.md` y `ai-service/README.md` para
detalles de cada componente.
