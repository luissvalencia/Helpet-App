import io

import pytest
from PIL import Image

from app.services.embeddings_service import (
    MAX_IMAGE_BYTES,
    DatosInvalidos,
    ReporteNoEncontrado,
    _download_image,
    generate_embedding_for_reporte,
)


def _imagen_valida_bytes():
    buf = io.BytesIO()
    Image.new("RGB", (8, 8), color="red").save(buf, format="JPEG")
    return buf.getvalue()


class _FakeResponse:
    def __init__(self, content: bytes, content_length: str | None = None):
        self._content = content
        self.headers = {"Content-Length": content_length} if content_length else {}

    def raise_for_status(self):
        pass

    def iter_content(self, chunk_size):
        for i in range(0, len(self._content), chunk_size):
            yield self._content[i : i + chunk_size]

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False


def test_download_image_acepta_una_imagen_valida(monkeypatch):
    contenido = _imagen_valida_bytes()
    monkeypatch.setattr(
        "app.services.embeddings_service.requests.get",
        lambda *a, **k: _FakeResponse(contenido),
    )
    imagen = _download_image("https://ejemplo.com/foto.jpg")
    assert imagen.size == (8, 8)


def test_download_image_rechaza_content_length_excesivo(monkeypatch):
    monkeypatch.setattr(
        "app.services.embeddings_service.requests.get",
        lambda *a, **k: _FakeResponse(b"x", content_length=str(MAX_IMAGE_BYTES + 1)),
    )
    with pytest.raises(DatosInvalidos):
        _download_image("https://ejemplo.com/foto-gigante.jpg")


def test_download_image_rechaza_contenido_que_excede_el_limite_sin_content_length(monkeypatch):
    contenido_gigante = b"x" * (MAX_IMAGE_BYTES + 1)
    monkeypatch.setattr(
        "app.services.embeddings_service.requests.get",
        lambda *a, **k: _FakeResponse(contenido_gigante),
    )
    with pytest.raises(DatosInvalidos):
        _download_image("https://ejemplo.com/foto-gigante.jpg")


def test_download_image_rechaza_contenido_que_no_es_imagen(monkeypatch):
    monkeypatch.setattr(
        "app.services.embeddings_service.requests.get",
        lambda *a, **k: _FakeResponse(b"esto no es una imagen"),
    )
    with pytest.raises(DatosInvalidos):
        _download_image("https://ejemplo.com/no-es-foto.jpg")


class _FakeDoc:
    def __init__(self, data, exists=True):
        self._data = data
        self.exists = exists

    def to_dict(self):
        return self._data


class _FakeDocRef:
    def __init__(self, doc):
        self._doc = doc
        self.updated_with = None
        self.id = "embedding-nuevo"

    def get(self):
        return self._doc

    def update(self, data):
        self.updated_with = data

    def set(self, data):
        self.set_with = data


class _FakeCollection:
    def __init__(self, doc):
        self._doc = doc

    def document(self, _id=None):
        return _FakeDocRef(self._doc)


class _FakeDb:
    def __init__(self, reporte_doc):
        self._reporte_doc = reporte_doc

    def collection(self, name):
        if name == "reportes":
            return _FakeCollection(self._reporte_doc)
        return _FakeCollection(_FakeDoc({}, exists=False))


def test_generate_embedding_lanza_reporte_no_encontrado_si_no_existe(monkeypatch):
    fake_db = _FakeDb(_FakeDoc({}, exists=False))
    monkeypatch.setattr("app.services.embeddings_service.db", fake_db)

    with pytest.raises(ReporteNoEncontrado):
        generate_embedding_for_reporte("reporte-x", "https://ejemplo.com/foto.jpg")


def test_generate_embedding_lanza_datos_invalidos_si_falta_tipo_o_especie(monkeypatch):
    reporte_incompleto = _FakeDoc({"mascota": {}})  # sin 'tipo', sin 'especie'
    fake_db = _FakeDb(reporte_incompleto)
    monkeypatch.setattr("app.services.embeddings_service.db", fake_db)

    with pytest.raises(DatosInvalidos):
        generate_embedding_for_reporte("reporte-x", "https://ejemplo.com/foto.jpg")
