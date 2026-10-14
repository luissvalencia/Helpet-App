const { Router } = require("express");
const { verifyToken } = require("../middlewares/auth");
const validate = require("../middlewares/validate");
const reportesController = require("../controllers/reportes.controller");
const {
  crearReporteSchema,
  actualizarReporteSchema,
  listarCercanosQuerySchema,
  listarPropiosQuerySchema,
} = require("../schemas/reportes.schema");

const router = Router();

router.post("/", verifyToken, validate(crearReporteSchema), reportesController.crearReporte);
router.get("/", verifyToken, validate(listarCercanosQuerySchema, "query"), reportesController.listarCercanos);
router.get("/mios", verifyToken, validate(listarPropiosQuerySchema, "query"), reportesController.listarPropios);
router.get("/:id", verifyToken, reportesController.obtenerDetalle);
router.get("/:id/coincidencias", verifyToken, reportesController.obtenerCoincidencias);
router.patch("/:id", verifyToken, validate(actualizarReporteSchema), reportesController.actualizarReporte);
router.post("/:id/cerrar", verifyToken, reportesController.cerrarReporte);
router.delete("/:id", verifyToken, reportesController.eliminarReportePropio);

module.exports = router;
