from dataclasses import dataclass

from PIL import Image

from ..config import FACTOR_ESPECIE_DOMINANTE, MIN_PROPORCION_MASCOTA
from .segmenter import VOC_GATO, VOC_PERRO, segmenter


@dataclass
class DeteccionMascota:
    es_mascota: bool
    # "Perro" / "Gato" si una especie domina claramente; None si no hay
    # mascota o si la foto es ambigua (ahí no se le advierte nada al usuario).
    especie_detectada: str | None
    proporcion_perro: float
    proporcion_gato: float


class PetDetector:
    """¿La foto muestra un perro o un gato? Usa el mismo segmentador VOC que
    el filtro de pelaje: cuenta qué fracción de la imagen quedó etiquetada
    como perro o gato. Evita que se publiquen reportes con fotos de texto,
    paisajes, capturas de pantalla, etc., que generarían embeddings basura y
    coincidencias sin sentido."""

    def _cargar(self):
        return segmenter.modelo()

    def detectar(self, image: Image.Image) -> DeteccionMascota:
        img = segmenter.reducir(image)
        clases = segmenter.clases_por_pixel(self._cargar(), img)
        total = clases.numel()
        perro = float((clases == VOC_PERRO).sum()) / total
        gato = float((clases == VOC_GATO).sum()) / total

        es_mascota = perro + gato >= MIN_PROPORCION_MASCOTA
        especie = None
        if es_mascota:
            if perro >= FACTOR_ESPECIE_DOMINANTE * gato:
                especie = "Perro"
            elif gato >= FACTOR_ESPECIE_DOMINANTE * perro:
                especie = "Gato"
        return DeteccionMascota(es_mascota, especie, perro, gato)


pet_detector = PetDetector()
