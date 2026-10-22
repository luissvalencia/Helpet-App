const notificacionesService = require("../services/notificaciones.service");

async function notificarCoincidencia(req, res, next) {
  try {
    const { coincidenciaId } = req.body;
    const resultado = await notificacionesService.enviarNotificacionCoincidencia(coincidenciaId);
    res.json(resultado);
  } catch (err) {
    next(err);
  }
}

async function listar(req, res, next) {
  try {
    const notificaciones = await notificacionesService.listarNotificaciones(req.user.uid);
    res.json(notificaciones);
  } catch (err) {
    next(err);
  }
}

async function marcarLeida(req, res, next) {
  try {
    const result = await notificacionesService.marcarNotificacionLeida(req.params.id, req.user.uid);
    if (result.error === "not_found") return res.status(404).json({ error: "Notificación no encontrada" });
    if (result.error === "forbidden") return res.status(403).json({ error: "Esta notificación no es tuya" });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
}

async function marcarTodasLeidas(req, res, next) {
  try {
    const result = await notificacionesService.marcarTodasLeidas(req.user.uid);
    res.json(result);
  } catch (err) {
    next(err);
  }
}

async function eliminar(req, res, next) {
  try {
    const result = await notificacionesService.eliminarNotificacion(req.params.id, req.user.uid);
    if (result.error === "not_found") return res.status(404).json({ error: "Notificación no encontrada" });
    if (result.error === "forbidden") return res.status(403).json({ error: "Esta notificación no es tuya" });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
}

async function eliminarTodas(req, res, next) {
  try {
    const result = await notificacionesService.eliminarTodasNotificaciones(req.user.uid);
    res.json(result);
  } catch (err) {
    next(err);
  }
}

module.exports = { notificarCoincidencia, listar, marcarLeida, marcarTodasLeidas, eliminar, eliminarTodas };
