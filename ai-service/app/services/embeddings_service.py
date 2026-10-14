import logging
from io import BytesIO

import requests
from firebase_admin import firestore as admin_firestore
from PIL import Image, UnidentifiedImageError

from ..firebase_client import db
from ..models.embedder import embedder
from ..models.fur_color import fur_color
from .matching_service import find_and_save_matches

logger = logging.getLogger(__name__)

# Límite defensivo contra descargas gigantes (decompression bomb / DoS) —
# ninguna foto de reporte legítima debería acercarse a esto.
MAX_IMAGE_BYTES = 10 * 1024 * 1024


class ReporteNoEncontrado(Exception):
    pass


class DatosInvalidos(Exception):
    """La foto no es una imagen válida, o el reporte no tiene los campos
    necesarios (tipo, mascota.especie) para generar/comparar el embedding."""

    pass


def _download_image(foto_url: str) -> Image.Image:
    with requests.get(foto_url, timeout=15, stream=True) as response:
        response.raise_for_status()

        content_length = response.headers.get("Content-Length")
        if content_length and int(content_length) > MAX_IMAGE_BYTES:
            raise DatosInvalidos(f"La imagen excede el límite de {MAX_IMAGE_BYTES} bytes")

        chunks = bytearray()
        for chunk in response.iter_content(chunk_size=64 * 1024):
            chunks.extend(chunk)
            if len(chunks) > MAX_IMAGE_BYTES:
                raise DatosInvalidos(f"La imagen excede el límite de {MAX_IMAGE_BYTES} bytes")

    try:
        return Image.open(BytesIO(bytes(chunks))).convert("RGB")
    except UnidentifiedImageError as err:
        raise DatosInvalidos("La URL no apunta a una imagen válida") from err


def generate_embedding_for_reporte(reporte_id: str, foto_url: str) -> dict:
    """US-12: descarga la foto, genera el embedding con MobileNetV3, lo
    guarda en `embeddings`, actualiza `reportes.embeddingId` y dispara la
    comparación (US-13) contra los reportes del tipo opuesto."""
    reporte_ref = db.collection("reportes").document(reporte_id)
    reporte_doc = reporte_ref.get()
    if not reporte_doc.exists:
        raise ReporteNoEncontrado(reporte_id)
    reporte_data = reporte_doc.to_dict()

    tipo = reporte_data.get("tipo")
    especie = reporte_data.get("mascota", {}).get("especie")
    if not tipo or not especie:
        logger.error("Reporte %s sin 'tipo'/'mascota.especie' — no se puede generar embedding", reporte_id)
        raise DatosInvalidos("El reporte no tiene 'tipo' o 'mascota.especie'")

    image = _download_image(foto_url)
    vector = embedder.embed(image)
    # Solo gatos (ver _pelaje_incompatible en matching_service). None si no
    # se detectó el gato en la foto: en ese caso el filtro no se aplica.
    luminosidad = fur_color.luminosidad_gato(image) if especie == "Gato" else None

    embedding_ref = db.collection("embeddings").document()
    embedding_ref.set(
        {
            "reporteId": reporte_id,
            "vector": vector,
            "luminosidadPelaje": luminosidad,
            "creadoEn": admin_firestore.SERVER_TIMESTAMP,
        }
    )
    reporte_ref.update({"embeddingId": embedding_ref.id})

    coincidencias = find_and_save_matches(
        reporte_id=reporte_id,
        tipo=tipo,
        especie=especie,
        vector=vector,
        creado_por=reporte_data.get("creadoPor"),
        luminosidad_pelaje=luminosidad,
    )

    return {"embeddingId": embedding_ref.id, "coincidencias": coincidencias}
