const { Router } = require("express");
const { verifyToken, requireAdmin } = require("../middlewares/auth");
const adminController = require("../controllers/admin.controller");
const reportesController = require("../controllers/reportes.controller");

const router = Router();

router.use(verifyToken, requireAdmin);

router.get("/users", adminController.listUsers);
router.patch("/users/:uid/disable", adminController.disableUser);
router.delete("/reportes/:id", reportesController.eliminarReporteAdmin);
router.get("/metricas", adminController.obtenerMetricas);
router.get("/reportes-usuario", adminController.listarReportesUsuario);

module.exports = router;
