import numpy as np
import pytest
from PIL import Image

from app.models.fur_color import FurColorEstimator, _rgb_a_luminosidad


def test_luminosidad_de_negro_y_blanco():
    assert _rgb_a_luminosidad(np.array([[0.0, 0.0, 0.0]]))[0] == pytest.approx(0.0, abs=1e-6)
    assert _rgb_a_luminosidad(np.array([[1.0, 1.0, 1.0]]))[0] == pytest.approx(100.0, abs=1e-3)


def test_sin_gato_en_la_foto_devuelve_none(monkeypatch):
    import torch

    class _SegmentadorSinGato:
        def __call__(self, x):
            return {"out": torch.zeros(1, 21, x.shape[2], x.shape[3])}  # todo "fondo"

    estimador = FurColorEstimator()
    monkeypatch.setattr(estimador, "_cargar", lambda: _SegmentadorSinGato())
    assert estimador.luminosidad_gato(Image.new("RGB", (64, 64), "white")) is None


def test_mide_solo_los_pixeles_del_gato(monkeypatch):
    import torch

    class _SegmentadorMitadIzquierda:
        def __call__(self, x):
            out = torch.zeros(1, 21, x.shape[2], x.shape[3])
            out[0, 8, :, : x.shape[3] // 2] = 1.0  # gato a la izquierda
            return {"out": out}

    img = Image.new("RGB", (100, 100), "white")
    img.paste((0, 0, 0), (0, 0, 50, 100))  # mitad izquierda negra
    estimador = FurColorEstimator()
    monkeypatch.setattr(estimador, "_cargar", lambda: _SegmentadorMitadIzquierda())
    assert estimador.luminosidad_gato(img) < 5
