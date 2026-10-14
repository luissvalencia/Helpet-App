const { firestore } = require("../config/firebase");

// US-23: informativo, debe coincidir con SIMILARITY_THRESHOLD en ai-service/app/config.py.
const SIMILARITY_THRESHOLD = Number(process.env.SIMILARITY_THRESHOLD ?? 0.145);

// Objetivo específico 4 del anteproyecto: precisión del reconocimiento y tasa
// de falsos positivos. Solo cuentan las coincidencias que un usuario ya
// resolvió — "confirmada" (acierto) o "descartada" (falso positivo); las
// "pendiente" todavía no tienen veredicto y no entran en ninguna de las dos.
function calcularPrecision(coincidencias) {
  const confirmadas = coincidencias.filter((c) => c.estado === "confirmada").length;
  const descartadas = coincidencias.filter((c) => c.estado === "descartada").length;
  const resueltas = confirmadas + descartadas;
  return {
    coincidenciasResueltas: resueltas,
    precisionObservada: resueltas ? confirmadas / resueltas : null,
    tasaFalsosPositivos: resueltas ? descartadas / resueltas : null,
  };
}

// Objetivo específico 4: tiempo entre la detección de una coincidencia
// (`coincidencias.creadoEn`, lo escribe ai-service) y el envío de la
// notificación al dueño (`notificacionesUsuario.creadoEn`, se registra justo
// antes de mandar el push). La entrega final al celular la controla FCM/el
// sistema operativo y no es medible desde el servidor.
function calcularTiempoNotificacion(notificaciones, creadoEnPorCoincidencia) {
  const tiempos = notificaciones
    .map((n) => {
      const detectadaMs = creadoEnPorCoincidencia.get(n.data?.coincidenciaId);
      const enviadaMs = n.creadoEn?.toMillis?.();
      if (detectadaMs == null || enviadaMs == null) return null;
      return (enviadaMs - detectadaMs) / 1000;
    })
    .filter((segundos) => segundos != null && segundos >= 0);

  return {
    notificacionesMedidas: tiempos.length,
    tiempoPromedioNotificacionSeg: tiempos.length
      ? tiempos.reduce((a, b) => a + b, 0) / tiempos.length
      : null,
    tiempoMaximoNotificacionSeg: tiempos.length ? Math.max(...tiempos) : null,
  };
}

async function getMetricas() {
  const [
    embeddingsCount,
    coincidenciasSnap,
    notificacionesSnap,
    reportesActivosCount,
    reportesCerradosCount,
  ] = await Promise.all([
    firestore.collection("embeddings").count().get(),
    firestore.collection("coincidencias").get(),
    firestore.collection("notificacionesUsuario").where("tipo", "==", "coincidencia").get(),
    firestore.collection("reportes").where("estado", "==", "activo").count().get(),
    firestore.collection("reportes").where("estado", "==", "cerrado").count().get(),
  ]);

  const coincidencias = coincidenciasSnap.docs.map((doc) => doc.data());
  const similitudes = coincidencias
    .map((c) => c.similitud)
    .filter((similitud) => typeof similitud === "number");

  const creadoEnPorCoincidencia = new Map(
    coincidenciasSnap.docs.map((doc) => [doc.id, doc.data().creadoEn?.toMillis?.() ?? null]),
  );
  const notificaciones = notificacionesSnap.docs.map((doc) => doc.data());

  return {
    totalEmbeddings: embeddingsCount.data().count,
    totalCoincidencias: coincidencias.length,
    coincidenciasPendientes: coincidencias.filter((c) => c.estado === "pendiente").length,
    coincidenciasDescartadas: coincidencias.filter((c) => c.estado === "descartada").length,
    coincidenciasConfirmadas: coincidencias.filter((c) => c.estado === "confirmada").length,
    ...calcularPrecision(coincidencias),
    ...calcularTiempoNotificacion(notificaciones, creadoEnPorCoincidencia),
    similitudPromedio: similitudes.length
      ? similitudes.reduce((a, b) => a + b, 0) / similitudes.length
      : 0,
    similitudMinima: similitudes.length ? Math.min(...similitudes) : 0,
    similitudMaxima: similitudes.length ? Math.max(...similitudes) : 0,
    umbralActual: SIMILARITY_THRESHOLD,
    reportesActivos: reportesActivosCount.data().count,
    reportesCerrados: reportesCerradosCount.data().count,
  };
}

module.exports = { getMetricas, calcularPrecision, calcularTiempoNotificacion };
