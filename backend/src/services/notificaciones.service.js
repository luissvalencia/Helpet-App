const { firestore, admin } = require("../config/firebase");
const { haversineDistanceKm } = require("./geo.service");

const usersCollection = firestore.collection("users");
const reportesCollection = firestore.collection("reportes");
const coincidenciasCollection = firestore.collection("coincidencias");
const notificacionesCollection = firestore.collection("notificacionesUsuario");

const RADIO_CERCANIA_KM = 10;

async function limpiarTokenInvalido(uid, errorCode) {
  if (errorCode === "messaging/registration-token-not-registered" || errorCode === "messaging/invalid-argument") {
    await usersCollection.doc(uid).update({ fcmToken: null });
  }
}

// Centro de notificaciones in-app: se guarda siempre que se decide avisar a
// un usuario (aunque el push falle o no tenga fcmToken), para que la
// información no dependa únicamente del snackbar/notificación del momento.
async function registrarNotificacion(uid, { title, body, data }) {
  await notificacionesCollection.add({
    uid,
    titulo: title,
    cuerpo: body,
    tipo: data?.tipo ?? null,
    data: data ?? {},
    leida: false,
    creadoEn: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function listarNotificaciones(uid, { limite = 50 } = {}) {
  const snapshot = await notificacionesCollection.where("uid", "==", uid).get();
  return snapshot.docs
    .map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        titulo: data.titulo,
        cuerpo: data.cuerpo,
        tipo: data.tipo,
        data: data.data || {},
        leida: data.leida,
        creadoEn: data.creadoEn?.toDate?.().toISOString() ?? null,
        _ordenMillis: data.creadoEn?.toMillis?.() ?? 0,
      };
    })
    .sort((a, b) => b._ordenMillis - a._ordenMillis)
    .slice(0, limite)
    .map(({ _ordenMillis, ...resto }) => resto);
}

async function marcarNotificacionLeida(id, uid) {
  const doc = await notificacionesCollection.doc(id).get();
  if (!doc.exists) return { error: "not_found" };
  if (doc.data().uid !== uid) return { error: "forbidden" };

  await notificacionesCollection.doc(id).update({ leida: true });
  return { ok: true };
}

async function marcarTodasLeidas(uid) {
  const snapshot = await notificacionesCollection.where("uid", "==", uid).get();
  const pendientes = snapshot.docs.filter((doc) => doc.data().leida === false);
  if (pendientes.length === 0) return { ok: true, actualizadas: 0 };

  const batch = firestore.batch();
  pendientes.forEach((doc) => batch.update(doc.ref, { leida: true }));
  await batch.commit();
  return { ok: true, actualizadas: pendientes.length };
}

async function eliminarNotificacion(id, uid) {
  const doc = await notificacionesCollection.doc(id).get();
  if (!doc.exists) return { error: "not_found" };
  if (doc.data().uid !== uid) return { error: "forbidden" };

  await notificacionesCollection.doc(id).delete();
  return { ok: true };
}

