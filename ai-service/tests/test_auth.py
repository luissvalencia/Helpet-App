import pytest
from fastapi import HTTPException

from app.routers.embeddings import verify_internal_key


def test_rechaza_cuando_la_clave_no_coincide(monkeypatch):
    monkeypatch.setattr("app.routers.embeddings.INTERNAL_API_KEY", "clave-correcta")
    with pytest.raises(HTTPException) as exc_info:
        verify_internal_key(x_internal_api_key="clave-incorrecta")
    assert exc_info.value.status_code == 401


def test_rechaza_cuando_la_clave_esperada_esta_vacia(monkeypatch):
    monkeypatch.setattr("app.routers.embeddings.INTERNAL_API_KEY", "")
    with pytest.raises(HTTPException) as exc_info:
        verify_internal_key(x_internal_api_key="cualquier-cosa")
    assert exc_info.value.status_code == 401


def test_acepta_cuando_la_clave_coincide(monkeypatch):
    monkeypatch.setattr("app.routers.embeddings.INTERNAL_API_KEY", "clave-correcta")
    verify_internal_key(x_internal_api_key="clave-correcta")  # no debe lanzar
