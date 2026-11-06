import torch
from PIL import Image

from app.models.pet_detector import PetDetector
from app.models.segmenter import VOC_GATO, VOC_PERRO


def _segmentador(fracciones: dict[int, float]):
    """Segmentador falso: etiqueta franjas verticales de la imagen con las
    clases VOC indicadas (fracción del ancho); el resto queda como fondo."""

    class _Fake:
        def __call__(self, x):
            out = torch.zeros(1, 21, x.shape[2], x.shape[3])
            out[0, 0] = 0.5  # fondo por defecto
            inicio = 0
            for clase, fraccion in fracciones.items():
                fin = inicio + round(x.shape[3] * fraccion)
                out[0, clase, :, inicio:fin] = 1.0
                inicio = fin
            return {"out": out}

    return _Fake()


def _detectar(monkeypatch, fracciones):
    detector = PetDetector()
    monkeypatch.setattr(detector, "_cargar", lambda: _segmentador(fracciones))
    return detector.detectar(Image.new("RGB", (200, 200), "white"))


def test_foto_sin_perro_ni_gato_no_es_mascota(monkeypatch):
    d = _detectar(monkeypatch, {})
    assert not d.es_mascota
    assert d.especie_detectada is None


def test_perro_que_ocupa_buena_parte_de_la_foto(monkeypatch):
    d = _detectar(monkeypatch, {VOC_PERRO: 0.4})
    assert d.es_mascota
    assert d.especie_detectada == "Perro"


def test_gato(monkeypatch):
    d = _detectar(monkeypatch, {VOC_GATO: 0.3})
    assert d.es_mascota
    assert d.especie_detectada == "Gato"


def test_mezcla_ambigua_es_mascota_sin_especie(monkeypatch):
    d = _detectar(monkeypatch, {VOC_PERRO: 0.2, VOC_GATO: 0.15})
    assert d.es_mascota
    assert d.especie_detectada is None


def test_unos_pocos_pixeles_sueltos_no_alcanzan(monkeypatch):
    d = _detectar(monkeypatch, {VOC_PERRO: 0.005})
    assert not d.es_mascota
