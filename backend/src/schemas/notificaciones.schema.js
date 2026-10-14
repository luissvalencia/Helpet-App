const { z } = require("zod");

const notificarCoincidenciaSchema = z.object({
  coincidenciaId: z.string({ message: "coincidenciaId es requerido" }).min(1, "coincidenciaId es requerido"),
});

module.exports = { notificarCoincidenciaSchema };
