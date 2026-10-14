const { firestore } = require("../config/firebase");
const usersService = require("./users.service");
const notificacionesService = require("./notificaciones.service");
const logger = require("../utils/logger");

const coincidenciasCollection = firestore.collection("coincidencias");
const reportesCollection = firestore.collection("reportes");

// Arma el objeto de coincidencia visto desde `reporteIdReferencia` (uno de
// los dos lados del match). `reporte` en la salida siempre es el OTRO lado.
async function construirCoincidencia(doc, reporteIdReferencia, uid) {
  const data = doc.data();
  // US-24: una vez descartada por el usuario, no debe reaparecer.
  if (data.estado === "descartada") return null;

  const otroReporteId = data.reporteIdA === reporteIdReferencia ? data.reporteIdB : data.reporteIdA;
  const [otroDoc, referenciaDoc] = await Promise.all([
    reportesCollection.doc(otroReporteId).get(),
    reportesCollection.doc(reporteIdReferencia).get(),
  ]);
  if (!otroDoc.exists) return null;
  const otro = otroDoc.data();
  // Si el otro lado de la coincidencia ya se cerró, ya no es una pista
  // accionable (el avistamiento/reporte dejó de estar disponible).
  if (otro.estado !== "activo") return null;

  const otroUsuario = await usersService.getUserByUid(otro.creadoPor);
  // El nombre por sí solo no es un dato de contacto (no permite localizar
  // ni contactar a nadie) — se muestra siempre para dar contexto de a quién
  // pertenece el otro reporte. Teléfono/correo siguen gateados por
  // "confirmada".
  const propietarioNombre = otroUsuario ? otroUsuario.nombre : null;
  const contacto =
    data.estado === "confirmada" && otroUsuario
      ? {
          uid: otro.creadoPor,
          nombre: otroUsuario.nombre,
          telefono: otroUsuario.telefono ?? null,
          email: otroUsuario.email,
        }
      : null;

  // El dueño (lado "perdida") siempre puede iniciar la confirmación. Quien
  // reportó el avistamiento solo debería verse invitado a confirmar/
  // contactar DESPUÉS de que el dueño ya haya dicho "sí es mi mascota" de
  // su lado — antes de eso, mostrarle el botón de contacto en todas sus
  // coincidencias es prematuro y confuso (feedback de pruebas de usuario).
  const referencia = referenciaDoc.exists ? referenciaDoc.data() : null;
  const duenoUid = referencia?.tipo === "perdida" ? referencia.creadoPor : otro.creadoPor;
  const duenoYaConfirmo = Boolean(duenoUid && (data.confirmadoPor || []).includes(duenoUid));

  return {
    id: doc.id,
    similitud: data.similitud,
    estado: data.estado,
    yoConfirme: Boolean(uid && (data.confirmadoPor || []).includes(uid)),
    duenoYaConfirmo,
    contacto,
    reporte: {
      id: otroDoc.id,
      tipo: otro.tipo,
      mascota: otro.mascota,
      fotoUrl: otro.fotoUrl,
      ubicacion: otro.ubicacion,
      propietarioNombre,
    },
  };
}

async function listarCoincidenciasDeReporte(reporteId, uid) {
  const [snapA, snapB] = await Promise.all([
    coincidenciasCollection.where("reporteIdA", "==", reporteId).get(),
    coincidenciasCollection.where("reporteIdB", "==", reporteId).get(),
  ]);

  const docs = [...snapA.docs, ...snapB.docs];

  const coincidencias = await Promise.all(
    docs.map((doc) => construirCoincidencia(doc, reporteId, uid))
  );

  return coincidencias
    .filter((coincidencia) => coincidencia !== null)
    .sort((a, b) => b.similitud - a.similitud);
}

