const { firestore, admin } = require("../config/firebase");
const { haversineDistanceKm } = require("./geo.service");
const { dispararGeneracionEmbedding } = require("./aiService.service");
const { notificarReportesCercanos } = require("./notificaciones.service");
const logger = require("../utils/logger");

const reportesCollection = firestore.collection("reportes");

async function createReporte(data, uid) {
  const now = admin.firestore.FieldValue.serverTimestamp();
  const reporte = {
    tipo: data.tipo,
    creadoPor: uid,
    mascota: data.mascota,
    fotoUrl: data.fotoUrl,
    ubicacion: data.ubicacion,
    estado: "activo",
    creadoEn: now,
    actualizadoEn: now,
    embeddingId: null,
    // Referencia opcional a mascotas/{id} si el reporte se creó eligiendo
    // una mascota guardada del perfil — los datos de `mascota` de arriba
    // ya son una copia (snapshot) al momento de reportar, no cambian si
    // luego se edita el perfil de la mascota.
    mascotaId: data.mascotaId || null,
  };
  const docRef = await reportesCollection.add(reporte);
  const doc = await docRef.get();

  // US-12: no bloquea la respuesta al cliente; el embedding llega async.
  dispararGeneracionEmbedding(docRef.id, reporte.fotoUrl);

  const reporteCreado = { id: doc.id, ...doc.data() };

  // US-20: no bloquea la respuesta al cliente; las notificaciones se envían async.
  notificarReportesCercanos(reporteCreado).catch((err) => {
    logger.error(`notificaciones: no se pudo notificar reportes cercanos a ${reporteCreado.id}: ${err.message}`);
  });

  return reporteCreado;
}

async function getReporteById(id) {
  const doc = await reportesCollection.doc(id).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
}

async function listReportesCercanos(lat, lng, radioKm) {
  const snapshot = await reportesCollection.where("estado", "==", "activo").get();

  const origen = { lat, lng };

  return snapshot.docs
    .map((doc) => {
      const reporte = { id: doc.id, ...doc.data() };
      const distanciaKm = haversineDistanceKm(origen, {
        lat: reporte.ubicacion.lat,
        lng: reporte.ubicacion.lng,
      });
      return { ...reporte, distanciaKm };
    })
    .filter((reporte) => reporte.distanciaKm <= radioKm)
    .sort((a, b) => (b.creadoEn?.toMillis?.() ?? 0) - (a.creadoEn?.toMillis?.() ?? 0));
}

async function listReportesPropios(uid, tipo) {
  let query = reportesCollection.where("creadoPor", "==", uid);
  if (tipo) query = query.where("tipo", "==", tipo);
  const snapshot = await query.get();

  return snapshot.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .sort((a, b) => (b.creadoEn?.toMillis?.() ?? 0) - (a.creadoEn?.toMillis?.() ?? 0));
}

async function updateReporte(id, uid, data) {
  const reporte = await getReporteById(id);
  if (!reporte) return { error: "not_found" };
  if (reporte.creadoPor !== uid) return { error: "forbidden" };

  const allowedFields = ["mascota", "fotoUrl", "ubicacion"];
  const updateData = { actualizadoEn: admin.firestore.FieldValue.serverTimestamp() };
  for (const field of allowedFields) {
    if (data[field] !== undefined) updateData[field] = data[field];
  }

  await reportesCollection.doc(id).update(updateData);
  return { reporte: await getReporteById(id) };
}

async function cerrarReporte(id, uid) {
  const reporte = await getReporteById(id);
  if (!reporte) return { error: "not_found" };
  if (reporte.creadoPor !== uid) return { error: "forbidden" };

  await reportesCollection.doc(id).update({
    estado: "cerrado",
    actualizadoEn: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { reporte: await getReporteById(id) };
}

async function deleteReporte(id) {
  await reportesCollection.doc(id).delete();
}

async function eliminarReportePropio(id, uid) {
  const reporte = await getReporteById(id);
  if (!reporte) return { error: "not_found" };
  if (reporte.creadoPor !== uid) return { error: "forbidden" };
  // Solo se puede borrar un reporte ya cerrado — evita borrar por error uno
  // todavía activo (con eso, "cerrar" ya cumple el rol de "archivar").
  if (reporte.estado !== "cerrado") return { error: "no_cerrado" };

  await deleteReporte(id);
  return { ok: true };
}

module.exports = {
  createReporte,
  getReporteById,
  listReportesCercanos,
  listReportesPropios,
  updateReporte,
  cerrarReporte,
  deleteReporte,
  eliminarReportePropio,
};
