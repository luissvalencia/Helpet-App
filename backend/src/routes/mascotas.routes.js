const { Router } = require("express");
const { verifyToken } = require("../middlewares/auth");
const validate = require("../middlewares/validate");
const mascotasController = require("../controllers/mascotas.controller");
const { crearMascotaSchema, actualizarMascotaSchema } = require("../schemas/mascotas.schema");

const router = Router();

router.post("/", verifyToken, validate(crearMascotaSchema), mascotasController.crear);
router.get("/mias", verifyToken, mascotasController.listarPropias);
router.patch("/:id", verifyToken, validate(actualizarMascotaSchema), mascotasController.actualizar);
router.delete("/:id", verifyToken, mascotasController.eliminar);

module.exports = router;
