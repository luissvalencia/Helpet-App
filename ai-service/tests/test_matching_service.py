import pytest

from app.services.matching_service import _cosine_similarity, find_and_save_matches


class TestCosineSimilarity:
    def test_vectores_identicos_da_similitud_1(self):
        v = [1.0, 2.0, 3.0]
        assert _cosine_similarity(v, v) == pytest.approx(1.0)

    def test_vectores_ortogonales_da_similitud_0(self):
        assert _cosine_similarity([1.0, 0.0], [0.0, 1.0]) == pytest.approx(0.0)

    def test_vectores_opuestos_da_similitud_negativa(self):
        assert _cosine_similarity([1.0, 0.0], [-1.0, 0.0]) == pytest.approx(-1.0)

    def test_vector_con_norma_cero_no_falla_y_da_0(self):
        assert _cosine_similarity([0.0, 0.0], [1.0, 1.0]) == 0.0


class _FakeDoc:
    def __init__(self, id_, data, exists=True):
        self.id = id_
        self._data = data
        self.exists = exists

    def to_dict(self):
        return self._data


class _FakeQuery:
    def __init__(self, docs):
        self._docs = docs

    def where(self, *_args, **_kwargs):
        return self

    def stream(self):
        return iter(self._docs)


class _FakeCollection:
    def __init__(self, query_docs=None, docs_by_id=None):
        self._query_docs = query_docs or []
        self._docs_by_id = docs_by_id or {}
        self.added = []

    def where(self, *_args, **_kwargs):
        return _FakeQuery(self._query_docs)

    def document(self, doc_id=None):
        return _FakeDocRef(self, doc_id)

    def add(self, data):
        ref = _FakeDocRef(self, f"nueva-{len(self.added)}")
        self.added.append(data)
        return (None, ref)


class _FakeDocRef:
    def __init__(self, collection, doc_id):
        self.collection = collection
        self.id = doc_id

    def get(self):
        return self.collection._docs_by_id.get(self.id, _FakeDoc(self.id, {}, exists=False))


class _FakeDb:
    def __init__(self, reportes_candidatos, embeddings_por_id, coincidencias):
        self._collections = {
            "reportes": _FakeCollection(query_docs=reportes_candidatos),
            "embeddings": _FakeCollection(docs_by_id=embeddings_por_id),
            "coincidencias": coincidencias,
        }

    def collection(self, name):
        return self._collections[name]


def test_find_and_save_matches_guarda_coincidencia_sobre_el_umbral(monkeypatch):
    vector_nuevo = [1.0, 0.0]
    candidato = _FakeDoc("reporte-b", {"embeddingId": "emb-1"})
    embeddings = {"emb-1": _FakeDoc("emb-1", {"vector": [1.0, 0.0]})}
    coincidencias = _FakeCollection()

    fake_db = _FakeDb([candidato], embeddings, coincidencias)
    monkeypatch.setattr("app.services.matching_service.db", fake_db)
    monkeypatch.setattr("app.services.matching_service._notificar_coincidencia", lambda _id: None)

    resultado = find_and_save_matches(
        "reporte-a", "perdida", "Perro", vector_nuevo, creado_por="uid-dueno"
    )

    assert len(resultado) == 1
    assert resultado[0]["reporteId"] == "reporte-b"
    assert resultado[0]["similitud"] == pytest.approx(1.0)
    assert len(coincidencias.added) == 1


def test_find_and_save_matches_ignora_similitud_debajo_del_umbral(monkeypatch):
    candidato = _FakeDoc("reporte-b", {"embeddingId": "emb-1"})
    embeddings = {"emb-1": _FakeDoc("emb-1", {"vector": [0.0, 1.0]})}
    coincidencias = _FakeCollection()

    fake_db = _FakeDb([candidato], embeddings, coincidencias)
    monkeypatch.setattr("app.services.matching_service.db", fake_db)

    resultado = find_and_save_matches(
        "reporte-a", "perdida", "Perro", [1.0, 0.0], creado_por="uid-dueno"
    )

    assert resultado == []
    assert coincidencias.added == []


def test_find_and_save_matches_ignora_candidato_sin_embedding(monkeypatch):
    candidato = _FakeDoc("reporte-b", {})  # sin embeddingId
    fake_db = _FakeDb([candidato], {}, _FakeCollection())
    monkeypatch.setattr("app.services.matching_service.db", fake_db)

    resultado = find_and_save_matches(
        "reporte-a", "perdida", "Perro", [1.0, 0.0], creado_por="uid-dueno"
    )

    assert resultado == []


def test_find_and_save_matches_ignora_candidato_del_mismo_creador(monkeypatch):
    # Mismo usuario reportó "perdida" y "encontrada" con la misma foto (caso
    # típico al probar en solitario) — no debe generar una coincidencia,
    # aunque la similitud sea perfecta.
    vector_nuevo = [1.0, 0.0]
    candidato = _FakeDoc("reporte-b", {"embeddingId": "emb-1", "creadoPor": "uid-dueno"})
    embeddings = {"emb-1": _FakeDoc("emb-1", {"vector": [1.0, 0.0]})}
    coincidencias = _FakeCollection()

    fake_db = _FakeDb([candidato], embeddings, coincidencias)
    monkeypatch.setattr("app.services.matching_service.db", fake_db)

    resultado = find_and_save_matches(
        "reporte-a", "perdida", "Perro", vector_nuevo, creado_por="uid-dueno"
    )

    assert resultado == []
    assert coincidencias.added == []


def _matching_gatos(monkeypatch, especie, luminosidad_nuevo, luminosidad_candidato):
    candidato = _FakeDoc("reporte-b", {"embeddingId": "emb-1"})
    embeddings = {
        "emb-1": _FakeDoc("emb-1", {"vector": [1.0, 0.0], "luminosidadPelaje": luminosidad_candidato})
    }
    coincidencias = _FakeCollection()
    monkeypatch.setattr(
        "app.services.matching_service.db", _FakeDb([candidato], embeddings, coincidencias)
    )
    monkeypatch.setattr("app.services.matching_service._notificar_coincidencia", lambda _id: None)
    return find_and_save_matches(
        "reporte-a", "perdida", especie, [1.0, 0.0], creado_por="uid-dueno",
        luminosidad_pelaje=luminosidad_nuevo,
    )


def test_gato_negro_vs_claro_no_genera_coincidencia(monkeypatch):
    assert _matching_gatos(monkeypatch, "Gato", 10.0, 45.0) == []


def test_gatos_de_pelaje_parecido_si_generan_coincidencia(monkeypatch):
    assert len(_matching_gatos(monkeypatch, "Gato", 10.0, 25.0)) == 1


def test_sin_medicion_de_pelaje_no_se_aplica_el_filtro(monkeypatch):
    assert len(_matching_gatos(monkeypatch, "Gato", 10.0, None)) == 1
    assert len(_matching_gatos(monkeypatch, "Gato", None, 80.0)) == 1


def test_filtro_de_pelaje_no_aplica_a_perros(monkeypatch):
    assert len(_matching_gatos(monkeypatch, "Perro", 10.0, 80.0)) == 1
