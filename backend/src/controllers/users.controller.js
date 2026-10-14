const usersService = require("../services/users.service");
const reportesUsuarioService = require("../services/reportesUsuario.service");

async function getMe(req, res, next) {
  try {
    const user = await usersService.getUserByUid(req.user.uid);
    if (!user) return res.status(404).json({ error: "Usuario no encontrado" });
    res.json(user);
  } catch (err) {
    next(err);
  }
}

async function updateMe(req, res, next) {
  try {
    const user = await usersService.updateUser(req.user.uid, req.body);
    res.json(user);
  } catch (err) {
    next(err);
  }
}

async function eliminarMe(req, res, next) {
  try {
    await usersService.eliminarUsuario(req.user.uid);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

async function reportarUsuario(req, res, next) {
  try {
    const reporte = await reportesUsuarioService.crearReporte(req.user.uid, req.params.uid, req.body);
    res.status(201).json(reporte);
  } catch (err) {
    next(err);
  }
}

module.exports = { getMe, updateMe, eliminarMe, reportarUsuario };
