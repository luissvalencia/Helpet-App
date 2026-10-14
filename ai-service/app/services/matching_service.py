import logging

import numpy as np
import requests
from firebase_admin import firestore as admin_firestore

from ..config import (
    BACKEND_URL,
    INTERNAL_API_KEY,
    MAX_DIFERENCIA_LUMINOSIDAD_GATOS,
    SIMILARITY_THRESHOLD,
)
from ..firebase_client import db

logger = logging.getLogger(__name__)


def _notificar_coincidencia(coincidencia_id: str) -> None:
    """US-19: avisa al backend para que envíe el push. Best-effort: si falla,
    no debe interrumpir el flujo de matching (igual que el resto de este servicio)."""
    try:
        response = requests.post(
            f"{BACKEND_URL}/notificaciones/coincidencia",
            json={"coincidenciaId": coincidencia_id},
            headers={"X-Internal-Api-Key": INTERNAL_API_KEY},
            timeout=5,
        )
        if not response.ok:
            logger.error(
                "notificaciones: backend respondió %s para %s", response.status_code, coincidencia_id
            )
    except requests.RequestException as err:
        logger.error("notificaciones: no se pudo avisar al backend de %s: %s", coincidencia_id, err)


def _cosine_similarity(a: list[float], b: list[float]) -> float:
    va = np.array(a)
    vb = np.array(b)
    denom = np.linalg.norm(va) * np.linalg.norm(vb)
    if denom == 0:
        return 0.0
    return float(np.dot(va, vb) / denom)


def _pelaje_incompatible(especie: str, luminosidad_a, luminosidad_b) -> bool:
    """Solo gatos: True si uno es claramente más oscuro que el otro (ej. negro
    vs. crema). Sin medición en alguno de los dos, no se descarta nada."""
    if especie != "Gato" or luminosidad_a is None or luminosidad_b is None:
        return False
    return abs(luminosidad_a - luminosidad_b) > MAX_DIFERENCIA_LUMINOSIDAD_GATOS


def find_and_save_matches(
    reporte_id: str,
    tipo: str,
    especie: str,
    vector: list[float],
    creado_por: str,
    luminosidad_pelaje: float | None = None,
) -> list[dict]:
    """US-13: compara el embedding nuevo contra los reportes activos del tipo
    opuesto (y misma especie, auditoría post-Sprint-5: sin esto un gato podía
    "coincidir" con un perro si la similitud visual daba casualmente alta) y
    guarda en `coincidencias` los que superen el umbral (US-15).

    Excluye candidatos con el mismo `creadoPor`: dos reportes del mismo
    usuario (ej. "perdida" y "encontrada" con la misma foto, típico al
    probar la app en solitario) no son una coincidencia real entre dos
    personas, y el flujo de confirmación mutua se rompe si ambos lados son
    la misma cuenta — un solo tap en "confirmar" ya satisface "ambos
    confirmaron" y le revela el contacto a sí mismo.

    En gatos además descarta pares con pelaje de luminosidad muy distinta
    (`_pelaje_incompatible`)."""
    tipo_opuesto = "encontrada" if tipo == "perdida" else "perdida"

    candidatos = (
        db.collection("reportes")
        .where("estado", "==", "activo")
        .where("tipo", "==", tipo_opuesto)
        .where("mascota.especie", "==", especie)
        .stream()
    )

    guardadas = []
    for candidato in candidatos:
        data = candidato.to_dict()
        if data.get("creadoPor") == creado_por:
            continue
        embedding_id = data.get("embeddingId")
        if not embedding_id:
            continue

        embedding_doc = db.collection("embeddings").document(embedding_id).get()
        if not embedding_doc.exists:
            continue

        embedding_candidato = embedding_doc.to_dict()
        similitud = _cosine_similarity(vector, embedding_candidato.get("vector"))

        if similitud >= SIMILARITY_THRESHOLD and not _pelaje_incompatible(
            especie, luminosidad_pelaje, embedding_candidato.get("luminosidadPelaje")
        ):
            _, coincidencia_ref = db.collection("coincidencias").add(
                {
                    "reporteIdA": reporte_id,
                    "reporteIdB": candidato.id,
                    "similitud": similitud,
                    "estado": "pendiente",
                    "creadoEn": admin_firestore.SERVER_TIMESTAMP,
                }
            )
            _notificar_coincidencia(coincidencia_ref.id)
            guardadas.append({"reporteId": candidato.id, "similitud": similitud})

    return guardadas
