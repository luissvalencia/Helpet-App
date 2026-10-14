import logging

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from .routers import embeddings

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger(__name__)

app = FastAPI(title="Helpet AI Service")

app.include_router(embeddings.router)


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.exception("Error no manejado en %s %s", request.method, request.url.path)
    return JSONResponse(status_code=500, content={"detail": "Error interno del servidor"})


@app.get("/health")
def health():
    return {"status": "ok"}
