from pathlib import Path

import torch
from PIL import Image
from torchvision.models import MobileNet_V3_Large_Weights, mobilenet_v3_large

WEIGHTS_PATH = Path(__file__).with_name("mnv3_helpet.pt")


class MobileNetEmbedder:
    """MobileNetV3-Large (transfer learning desde ImageNet) afinado para
    reidentificar mascotas individuales (fine-tuning con ArcFace). Solo el feature extractor (sin la capa de
    clasificación final). El embedding es la salida del avgpool, 960
    dimensiones, normalizada (L2) para similitud de coseno."""

    def __init__(self):
        self.model = mobilenet_v3_large()
        self.model.features.load_state_dict(torch.load(WEIGHTS_PATH, map_location="cpu"))
        self.model.eval()
        self.preprocess = MobileNet_V3_Large_Weights.IMAGENET1K_V2.transforms()

    @torch.no_grad()
    def embed(self, image: Image.Image) -> list[float]:
        tensor = self.preprocess(image).unsqueeze(0)
        features = self.model.features(tensor)
        pooled = self.model.avgpool(features)
        vector = torch.flatten(pooled, 1).squeeze(0)
        vector = vector / vector.norm(p=2)
        return vector.tolist()


embedder = MobileNetEmbedder()
