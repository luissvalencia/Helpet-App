const mascotasService = require("../services/mascotas.service");

async function crear(req, res, next) {
  try {
    const mascota = await mascotasService.crearMascota(req.body, req.user.uid);
    res.status(201).json(mascota);
  } catch (err) {
    next(err);
  }
}

async function listarPropias(req, res, next) {
  try {
    const mascotas = await mascotasService.listarMascotasPropias(req.user.uid);
    res.json(mascotas);
  } catch (err) {
    next(err);
  }
}

async function actualizar(req, res, next) {
  try {
    const result = await mascotasService.actualizarMascota(req.params.id, req.user.uid, req.body);
    if (result.error === "not_found") return res.status(404).json({ error: "Mascota no encontrada" });
    if (result.error === "forbidden") return res.status(403).json({ error: "Solo el dueño puede editar esta mascota" });
    res.json(result.mascota);
  } catch (err) {
    next(err);
  }
}

async function eliminar(req, res, next) {
  try {
    const result = await mascotasService.eliminarMascota(req.params.id, req.user.uid);
    if (result.error === "not_found") return res.status(404).json({ error: "Mascota no encontrada" });
    if (result.error === "forbidden") return res.status(403).json({ error: "Solo el dueño puede borrar esta mascota" });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = { crear, listarPropias, actualizar, eliminar };
