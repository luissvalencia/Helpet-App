"""Mide la luminosidad del pelaje (app/models/fur_color.py) de los reportes
de gatos activos cuyo embedding todavía no la tiene, y la guarda en
`embeddings.luminosidadPelaje`. Necesario una vez al activar el filtro de
pelaje: los embeddings creados antes no tienen ese campo y el filtro no se
aplica a ellos. No cambia vectores ni coincidencias ya guardadas.

Desde ai-service/, con GOOGLE_APPLICATION_CREDENTIALS exportada:
    python -m scripts.medir_pelaje_gatos            # solo muestra
    python -m scripts.medir_pelaje_gatos --ejecutar # escribe en Firestore
"""

import sys

from app.firebase_client import db
from app.models.fur_color import fur_color
from app.services.embeddings_service import _download_image


def main(ejecutar: bool) -> None:
    reportes = (
        db.collection("reportes")
        .where("estado", "==", "activo")
        .where("mascota.especie", "==", "Gato")
        .stream()
    )
    for reporte in reportes:
        data = reporte.to_dict()
        embedding_id = data.get("embeddingId")
        if not embedding_id:
            print(f"{reporte.id}: sin embedding, se omite")
            continue
        ref = db.collection("embeddings").document(embedding_id)
        if "luminosidadPelaje" in (ref.get().to_dict() or {}):
            print(f"{reporte.id}: ya medido")
            continue
        luminosidad = fur_color.luminosidad_gato(_download_image(data["fotoUrl"]))
        texto = "sin gato detectado" if luminosidad is None else f"{luminosidad:.1f}"
        print(f"{reporte.id} ({data.get('tipo')}, {data.get('mascota', {}).get('nombre')}): {texto}")
        if ejecutar:
            ref.update({"luminosidadPelaje": luminosidad})
    if not ejecutar:
        print("\nModo prueba: no se escribió nada. Usar --ejecutar para guardar.")


if __name__ == "__main__":
    main("--ejecutar" in sys.argv)
