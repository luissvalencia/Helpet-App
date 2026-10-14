const { Router } = require("express");
const { verifyToken } = require("../middlewares/auth");
const coincidenciasController = require("../controllers/coincidencias.controller");

const router = Router();

router.get("/mias", verifyToken, coincidenciasController.listarPropias);
router.post("/:id/descartar", verifyToken, coincidenciasController.descartar);
router.post("/:id/confirmar", verifyToken, coincidenciasController.confirmar);

module.exports = router;
