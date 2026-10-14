const { firestore } = require("../config/firebase");
const AppError = require("../utils/AppError");

const reportesUsuarioCollection = firestore.collection("reportesUsuario");

async function crearReporte(reportanteUid, reportadoUid, { motivo, coincidenciaId }) {
  if (reportanteUid === reportadoUid) {
    throw new AppError(400, "No puedes reportarte a ti mismo");
  }

  const data = {
    reportadoUid,
    reportanteUid,
    motivo,
    coincidenciaId: coincidenciaId || null,
    estado: "pendiente",
    creadoEn: new Date(),
  };
  const ref = await reportesUsuarioCollection.add(data);
  return { id: ref.id, ...data };
}

async function listarReportes() {
  const snapshot = await reportesUsuarioCollection.orderBy("creadoEn", "desc").get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

module.exports = { crearReporte, listarReportes };
