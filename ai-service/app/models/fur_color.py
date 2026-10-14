from pathlib import Path

import numpy as np
import torch
from PIL import Image
from torchvision.models.segmentation import (
    LRASPP_MobileNet_V3_Large_Weights,
    lraspp_mobilenet_v3_large,
)

WEIGHTS_PATH = Path(__file__).with_name("lraspp_voc.pt")

# Clase "cat" en las etiquetas VOC del segmentador.
VOC_GATO = 8
# Lado mayor al que se reduce la foto antes de segmentar.
LADO_MAX = 400
# Si el gato ocupa menos píxeles que esto, la medición no es confiable.
MIN_PIXELES = 200


def _rgb_a_luminosidad(rgb: np.ndarray) -> np.ndarray:
    """L* de CIELAB (0 = negro, 100 = blanco) a partir de RGB en [0, 1]."""
    lineal = np.where(rgb > 0.04045, ((rgb + 0.055) / 1.055) ** 2.4, rgb / 12.92)
    y = lineal @ np.array([0.2126, 0.7152, 0.0722])
    f = np.where(y > 0.008856, np.cbrt(y), 7.787 * y + 16 / 116)
    return 116 * f - 16


class FurColorEstimator:
    """Mide qué tan claro u oscuro es el pelaje de un gato: segmenta la foto
    (LR-ASPP MobileNetV3-Large, etiquetas VOC) y toma la mediana de L* solo
    sobre los píxeles del gato, sin el fondo. Se usa en el matching de gatos
    para no avisar coincidencias entre un gato negro y uno claro (ver
    MAX_DIFERENCIA_LUMINOSIDAD_GATOS en config.py).

    El modelo se carga en el primer uso: los reportes de perros nunca lo
    necesitan."""

    def __init__(self):
        self._model = None
        self._preprocess = LRASPP_MobileNet_V3_Large_Weights.COCO_WITH_VOC_LABELS_V1.transforms()

    def _cargar(self):
        if self._model is None:
            model = lraspp_mobilenet_v3_large(weights=None, weights_backbone=None)
            model.load_state_dict(torch.load(WEIGHTS_PATH, map_location="cpu"))
            self._model = model.eval()
        return self._model

    @torch.no_grad()
    def luminosidad_gato(self, image: Image.Image) -> float | None:
        """Mediana de L* del pelaje, o None si no se detecta un gato."""
        img = image.convert("RGB")
        img.thumbnail((LADO_MAX, LADO_MAX))
        logits = self._cargar()(self._preprocess(img).unsqueeze(0))["out"]
        logits = torch.nn.functional.interpolate(logits, size=img.size[::-1], mode="bilinear")
        mascara = (logits[0].argmax(0) == VOC_GATO).numpy()
        if mascara.sum() < MIN_PIXELES:
            return None
        rgb = np.asarray(img, dtype=np.float64) / 255.0
        return float(np.median(_rgb_a_luminosidad(rgb[mascara])))


fur_color = FurColorEstimator()
