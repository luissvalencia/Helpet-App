const usersService = require("../services/users.service");
const metricasService = require("../services/metricas.service");
const reportesUsuarioService = require("../services/reportesUsuario.service");
const { auth } = require("../config/firebase");

async function listUsers(req, res, next) {
  try {
    const users = await usersService.listUsers();
    res.json(users);
  } catch (err) {
    next(err);
  }
}

async function disableUser(req, res, next) {
  try {
    const { uid } = req.params;
    await auth.updateUser(uid, { disabled: true });
    await auth.revokeRefreshTokens(uid);
    res.json({ uid, disabled: true });
  } catch (err) {
    next(err);
  }
}

async function obtenerMetricas(req, res, next) {
  try {
    const metricas = await metricasService.getMetricas();
    res.json(metricas);
  } catch (err) {
    next(err);
  }
}

async function listarReportesUsuario(req, res, next) {
  try {
    const reportes = await reportesUsuarioService.listarReportes();
    res.json(reportes);
  } catch (err) {
    next(err);
  }
}

module.exports = { listUsers, disableUser, obtenerMetricas, listarReportesUsuario };
