const { Router } = require("express");
const { verifyInternalKey } = require("../middlewares/internalAuth");
const { verifyToken } = require("../middlewares/auth");
const validate = require("../middlewares/validate");
const notificacionesController = require("../controllers/notificaciones.controller");
const { notificarCoincidenciaSchema } = require("../schemas/notificaciones.schema");

const router = Router();

router.post(
  "/coincidencia",
  verifyInternalKey,
  validate(notificarCoincidenciaSchema),
  notificacionesController.notificarCoincidencia
);

router.get("/", verifyToken, notificacionesController.listar);
router.post("/:id/marcar-leida", verifyToken, notificacionesController.marcarLeida);
router.post("/marcar-todas-leidas", verifyToken, notificacionesController.marcarTodasLeidas);
router.delete("/", verifyToken, notificacionesController.eliminarTodas);
router.delete("/:id", verifyToken, notificacionesController.eliminar);

module.exports = router;
