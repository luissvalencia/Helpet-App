const { z } = require("zod");
const { mascotaSchema } = require("./common.schema");

const crearMascotaSchema = mascotaSchema.extend({
  fotoUrl: z.string({ message: "fotoUrl debe ser texto" }).optional(),
});

const actualizarMascotaSchema = crearMascotaSchema.partial();

module.exports = { crearMascotaSchema, actualizarMascotaSchema };
