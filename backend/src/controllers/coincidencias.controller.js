const coincidenciasService = require("../services/coincidencias.service");

async function listarPropias(req, res, next) {
  try {
    const coincidencias = await coincidenciasService.listarCoincidenciasDeUsuario(req.user.uid);
    res.json(coincidencias);
  } catch (err) {
    next(err);
  }
}

async function descartar(req, res, next) {
  try {
    const result = await coincidenciasService.descartarCoincidencia(req.params.id, req.user.uid);
    if (result.error === "not_found") return res.status(404).json({ error: "Coincidencia no encontrada" });
    if (result.error === "forbidden") return res.status(403).json({ error: "Solo el dueño de uno de los reportes puede descartar esta coincidencia" });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
}

async function confirmar(req, res, next) {
  try {
    const result = await coincidenciasService.confirmarCoincidencia(req.params.id, req.user.uid);
    if (result.error === "not_found") return res.status(404).json({ error: "Coincidencia no encontrada" });
    if (result.error === "forbidden") return res.status(403).json({ error: "Solo el dueño de uno de los reportes puede confirmar esta coincidencia" });
    if (result.error === "descartada") return res.status(400).json({ error: "Esta coincidencia ya fue descartada" });
    res.json({
      estado: result.estado,
      confirmada: result.confirmada,
      contacto: result.contacto,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { listarPropias, descartar, confirmar };
