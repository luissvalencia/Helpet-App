import requests
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, HttpUrl

from ..services.embeddings_service import DatosInvalidos
from ..services.validacion_service import validar_foto
from .embeddings import verify_internal_key

router = APIRouter()


class ValidarImagenRequest(BaseModel):
    fotoUrl: HttpUrl


@router.post("/imagenes/validar", dependencies=[Depends(verify_internal_key)])
def validar_imagen(payload: ValidarImagenRequest):
    try:
        return validar_foto(str(payload.fotoUrl))
    except DatosInvalidos as err:
        raise HTTPException(status_code=422, detail=str(err))
    except requests.exceptions.RequestException:
        raise HTTPException(status_code=502, detail="No se pudo descargar la foto")
