import secrets

import requests
from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, HttpUrl

from ..config import INTERNAL_API_KEY
from ..services.embeddings_service import (
    DatosInvalidos,
    ReporteNoEncontrado,
    generate_embedding_for_reporte,
)

router = APIRouter()


class GenerateEmbeddingRequest(BaseModel):
    reporteId: str
    fotoUrl: HttpUrl


def verify_internal_key(x_internal_api_key: str = Header(default="")):
    """Solo el backend (servidor-a-servidor) puede disparar la generación de
    un embedding — misma clave compartida que ya usa /notificaciones/coincidencia
    en la dirección inversa (ver INTERNAL_API_KEY en backend/.env). Se compara
    con secrets.compare_digest para no filtrar la clave por timing attack."""
    if not INTERNAL_API_KEY or not secrets.compare_digest(x_internal_api_key, INTERNAL_API_KEY):
        raise HTTPException(status_code=401, detail="No autorizado")


@router.post("/embeddings/generate", status_code=201, dependencies=[Depends(verify_internal_key)])
def generate_embedding(payload: GenerateEmbeddingRequest):
    try:
        return generate_embedding_for_reporte(payload.reporteId, str(payload.fotoUrl))
    except ReporteNoEncontrado:
        raise HTTPException(status_code=404, detail="Reporte no encontrado")
    except DatosInvalidos as err:
        raise HTTPException(status_code=422, detail=str(err))
    except requests.exceptions.RequestException:
        raise HTTPException(status_code=502, detail="No se pudo descargar la foto")
