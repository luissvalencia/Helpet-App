from pathlib import Path

import torch
from PIL import Image
from torchvision.models.segmentation import (
    LRASPP_MobileNet_V3_Large_Weights,
    lraspp_mobilenet_v3_large,
)

WEIGHTS_PATH = Path(__file__).with_name("lraspp_voc.pt")

# Etiquetas VOC del segmentador.
VOC_GATO = 8
VOC_PERRO = 12
# Lado mayor al que se reduce la foto antes de segmentar.
LADO_MAX = 400


class VocSegmenter:
    """Segmentador semántico LR-ASPP MobileNetV3-Large (etiquetas VOC: fondo,
    persona, perro, gato, caballo, ...). Lo comparten la validación de fotos
    (¿hay un perro o un gato?, ver pet_detector.py) y la medición del pelaje
    de gatos (fur_color.py), para cargar los pesos una sola vez.

    El modelo se carga en el primer uso."""

    def __init__(self):
        self._model = None
        self.preprocess = LRASPP_MobileNet_V3_Large_Weights.COCO_WITH_VOC_LABELS_V1.transforms()

    def modelo(self):
        if self._model is None:
            model = lraspp_mobilenet_v3_large(weights=None, weights_backbone=None)
            model.load_state_dict(torch.load(WEIGHTS_PATH, map_location="cpu"))
            self._model = model.eval()
        return self._model

    @staticmethod
    def reducir(image: Image.Image) -> Image.Image:
        img = image.convert("RGB")
        img.thumbnail((LADO_MAX, LADO_MAX))
        return img

    @torch.no_grad()
    def clases_por_pixel(self, modelo, img: Image.Image) -> torch.Tensor:
        """Clase VOC más probable de cada píxel de `img` (ya reducida)."""
        logits = modelo(self.preprocess(img).unsqueeze(0))["out"]
        logits = torch.nn.functional.interpolate(logits, size=img.size[::-1], mode="bilinear")
        return logits[0].argmax(0)


segmenter = VocSegmenter()