function chunk(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

// Firestore permite hasta 30 valores por cláusula "in".
const FIRESTORE_IN_LIMIT = 30;

async function listarCoincidenciasDeUsuario(uid) {
  const misReportesSnap = await reportesCollection.where("creadoPor", "==", uid).get();
  if (misReportesSnap.empty) return [];

  const misReportes = new Map(
    misReportesSnap.docs.map((doc) => [doc.id, { ...doc.data(), id: doc.id }])
  );
  const misReporteIds = [...misReportes.keys()];

  const docsPorId = new Map();
  await Promise.all(
    chunk(misReporteIds, FIRESTORE_IN_LIMIT).map(async (grupo) => {
      const [snapA, snapB] = await Promise.all([
        coincidenciasCollection.where("reporteIdA", "in", grupo).get(),
        coincidenciasCollection.where("reporteIdB", "in", grupo).get(),
      ]);
      for (const doc of [...snapA.docs, ...snapB.docs]) {
        docsPorId.set(doc.id, doc);
      }
    })
  );

  const coincidencias = await Promise.all(
    [...docsPorId.values()].map(async (doc) => {
      const data = doc.data();
      const miReporteId = misReportes.has(data.reporteIdA) ? data.reporteIdA : data.reporteIdB;
      const coincidencia = await construirCoincidencia(doc, miReporteId, uid);
      if (!coincidencia) return null;
      const miReporte = misReportes.get(miReporteId);
      return {
        ...coincidencia,
        miReporte: {
          id: miReporte.id,
          tipo: miReporte.tipo,
          fotoUrl: miReporte.fotoUrl,
          mascota: { nombre: miReporte.mascota.nombre },
        },
      };
    })
  );

  return coincidencias
    .filter((coincidencia) => coincidencia !== null)
    .sort((a, b) => b.similitud - a.similitud);
}

async function descartarCoincidencia(id, uid) {
  const doc = await coincidenciasCollection.doc(id).get();
  if (!doc.exists) return { error: "not_found" };
  const data = doc.data();

  const [reporteADoc, reporteBDoc] = await Promise.all([
    reportesCollection.doc(data.reporteIdA).get(),
    reportesCollection.doc(data.reporteIdB).get(),
  ]);
  const esCreadorA = reporteADoc.exists && reporteADoc.data().creadoPor === uid;
  const esCreadorB = reporteBDoc.exists && reporteBDoc.data().creadoPor === uid;
  if (!esCreadorA && !esCreadorB) return { error: "forbidden" };

  await coincidenciasCollection.doc(id).update({ estado: "descartada" });
  return { ok: true };
}

async function confirmarCoincidencia(id, uid) {
  const doc = await coincidenciasCollection.doc(id).get();
  if (!doc.exists) return { error: "not_found" };
  const data = doc.data();
  if (data.estado === "descartada") return { error: "descartada" };

  const [reporteADoc, reporteBDoc] = await Promise.all([
    reportesCollection.doc(data.reporteIdA).get(),
    reportesCollection.doc(data.reporteIdB).get(),
  ]);
  const creadorA = reporteADoc.exists ? reporteADoc.data().creadoPor : null;
  const creadorB = reporteBDoc.exists ? reporteBDoc.data().creadoPor : null;
  if (uid !== creadorA && uid !== creadorB) return { error: "forbidden" };

  const confirmadoPor = Array.from(new Set([...(data.confirmadoPor || []), uid]));
  const ambosConfirmaron =
    Boolean(creadorA) &&
    Boolean(creadorB) &&
    confirmadoPor.includes(creadorA) &&
    confirmadoPor.includes(creadorB);
  const nuevoEstado = ambosConfirmaron ? "confirmada" : data.estado;

  await coincidenciasCollection.doc(id).update({ confirmadoPor, estado: nuevoEstado });

  const otroUid = uid === creadorA ? creadorB : creadorA;
  let contacto = null;

  if (ambosConfirmaron) {
    const otroUsuario = await usersService.getUserByUid(otroUid);
    contacto = otroUsuario
      ? {
          uid: otroUid,
          nombre: otroUsuario.nombre,
          telefono: otroUsuario.telefono ?? null,
          email: otroUsuario.email,
        }
      : null;

    // Ambos ya se pueden ver el contacto — avisarles a los dos. Cada quien
    // recibe el reporteId del SUYO (para que el tap abra su propio reporte,
    // donde está la sección de coincidencias).
    // Se espera a que quede registrada la notificación in-app (no solo el
    // push, que puede fallar/tardar) antes de responder — un cliente que
    // consulte GET /notificaciones justo después de este 200 debe verla ya
    // guardada, no depender de una carrera con una escritura en segundo
    // plano.
    const reporteIdPorUid = { [creadorA]: data.reporteIdA, [creadorB]: data.reporteIdB };
    await Promise.all(
      [creadorA, creadorB].map((destinatario) =>
        notificacionesService
          .enviarPushAUsuario(destinatario, {
            title: "¡Coincidencia confirmada!",
            body: "Ya pueden verse los datos de contacto en la app.",
            data: {
              tipo: "coincidencia_confirmada",
              coincidenciaId: id,
              reporteId: reporteIdPorUid[destinatario],
            },
          })
          .catch((err) =>
            logger.error(`notificaciones: no se pudo avisar confirmación a ${destinatario}: ${err.message}`)
          )
      )
    );
  } else if (otroUid) {
    // Solo confirmó una parte — invitar a la otra a confirmar también.
    const reporteIdDelOtro = otroUid === creadorA ? data.reporteIdA : data.reporteIdB;
    await notificacionesService
      .enviarPushAUsuario(otroUid, {
        title: "Alguien confirmó una coincidencia",
        body: "Revisa el reporte y confirma si también es tu mascota.",
        data: {
          tipo: "coincidencia_por_confirmar",
          coincidenciaId: id,
          reporteId: reporteIdDelOtro,
        },
      })
      .catch((err) =>
        logger.error(`notificaciones: no se pudo avisar confirmación parcial a ${otroUid}: ${err.message}`)
      );
  }

  return { estado: nuevoEstado, confirmada: ambosConfirmaron, contacto };
}

module.exports = {
  listarCoincidenciasDeReporte,
  listarCoincidenciasDeUsuario,
  descartarCoincidencia,
  confirmarCoincidencia,
};
