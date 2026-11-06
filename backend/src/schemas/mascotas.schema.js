const { z } = require("zod");
const { mascotaSchema, fotoUrlSchema } = require("./common.schema");

const crearMascotaSchema = mascotaSchema.extend({
  fotoUrl: fotoUrlSchema.nullable().optional(),
  // Ver confirmarEspecie en reportes.schema.js.
  confirmarEspecie: z.boolean({ message: "confirmarEspecie debe ser verdadero/falso" }).optional(),
});

const actualizarMascotaSchema = crearMascotaSchema.partial();

module.exports = { crearMascotaSchema, actualizarMascotaSchema };
