const { z } = require("zod");

const reportarUsuarioSchema = z.object({
  motivo: z
    .string({ message: "motivo debe ser texto" })
    .min(1, "motivo no puede estar vacío")
    .max(500, "motivo no puede superar 500 caracteres"),
  coincidenciaId: z.string({ message: "coincidenciaId debe ser texto" }).optional(),
});

module.exports = { reportarUsuarioSchema };
