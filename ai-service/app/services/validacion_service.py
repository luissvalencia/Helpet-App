from ..models.pet_detector import pet_detector
from .embeddings_service import _download_image


def validar_foto(foto_url: str) -> dict:
    """Descarga la foto y dice si muestra un perro o un gato (y cuál). La
    llama el backend antes de guardar un reporte o una mascota, para rechazar
    fotos que no son de un animal. Lanza DatosInvalidos si no es una imagen."""
    deteccion = pet_detector.detectar(_download_image(foto_url))
    return {
        "esMascota": deteccion.es_mascota,
        "especieDetectada": deteccion.especie_detectada,
        "proporcionPerro": round(deteccion.proporcion_perro, 4),
        "proporcionGato": round(deteccion.proporcion_gato, 4),
    }
