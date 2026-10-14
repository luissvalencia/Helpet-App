const reportesService = require("../services/reportes.service");
const coincidenciasService = require("../services/coincidencias.service");
const usersService = require("../services/users.service");

async function crearReporte(req, res, next) {
  try {
    const { tipo, mascota, fotoUrl, ubicacion, mascotaId } = req.body;

    const reporte = await reportesService.createReporte(
      { tipo, mascota, fotoUrl, ubicacion, mascotaId },
      req.user.uid
    );
    res.status(201).json(reporte);
  } catch (err) {
    next(err);
  }
}

async function listarCercanos(req, res, next) {
  try {
    const { lat, lng, radioKm } = req.query;
    const reportes = await reportesService.listReportesCercanos(lat, lng, radioKm);
    res.json(reportes);
  } catch (err) {
    next(err);
  }
}

async function listarPropios(req, res, next) {
  try {
    const { tipo } = req.query;
    const reportes = await reportesService.listReportesPropios(req.user.uid, tipo);
    const conCoincidencias = await Promise.all(
      reportes.map(async (reporte) => ({
        ...reporte,
        coincidenciasCount: (
          await coincidenciasService.listarCoincidenciasDeReporte(reporte.id, req.user.uid)
        ).length,
      }))
    );
    res.json(conCoincidencias);
  } catch (err) {
    next(err);
  }
}

async function obtenerDetalle(req, res, next) {
  try {
    const reporte = await reportesService.getReporteById(req.params.id);
    if (!reporte) return res.status(404).json({ error: "Reporte no encontrado" });
    const creador = await usersService.getUserByUid(reporte.creadoPor);
    res.json({ ...reporte, nombreCreador: creador ? creador.nombre : null });
  } catch (err) {
    next(err);
  }
}

async function obtenerCoincidencias(req, res, next) {
  try {
    const reporte = await reportesService.getReporteById(req.params.id);
    if (!reporte) return res.status(404).json({ error: "Reporte no encontrado" });
    if (reporte.creadoPor !== req.user.uid) {
      return res.status(403).json({ error: "Solo el dueño del reporte puede ver sus coincidencias" });
    }

    const coincidencias = await coincidenciasService.listarCoincidenciasDeReporte(
      req.params.id,
      req.user.uid
    );
    res.json(coincidencias);
  } catch (err) {
    next(err);
  }
}

async function actualizarReporte(req, res, next) {
  try {
    const result = await reportesService.updateReporte(req.params.id, req.user.uid, req.body);
    if (result.error === "not_found") return res.status(404).json({ error: "Reporte no encontrado" });
    if (result.error === "forbidden") return res.status(403).json({ error: "Solo el creador puede editar este reporte" });
    res.json(result.reporte);
  } catch (err) {
    next(err);
  }
}

async function cerrarReporte(req, res, next) {
  try {
    const result = await reportesService.cerrarReporte(req.params.id, req.user.uid);
    if (result.error === "not_found") return res.status(404).json({ error: "Reporte no encontrado" });
    if (result.error === "forbidden") return res.status(403).json({ error: "Solo el creador puede cerrar este reporte" });
    res.json(result.reporte);
  } catch (err) {
    next(err);
  }
}

async function eliminarReportePropio(req, res, next) {
  try {
    const result = await reportesService.eliminarReportePropio(req.params.id, req.user.uid);
    if (result.error === "not_found") return res.status(404).json({ error: "Reporte no encontrado" });
    if (result.error === "forbidden") return res.status(403).json({ error: "Solo el creador puede borrar este reporte" });
    if (result.error === "no_cerrado") return res.status(400).json({ error: "Solo puedes borrar reportes ya cerrados" });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

async function eliminarReporteAdmin(req, res, next) {
  try {
    const reporte = await reportesService.getReporteById(req.params.id);
    if (!reporte) return res.status(404).json({ error: "Reporte no encontrado" });
    await reportesService.deleteReporte(req.params.id);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = {
  crearReporte,
  listarCercanos,
  listarPropios,
  obtenerDetalle,
  obtenerCoincidencias,
  actualizarReporte,
  cerrarReporte,
  eliminarReportePropio,
  eliminarReporteAdmin,
};
