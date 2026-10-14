const { Router } = require("express");
const { verifyToken } = require("../middlewares/auth");
const validate = require("../middlewares/validate");
const usersController = require("../controllers/users.controller");
const { actualizarUserSchema } = require("../schemas/users.schema");
const { reportarUsuarioSchema } = require("../schemas/reportesUsuario.schema");

const router = Router();

router.get("/me", verifyToken, usersController.getMe);
router.patch("/me", verifyToken, validate(actualizarUserSchema), usersController.updateMe);
router.delete("/me", verifyToken, usersController.eliminarMe);
router.post(
  "/:uid/reportar",
  verifyToken,
  validate(reportarUsuarioSchema),
  usersController.reportarUsuario
);

module.exports = router;