async function eliminarTodasNotificaciones(uid) {
  const snapshot = await notificacionesCollection.where("uid", "==", uid).get();
  // Un batch de Firestore admite como máximo 500 operaciones.
  for (let i = 0; i < snapshot.docs.length; i += 500) {
    const batch = firestore.batch();
    snapshot.docs.slice(i, i + 500).forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
  return { ok: true, eliminadas: snapshot.docs.length };
}

async function enviarNotificacionCoincidencia(coincidenciaId) {
  const coincidenciaDoc = await coincidenciasCollection.doc(coincidenciaId).get();
  if (!coincidenciaDoc.exists) return { enviado: false, motivo: "coincidencia_no_encontrada" };

  const coincidencia = coincidenciaDoc.data();
  const [reporteADoc, reporteBDoc] = await Promise.all([
    reportesCollection.doc(coincidencia.reporteIdA).get(),
    reportesCollection.doc(coincidencia.reporteIdB).get(),
  ]);

  const reporteA = reporteADoc.exists ? { id: reporteADoc.id, ...reporteADoc.data() } : null;
  const reporteB = reporteBDoc.exists ? { id: reporteBDoc.id, ...reporteBDoc.data() } : null;
  const reportePerdida = [reporteA, reporteB].find((r) => r?.tipo === "perdida");

  if (!reportePerdida) return { enviado: false, motivo: "reporte_perdida_no_encontrado" };

  const userDoc = await usersCollection.doc(reportePerdida.creadoPor).get();
  if (!userDoc.exists) return { enviado: false, motivo: "usuario_no_encontrado" };

  const user = userDoc.data();
  if (user.notifCoincidencias === false) return { enviado: false, motivo: "preferencia_desactivada" };

  const notifTitle = "¡Posible coincidencia encontrada!";
  const notifBody = `Encontramos un avistamiento que podría ser ${reportePerdida.mascota.nombre}. Toca para ver los detalles.`;
  const notifData = {
    tipo: "coincidencia",
    reporteId: reportePerdida.id,
    coincidenciaId,
  };
  await registrarNotificacion(reportePerdida.creadoPor, { title: notifTitle, body: notifBody, data: notifData });

  if (!user.fcmToken) return { enviado: false, motivo: "sin_fcm_token" };

  const message = {
    token: user.fcmToken,
    notification: { title: notifTitle, body: notifBody },
    data: notifData,
    android: { priority: "high" },
  };

  try {
    await admin.messaging().send(message);
    return { enviado: true };
  } catch (err) {
    await limpiarTokenInvalido(reportePerdida.creadoPor, err.code);
    return { enviado: false, motivo: err.code || "error_envio" };
  }
}

async function enviarPushAUsuario(uid, { title, body, data }) {
  const userDoc = await usersCollection.doc(uid).get();
  if (!userDoc.exists) return { enviado: false, motivo: "usuario_no_encontrado" };

  const user = userDoc.data();
  if (user.notifCoincidencias === false) return { enviado: false, motivo: "preferencia_desactivada" };

  await registrarNotificacion(uid, { title, body, data });

  if (!user.fcmToken) return { enviado: false, motivo: "sin_fcm_token" };

  try {
    await admin.messaging().send({
      token: user.fcmToken,
      notification: { title, body },
      data,
      android: { priority: "high" },
    });
    return { enviado: true };
  } catch (err) {
    await limpiarTokenInvalido(uid, err.code);
    return { enviado: false, motivo: err.code || "error_envio" };
  }
}

async function notificarReportesCercanos(reporte) {
  const tipoContrario = reporte.tipo === "perdida" ? "encontrada" : "perdida";

  const snapshot = await reportesCollection
    .where("estado", "==", "activo")
    .where("tipo", "==", tipoContrario)
    .get();

  const candidatos = snapshot.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .filter((candidato) => candidato.creadoPor !== reporte.creadoPor)
    .filter(
      (candidato) =>
        haversineDistanceKm(reporte.ubicacion, {
          lat: candidato.ubicacion.lat,
          lng: candidato.ubicacion.lng,
        }) <= RADIO_CERCANIA_KM
    );

  if (candidatos.length === 0) return { enviados: 0 };

  const uidsDestino = [...new Set(candidatos.map((candidato) => candidato.creadoPor))];
  const userDocs = await Promise.all(uidsDestino.map((uid) => usersCollection.doc(uid).get()));

  const uidsDeseanAviso = [];
  const tokenPorUid = new Map();
  userDocs.forEach((doc) => {
    if (!doc.exists) return;
    const user = doc.data();
    if (user.notifReportesCercanos === false) return;
    uidsDeseanAviso.push(doc.id);
    if (user.fcmToken) tokenPorUid.set(doc.id, user.fcmToken);
  });

  if (uidsDeseanAviso.length === 0) return { enviados: 0 };

  const titulo =
    reporte.tipo === "encontrada" ? "Nuevo avistamiento cerca de ti" : "Reportan mascota perdida cerca de ti";
  const cuerpo = `${reporte.mascota.nombre} — ${reporte.ubicacion.direccionTexto}`;
  const notifData = { tipo: "nuevo_reporte", reporteId: reporte.id };

  await Promise.all(
    uidsDeseanAviso.map((uid) => registrarNotificacion(uid, { title: titulo, body: cuerpo, data: notifData }))
  );

  if (tokenPorUid.size === 0) return { enviados: 0 };

  const tokens = [...tokenPorUid.values()];
  const uids = [...tokenPorUid.keys()];

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title: titulo, body: cuerpo },
    data: notifData,
    android: { priority: "high" },
  });

  await Promise.all(
    response.responses.map((res, i) => (res.success ? null : limpiarTokenInvalido(uids[i], res.error?.code)))
  );

  return { enviados: response.successCount };
}

module.exports = {
  enviarNotificacionCoincidencia,
  notificarReportesCercanos,
  enviarPushAUsuario,
  listarNotificaciones,
  marcarNotificacionLeida,
  marcarTodasLeidas,
  eliminarNotificacion,
  eliminarTodasNotificaciones,
};
